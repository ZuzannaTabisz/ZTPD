-- 1.A Zarejestruj stworzoną przez Ciebie warstwę w słowniku bazy danych (metadanych). Domyślna tolerancja niechaj wynosi 0.01.
INSERT INTO USER_SDO_GEOM_METADATA
VALUES ('FIGURY','KSZTALT', MDSYS.SDO_DIM_ARRAY(
    MDSYS.SDO_DIM_ELEMENT('X', 0, 20, 0.01),
    MDSYS.SDO_DIM_ELEMENT('Y', 0, 20, 0.01) ),
    null
);

-- 1.B Dokonaj estymacji rozmiaru indeksu R-drzewo dla stworzonej przez Ciebie tabeli FIGURY.
SELECT SDO_TUNE.ESTIMATE_RTREE_INDEX_SIZE(3000000,8192,10,2,0)
FROM FIGURY;

-- 1.C Utwórz indeks R-drzewo na utworzonej przez Ciebie tabeli.
CREATE INDEX FIG_IDX ON FIGURY(KSZTALT) INDEXTYPE IS MDSYS.SPATIAL_INDEX_V2;

-- 1.D Sprawdź za pomocą operatora SDO_FILTER, które z utworzonych geometrii "mają coś
-- wspólnego" z punktem 3,3. Czy wynik odpowiada rzeczywistości? Czym to jest spowodowane?
-- Jedynie figura o ID 2 (kwadrat) zawiera punkt 3,3. Wynik pokazuje wszytskie trzy figury.
-- Zapytania przestzrenne wykorzystują dwufazowe przetwarzanie. Podczas pierwszej fazy wybierani są jedynie kandydaci spełniający warunek w przybliżeniu (faza filtru podstawowego). 
SELECT f.ID
FROM FIGURY f
WHERE SDO_FILTER(
        f.KSZTALT,
        SDO_GEOMETRY(2001, NULL, SDO_POINT_TYPE(3,3,NULL), NULL, NULL)
      ) = 'TRUE';

-- 1.E Sprawdź za pomocą operatora SDO_RELATE, które z utworzonych geometrii "mają coś
-- wspólnego" (nie są rozłączne) z punktem 3,3. Czy teraz wynik odpowiada rzeczywistości?
-- Wynik jest poprawny. SDO_RELATE wykonuje obie fazy zapytania.
SELECT f.ID
FROM FIGURY f
WHERE SDO_RELATE(
        f.KSZTALT,
        SDO_GEOMETRY(2001, NULL, SDO_POINT_TYPE(3,3,NULL), NULL, NULL),
        'mask=ANYINTERACT'
      ) = 'TRUE';

-- 2.A Wykorzystując operator SDO_NN i funkcję SDO_NN_DISTANCE znajdź dziewięć najbliższych miast wraz z odległościami od Warszawy.

WITH warsaw_point AS (
    SELECT geom AS warsaw_pnt
    FROM major_cities
    WHERE city_name = 'Warsaw'
)
SELECT 
    a.city_name AS miasto,
    ROUND(SDO_NN_DISTANCE(1), 8) AS odl
FROM major_cities a, warsaw_point w
WHERE SDO_NN(
        a.geom, 
        SDO_GEOMETRY(2001, 8307, NULL,
                     MDSYS.SDO_ELEM_INFO_ARRAY(1, 1, 1),
                     MDSYS.SDO_ORDINATE_ARRAY(
                         w.warsaw_pnt.sdo_point.x,
                         w.warsaw_pnt.sdo_point.y
                     )),
        'sdo_num_res=10 unit=km', 1
      ) = 'TRUE'
  AND a.city_name <> 'Warsaw';

-- 2.B Sprawdź, które miasta znajdują się w odległości 100 km od Warszawy. Skorzystaj z operatora SDO_WITHIN_DISTANCE. Wynik porównaj z wynikiem z zadania powyżej. 

WITH warsaw_point AS (
    SELECT geom AS warsaw_pnt
    FROM major_cities
    WHERE city_name = 'Warsaw'
)
SELECT 
    a.city_name AS miasto
FROM major_cities a, warsaw_point w
WHERE SDO_WITHIN_DISTANCE(
        a.geom, 
        SDO_GEOMETRY(2001, 8307, NULL,
                     MDSYS.SDO_ELEM_INFO_ARRAY(1, 1, 1),
                     MDSYS.SDO_ORDINATE_ARRAY(
                         w.warsaw_pnt.sdo_point.x,
                         w.warsaw_pnt.sdo_point.y
                     )),
        'distance=100 unit=km'
      ) = 'TRUE'
  AND a.city_name <> 'Warsaw';

-- 2.C Wyświetl miasta ze Słowacji. Skorzystaj z operatora SDO_RELATE.

SELECT B.CNTRY_NAME AS KRAJ, C.CITY_NAME AS MIASTO
FROM COUNTRY_BOUNDARIES B, MAJOR_CITIES C
WHERE B.CNTRY_NAME = 'Slovakia'
  AND SDO_RELATE(C.GEOM, B.GEOM, 'mask=INSIDE') = 'TRUE'
ORDER BY C.CITY_NAME;

-- 2.D Znajdź odległości pomiędzy Polską a krajami, które z nią nie graniczą. Wykorzystaj operator SDO_RELATE oraz funkcję SDO_DISTANCE. 
SELECT B.CNTRY_NAME AS PANSTWO,
    SDO_GEOM.SDO_DISTANCE(A.GEOM, B.GEOM, 1, 'unit=km') AS ODL
FROM COUNTRY_BOUNDARIES A, COUNTRY_BOUNDARIES B
WHERE 
    A.CNTRY_NAME = 'Poland'
    AND B.CNTRY_NAME <> 'Poland'
    AND NOT SDO_RELATE(A.GEOM, B.GEOM, 'mask=TOUCH') = 'TRUE';

-- 3.A Znajdź sąsiadów Polski oraz odczytaj długość granicy z każdym z nich.
SELECT 
    B.CNTRY_NAME,
    SDO_GEOM.SDO_LENGTH(SDO_GEOM.SDO_INTERSECTION(A.GEOM, B.GEOM, 1), 1, 'unit=km') AS ODL
FROM 
    COUNTRY_BOUNDARIES A,
    COUNTRY_BOUNDARIES B
WHERE 
    A.CNTRY_NAME = 'Poland'
    AND B.CNTRY_NAME <> 'Poland'
    AND SDO_RELATE(A.GEOM, B.GEOM, 'mask=TOUCH') = 'TRUE';

-- 3.B Podaj nazwę Państwa, którego fragment przechowywany w bazie danych jest największy.
SELECT 
    CNTRY_NAME
FROM 
    COUNTRY_BOUNDARIES
ORDER BY 
    SDO_GEOM.SDO_AREA(GEOM, 1, 'unit=SQ_KM') DESC
FETCH FIRST 1 ROW ONLY;

-- 3.C Wyznacz pole minimalnego ograniczającego prostokąta (MBR), w którym znajdują się Warszawa i Łódź.
SELECT 
    ROUND(SDO_GEOM.SDO_AREA(
            SDO_GEOM.SDO_MBR(
                SDO_AGGR_UNION(SDOAGGRTYPE(GEOM, 1))
            ), 1, 'unit=SQ_KM'), 5) AS SQ_KM
FROM MAJOR_CITIES
WHERE CITY_NAME IN ('Warsaw', 'Lodz');

-- 3.D  Jakiego typu geometria będzie sumą geometryczną państwa polskiego i Pragi. Wykorzystaj odpowiednią metodę lub atrybut typu SDO_GEOMETRY.
SELECT SDO_GEOM.SDO_UNION(B.GEOM, C.GEOM, 1).SDO_GTYPE AS GTYPE
FROM COUNTRY_BOUNDARIES B, MAJOR_CITIES C
WHERE B.CNTRY_NAME = 'Poland'
    AND C.CITY_NAME = 'Prague';

-- 3.E Znajdź nazwę miasta, które znajduje się najbliżej centrum ciężkości swojego państwa.
SELECT C.CITY_NAME, B.CNTRY_NAME
FROM COUNTRY_BOUNDARIES B, MAJOR_CITIES C
WHERE C.CNTRY_NAME = B.CNTRY_NAME
ORDER BY SDO_GEOM.SDO_DISTANCE(SDO_GEOM.SDO_CENTROID(B.GEOM,1), C.GEOM, 1)
FETCH FIRST 1 ROW ONLY;

-- 3.F Podaj długość tych z rzek, które przepływają przez terytorium Polski. Ogranicz swoje obliczenia tylko do tych fragmentów, które leżą na terytorium Polski.
SELECT 
    R.NAME,
    SUM(SDO_GEOM.SDO_LENGTH(
                SDO_GEOM.SDO_INTERSECTION(R.GEOM, P.GEOM, 1), 
                1, 'unit=km')) AS DLUGOSC
FROM RIVERS R,
     COUNTRY_BOUNDARIES P
WHERE P.CNTRY_NAME = 'Poland'
  AND SDO_RELATE(R.GEOM, P.GEOM, 'mask=ANYINTERACT') = 'TRUE'
  AND R.NAME IS NOT NULL
  GROUP BY R.NAME;