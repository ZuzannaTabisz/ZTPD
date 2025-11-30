-- 1.A Wykorzystując klauzulę CONNECT BY wyświetl hierarchię typu ST_GEOMETRY.

select lpad('-',2*(level-1),'|-') || t.owner||'.'||t.type_name||' (FINAL:'||t.final||
', INSTANTIABLE:'||t.instantiable||', ATTRIBUTES:'||t.attributes||', METHODS:'||t.methods||')'
from all_types t
start with t.type_name = 'ST_GEOMETRY'
connect by prior t.type_name = t.supertype_name
and prior t.owner = t.owner;

-- 1.B Wyświetl nazwy metod typu ST_POLYGON.
select distinct m.method_name
from all_type_methods m
where m.type_name like 'ST_POLYGON'
and m.owner = 'MDSYS'
order by 1;

-- 1.C Utwórz tabelę MYST_MAJOR_CITIES.
CREATE TABLE MYST_MAJOR_CITIES (
FIPS_CNTRY VARCHAR2(2),
CITY_NAME VARCHAR2(40),
STGEOM ST_POINT );

-- 1.D Przepisz zawartość tabeli MAJOR_CITIES (znajduje się ona w schemacie ZTPD) do
-- stworzonej przez Ciebie tabeli MYST_MAJOR_CITIES dokonując odpowiedniej konwersji typów.


INSERT INTO MYST_MAJOR_CITIES
SELECT C.FIPS_CNTRY, C.CITY_NAME, 
    TREAT(ST_POINT.FROM_SDO_GEOM(C.GEOM) AS ST_POINT) STGEOM
FROM MAJOR_CITIES C;

-- 2.A Wstaw do tabeli MYST_MAJOR_CITIES informację dotyczącą Szczyrku. Załóż, że centrum Szczyrku znajduje się w punkcie o współrzędnych 19.036107;
-- 49.718655. Wykorzystaj 3-argumentowy konstruktor ST_POINT (ostatnim argumentem jest identyfikator układu współrzędnych).


INSERT INTO MYST_MAJOR_CITIES
VALUES('PL', 'Szczyrk', ST_POINT(19.036107, 49.718655, 8307));

-- 3.A Utwórz tabelę MYST_COUNTRY_BOUNDARIES.

CREATE TABLE MYST_COUNTRY_BOUNDARIES (
FIPS_CNTRY VARCHAR2(2),
CNTRY_NAME VARCHAR2(40),
STGEOM ST_MULTIPOLYGON );

-- 3.B Przepisz zawartość tabeli COUNTRY_BOUNDARIES do nowo utworzonej tabeli dokonując odpowiednich konwersji.


INSERT INTO MYST_COUNTRY_BOUNDARIES
SELECT B.FIPS_CNTRY, B.CNTRY_NAME, ST_MULTIPOLYGON(B.GEOM)
FROM COUNTRY_BOUNDARIES B;

-- 3.C Sprawdź jakiego typu i ile obiektów przestrzennych zostało umieszczonych w tabeli MYST_COUNTRY_BOUNDARIES.

SELECT B.STGEOM.ST_GEOMETRYTYPE() AS TYP_OBIEKTU, 
    COUNT(B.STGEOM.ST_GEOMETRYTYPE())  AS ILE
FROM MYST_COUNTRY_BOUNDARIES B
GROUP BY B.STGEOM.ST_GEOMETRYTYPE()
ORDER BY ILE DESC;

-- 3.D Sprawdź czy wszystkie definicje przestrzenne uznawane są za proste.
SELECT B.STGEOM.ST_ISSIMPLE()
FROM MYST_COUNTRY_BOUNDARIES B;

-- 4.A Sprawdź ile miejscowości (MYST_MAJOR_CITIES) zawiera się w danym państwie (MYST_COUNTRY_BOUNDARIES).

SELECT B.CNTRY_NAME, COUNT(*)
FROM MYST_MAJOR_CITIES C, MYST_COUNTRY_BOUNDARIES B
WHERE B.STGEOM.ST_CONTAINS(C.STGEOM) = 1
GROUP BY B.CNTRY_NAME;

-- 4.B Znajdź te państwa, które graniczą z Czechami.

SELECT A.CNTRY_NAME AS A_NAME, B.CNTRY_NAME AS B_NAME
FROM MYST_COUNTRY_BOUNDARIES A, MYST_COUNTRY_BOUNDARIES B
WHERE B.CNTRY_NAME = 'Czech Republic' AND
      B.STGEOM.ST_TOUCHES(A.STGEOM) = 1;

-- 4.C Znajdź nazwy tych rzek, które przecinają granicę Czech.

SELECT DISTINCT B.CNTRY_NAME, A.NAME
FROM RIVERS A, MYST_COUNTRY_BOUNDARIES B
WHERE B.CNTRY_NAME = 'Czech Republic' AND
      B.STGEOM.ST_CROSSES(ST_LINESTRING(A.GEOM)) = 1;

-- 4.D Sprawdź, jaka powierzchnia jest Czech i Słowacji połączonych w jeden obiekt przestrzenny.

SELECT TREAT(A.STGEOM.ST_UNION(B.STGEOM) AS ST_POLYGON).ST_AREA() POWIERZCHNIA
FROM MYST_COUNTRY_BOUNDARIES A, MYST_COUNTRY_BOUNDARIES B
WHERE B.CNTRY_NAME = 'Czech Republic' AND
      A.CNTRY_NAME = 'Slovakia';

-- 4.E Sprawdź jakiego typu obiektem są Węgry z "wykrojonym" Balatonem – wykorzystaj tabelę WATER_BODIES.
SELECT B.STGEOM.ST_DIFFERENCE(ST_GEOMETRY(W.GEOM)) AS OBIEKT, 
    B.STGEOM.ST_DIFFERENCE(ST_GEOMETRY(W.GEOM)).ST_GEOMETRYTYPE() WEGRY_BEZ
FROM MYST_COUNTRY_BOUNDARIES B, WATER_BODIES W
WHERE B.CNTRY_NAME = 'Hungary' AND
      W.NAME = 'Balaton';

-- 5.A Wykorzystując operator SDO_WITHIN_DISTANCE znajdź liczbę miejscowości oddalonych od terytorium Polski nie więcej niż 100 km. 
EXPLAIN PLAN FOR
    SELECT B.CNTRY_NAME, COUNT(*)
    FROM MYST_MAJOR_CITIES C, MYST_COUNTRY_BOUNDARIES B
    WHERE SDO_WITHIN_DISTANCE(C.STGEOM, B.STGEOM, 'distance=100 unit=km') = 'TRUE' AND
        B.CNTRY_NAME = 'Poland'
    GROUP BY B.CNTRY_NAME;

SELECT plan_table_output FROM TABLE(dbms_xplan.display('plan_table', null, 'basic'));

-- 5.B Zarejestruj metadane dotyczące stworzonych przez Ciebie tabeli MYST_MAJOR_CITIES i/lub MYST_COUNTRY_BOUNDARIES.

INSERT INTO USER_SDO_GEOM_METADATA
SELECT 'MYST_MAJOR_CITIES', 'STGEOM', T.DIMINFO, T.SRID
FROM ALL_SDO_GEOM_METADATA T
WHERE T.TABLE_NAME = 'MAJOR_CITIES';

INSERT INTO USER_SDO_GEOM_METADATA
SELECT 'MYST_COUNTRY_BOUNDARIES', 'STGEOM', T.DIMINFO, T.SRID
FROM ALL_SDO_GEOM_METADATA T
WHERE T.TABLE_NAME = 'COUNTRY_BOUNDARIES';


-- 5.C Utwórz na tabelach MYST_MAJOR_CITIES i/lub MYST_COUNTRY_BOUNDARIES indeks R-drzewo.

CREATE INDEX MYST_MAJOR_CITIES_IDX ON MYST_MAJOR_CITIES(STGEOM)
indextype IS MDSYS.SPATIAL_INDEX;


CREATE INDEX MYST_COUNTRY_BND_IDX ON MYST_COUNTRY_BOUNDARIES(STGEOM)
indextype IS MDSYS.SPATIAL_INDEX;

-- 5.D Ponownie znajdź liczbę miejscowości oddalonych od terytorium Polski nie więcej niż 100 km.
-- Indeksy są wykorzystywane (DOMAIN INDEX | MYST_MAJOR_CITIES_IDX)

EXPLAIN PLAN FOR
    SELECT B.CNTRY_NAME, COUNT(*)
    FROM MYST_MAJOR_CITIES C, MYST_COUNTRY_BOUNDARIES B
    WHERE SDO_WITHIN_DISTANCE(C.STGEOM, B.STGEOM, 'distance=100 unit=km') = 'TRUE' AND
        B.CNTRY_NAME = 'Poland'
    GROUP BY B.CNTRY_NAME;

SELECT plan_table_output FROM TABLE(dbms_xplan.display('plan_table', null, 'basic'));

DROP TABLE MYST_MAJOR_CITIES;
DROP TABLE MYST_COUNTRY_BOUNDARIES;