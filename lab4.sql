-- A. Utwórz tabelę o nazwie FIGURY z dwoma kolumnami:
-- ID - number(1) - klucz podstawowy
-- KSZTALT - MDSYS.SDO_GEOMETRY.
CREATE TABLE FIGURY (ID NUMBER(1) PRIMARY KEY, KSZTALT MDSYS.SDO_GEOMETRY);

-- B. Wstaw do tabeli FIGURY trzy kształty przedstawione na rysunku poniżej. Układ odniesienia pozostaw pusty – będzie to kartezjański układ odniesienia.
-- kształt nr 1 (koło)
INSERT INTO FIGURY VALUES (1, MDSYS.SDO_GEOMETRY(
    2003, NULL, NULL,
    MDSYS.SDO_ELEM_INFO_ARRAY(1, 1003, 4),
    MDSYS.SDO_ORDINATE_ARRAY(5,7, 7,5, 5,3)
));
-- kształt nr 2 (kwadrat)
INSERT INTO FIGURY VALUES (2, MDSYS.SDO_GEOMETRY(
    2003, NULL, NULL,
    MDSYS.SDO_ELEM_INFO_ARRAY(1, 1003, 3),
    MDSYS.SDO_ORDINATE_ARRAY(1,1, 5,5)
));
-- kształt nr 3 (nieregularny)
INSERT INTO FIGURY VALUES (3, MDSYS.SDO_GEOMETRY(
    2002, NULL, NULL,
    MDSYS.SDO_ELEM_INFO_ARRAY(1,4,2, 1,2,1, 5,2,2),
    MDSYS.SDO_ORDINATE_ARRAY(3,2, 6,2, 7,3, 8,2, 7,1)
));

-- C. Wstaw do tabeli FIGURY własny kształt o nieprawidłowej definicji
--  kształt, którego definicja elementów określona w SDO_ELEM_INFO jest niezgodna z typem geometrii SDO_GEOM
INSERT INTO FIGURY VALUES (3, MDSYS.SDO_GEOMETRY(
    2003, NULL, NULL,
    MDSYS.SDO_ELEM_INFO_ARRAY(1,4,2),
    MDSYS.SDO_ORDINATE_ARRAY(3,2, 6,2, 7,3)
));
-- D. Zweryfikuj poprawność wstawionych geometrii 
SELECT ID, SDO_GEOM.VALIDATE_GEOMETRY_WITH_CONTEXT(KSZTALT, 0.005) AS VAL FROM FIGURY;

-- E. Usuń te wiersze z tabeli FIGURY, które zawierają nieprawidłowe kształty.
DELETE FROM FIGURY WHERE SDO_GEOM.VALIDATE_GEOMETRY_WITH_CONTEXT(KSZTALT, 0.1) <> 'TRUE';

-- F. Zatwierdź transakcję.
COMMIT;