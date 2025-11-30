-- 1.A. Utwórz tabelę S6_LRS posiadającą jedną kolumnę GEOM typu SDO_GEOMETRY.
CREATE TABLE S6_LRS (GEOM SDO_GEOMETRY);

-- 1.B. Skopiuj do tabeli S6_LRS obiekt przestrzenny z tabeli STREETS_AND_RAILROADS znajdujący się w odległości nie większej niż 10 km od Koszalina.

INSERT INTO S6_LRS
SELECT S.GEOM
FROM STREETS_AND_RAILROADS S, MAJOR_CITIES C
WHERE C.CITY_NAME = 'Koszalin' AND
    SDO_RELATE(S.GEOM, SDO_GEOM.SDO_BUFFER(C.GEOM, 10, 1, 'unit=km'),
    'MASK=ANYINTERACT') = 'TRUE';

SELECT * FROM S6_LRS;

-- 1.C. Sprawdź długość oraz liczbę punktów, na który składa się skopiowany odcinek – przebieg trasy S6. 
SELECT SDO_GEOM.SDO_LENGTH(GEOM, 1, 'unit=km') DISTANCE,
    ST_LINESTRING(GEOM).ST_NUMPOINTS() ST_NUMPOINTS
FROM S6_LRS;

-- D. Dokonaj konwersji obiektu przestrzennego uzupełniając go o miary punktów
-- wchodzących w skład obiektu z przedziału od 0 do wartości będącej długością
-- skopiowanego odcinka.
UPDATE S6_LRS
SET GEOM = SDO_LRS.CONVERT_TO_LRS_GEOM(GEOM, 0, 276.681);

-- 1.E. Zarejestruj metadane dotyczące tabeli S6_LRS. 
INSERT INTO USER_SDO_GEOM_METADATA
VALUES ('S6_LRS', 'GEOM', MDSYS.SDO_DIM_ARRAY(
    MDSYS.SDO_DIM_ELEMENT('X', 12.603676, 26.369824, 1),
    MDSYS.SDO_DIM_ELEMENT('Y', 45.8464, 58.0213, 1),
    MDSYS.SDO_DIM_ELEMENT('M', 0, 300, 1) ),
    8307);

-- 1.F. Utwórz indeks przestrzenny na tabeli S6_LRS.
CREATE INDEX S6_LRS_IDX ON S6_LRS(GEOM)
indextype IS MDSYS.SPATIAL_INDEX;


-- 2.A. Sprawdź czy miara o wartości 500 jest prawidłową miarą dla utworzonego segmentu LRS.
SELECT SDO_LRS.VALID_MEASURE(GEOM, 500) VALID_500 FROM S6_LRS;

-- 2.B. Sprawdź jaki punkt jest punktem kończącym segment LRS.
SELECT SDO_LRS.GEOM_SEGMENT_END_PT(GEOM).GET_WKT() END_PT FROM S6_LRS;

-- 2.C. Wyznacz punkt, w którym kończy się 150. kilometr trasy S6.
SELECT SDO_LRS.LOCATE_PT(GEOM, 150, 0).GET_WKT() KM150 FROM S6_LRS;

-- 2.D. Wyznacz ciąg linii będący fragmentem trasy S6 od jej 120. kilometra do 160. kilometra.

SELECT SDO_LRS.CLIP_GEOM_SEGMENT(GEOM, 120, 160).GET_WKT() CLIPPED FROM S6_LRS;

-- 2.E. Zakładając, że punkty definiujące trasę S6 są jej wjazdami znajdź współrzędne
-- wjazdu położonego najbliżej od Słupska, przy założeniu, że kierowca udaje się do
-- Szczecina.
SELECT SDO_LRS.PROJECT_PT(s6.GEOM, c.GEOM).GET_WKT() AS WJAZD_NA_S6
FROM S6_LRS s6, MAJOR_CITIES c
WHERE c.CITY_NAME = 'Slupsk';

-- 2.F. Gdyby chcieć zbudować gazociąg biegnący po lewej stronie trasy S6
-- w odległości 50 metrów od niej, ciągnący się od 50. do 200. jej kilometra, to jaki
-- byłby koszt jego budowy? Przyjmij, że koszt budowy gazociągu to 1mln/km.

SELECT SDO_GEOM.SDO_LENGTH(
    SDO_LRS.OFFSET_GEOM_SEGMENT(S6.GEOM, M.DIMINFO, 50, 200, 50,'unit=m arc_tolerance=1'),
    1, 'unit=km').GET_WKT() KOSZT
FROM S6_LRS S6, USER_SDO_GEOM_METADATA M
WHERE M.TABLE_NAME = 'S6_LRS' AND M.COLUMN_NAME = 'GEOM';


