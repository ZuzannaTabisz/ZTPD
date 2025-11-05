--1. Zdefiniuj typ obiektowy reprezentujący SAMOCHODY. Każdy samochód powinien mieć markę, model, liczbę kilometrów oraz datę produkcji i cenę. Stwórz tablicę obiektową i wprowadź kilka przykładowych obiektów, obejrzyj zawartość tablicy

CREATE OR REPLACE TYPE SAMOCHOD AS OBJECT(
    MARKA VARCHAR2(20),
    MODEL VARCHAR2(20),
    KILOMETRY NUMBER,
    DATA_PRODUKCJI DATE,
    CENA NUMBER(10,2)
);

CREATE TABLE SAMOCHODY OF SAMOCHOD;

INSERT INTO SAMOCHODY VALUES (NEW SAMOCHOD('FIAT','BRAVA', 60000, DATE '1999-11-30', 25000));
INSERT INTO SAMOCHODY VALUES (NEW SAMOCHOD('FORD','MONDEO', 80000, DATE '1997-05-10', 45000));
INSERT INTO SAMOCHODY VALUES (NEW SAMOCHOD('MAZDA','323', 12000, DATE '2000-09-22', 52000));

-- 2. Stwórz tablicę WLASCICIELE zawierającą imiona i nazwiska właścicieli oraz atrybut obiektowy SAMOCHOD. Wprowadź do tabeli przykładowe dane i wyświetl jej zawartość. 

CREATE TABLE WLASCICIELE(
    IMIE VARCHAR2(100),
    NAZWISKO VARCHAR2(100),
    AUTO SAMOCHOD
);

INSERT INTO WLASCICIELE VALUES('JAN','KOWALSKI',NEW SAMOCHOD('FIAT','SEICENTO',30000,DATE '2010-12-02',19500));
INSERT INTO WLASCICIELE VALUES('ADAM','NOWAK',NEW SAMOCHOD('OPEL','ASTRA',34000,DATE '2009-06-01',33700));

--3. Wartość samochodu maleje o 10% z każdym rokiem. Dodaj do typu obiektowego SAMOCHOD metodę wyliczającą aktualną wartość samochodu na podstawie wieku.

CREATE OR REPLACE TYPE BODY SAMOCHOD AS
    MEMBER FUNCTION WARTOSC RETURN NUMBER IS
        LATA NUMBER;
    BEGIN
        LATA := EXTRACT(YEAR FROM SYSDATE) - EXTRACT(YEAR FROM DATA_PRODUKCJI);
        RETURN ROUND(CENA * POWER(0.9, LATA), 2);
    END WARTOSC;
END;
/

SELECT s.MARKA, s.CENA, s.WARTOSC() FROM SAMOCHODY s;

--4. Dodaj do typu SAMOCHOD metodę odwzorowującą, która pozwoli na porównywanie samochodów na podstawie ich wieku i zużycia. Przyjmij, że 10000 km odpowiada jednemu rokowi wieku samochodu. 

ALTER TYPE SAMOCHOD ADD MAP MEMBER FUNCTION POROWNAJ RETURN NUMBER CASCADE;

CREATE OR REPLACE TYPE BODY SAMOCHOD AS
    MEMBER FUNCTION WARTOSC RETURN NUMBER IS
        LATA NUMBER;
    BEGIN
        LATA := EXTRACT(YEAR FROM SYSDATE) - EXTRACT(YEAR FROM DATA_PRODUKCJI);
        RETURN ROUND(CENA * POWER(0.9, LATA), 2);
    END WARTOSC;

    MAP MEMBER FUNCTION POROWNAJ RETURN NUMBER IS
        WIEK_LATA NUMBER;
    BEGIN
        WIEK_LATA := EXTRACT(YEAR FROM SYSDATE) - EXTRACT(YEAR FROM DATA_PRODUKCJI);
        RETURN WIEK_LATA + (KILOMETRY / 10000);
    END POROWNAJ;
END;
/

SELECT * FROM SAMOCHODY s ORDER BY VALUE(s);

--5. Stwórz typ WLASCICIEL zawierający imię i nazwisko właściciela samochodu, dodaj do typu SAMOCHOD referencje do właściciela. Wypełnij tabelę przykładowymi danymi.

CREATE OR REPLACE TYPE WLASCICIEL AS OBJECT(
    IMIE VARCHAR2(30),
    NAZWISKO VARCHAR2(30)
);




CREATE OR REPLACE TYPE WLASCICIEL AS OBJECT(
    IMIE VARCHAR2(30),
    NAZWISKO VARCHAR2(30)
);

CREATE TABLE WLASCICIELE2 OF WLASCICIEL;

INSERT INTO WLASCICIELE2 VALUES('JAN','KOWALSKI');
INSERT INTO WLASCICIELE2 VALUES('ADAM','NOWAK');

DROP TYPE SAMOCHOD FORCE;


CREATE OR REPLACE TYPE SAMOCHOD AS OBJECT(
    MARKA VARCHAR2(20),
    MODEL VARCHAR2(20),
    KILOMETRY NUMBER,
    DATA_PRODUKCJI DATE,
    CENA NUMBER(10,2),
    WLASC REF WLASCICIEL
);

DROP TABLE SAMOCHODY PURGE;

CREATE TABLE SAMOCHODY OF SAMOCHOD;

ALTER TABLE SAMOCHODY
ADD SCOPE FOR (WLASC) IS WLASCICIELE2;

INSERT INTO SAMOCHODY VALUES(
    SAMOCHOD('FIAT','PUNTO',120000,TO_DATE('01-01-2015','DD-MM-YYYY'),15000,
             (SELECT REF(w) FROM WLASCICIELE2 w WHERE w.IMIE='JAN' AND w.NAZWISKO='KOWALSKI'))
);

SELECT * FROM SAMOCHODY;




--KOLEKCJE

--6. Zbuduj kolekcję (tablicę o zmiennym rozmiarze) zawierającą informacje o przedmiotach (łańcuchy znaków). Wstaw do kolekcji przykładowe przedmioty, rozszerz kolekcję, wyświetl zawartość kolekcji, usuń elementy z końca kolekcji 

DECLARE
 TYPE t_przedmioty IS VARRAY(10) OF VARCHAR2(20);
 moje_przedmioty t_przedmioty := t_przedmioty('');
BEGIN
 moje_przedmioty(1) := 'MATEMATYKA';
 moje_przedmioty.EXTEND(9);
 FOR i IN 2..10 LOOP
 moje_przedmioty(i) := 'PRZEDMIOT_' || i;
 END LOOP;
 FOR i IN moje_przedmioty.FIRST()..moje_przedmioty.LAST() LOOP
 DBMS_OUTPUT.PUT_LINE(moje_przedmioty(i));
 END LOOP;
 moje_przedmioty.TRIM(2);
 FOR i IN moje_przedmioty.FIRST()..moje_przedmioty.LAST() LOOP
 DBMS_OUTPUT.PUT_LINE(moje_przedmioty(i));
 END LOOP;
 DBMS_OUTPUT.PUT_LINE('Limit: ' || moje_przedmioty.LIMIT());
 DBMS_OUTPUT.PUT_LINE('Liczba elementow: ' || moje_przedmioty.COUNT());
 moje_przedmioty.EXTEND();
 moje_przedmioty(9) := 9;
 DBMS_OUTPUT.PUT_LINE('Limit: ' || moje_przedmioty.LIMIT());
 DBMS_OUTPUT.PUT_LINE('Liczba elementow: ' || moje_przedmioty.COUNT());
 moje_przedmioty.DELETE();
 DBMS_OUTPUT.PUT_LINE('Limit: ' || moje_przedmioty.LIMIT());
 DBMS_OUTPUT.PUT_LINE('Liczba elementow: ' || moje_przedmioty.COUNT());
END;


--7. Zdefiniuj kolekcję (w oparciu o tablicę o zmiennym rozmiarze) zawierającą listę tytułów książek. Wykonaj na kolekcji kilka czynności (rozszerz, usuń jakiś element, wstaw nową książkę).

DECLARE
TYPE t_ksiazki IS VARRAY(10) OF VARCHAR2(50);
moje_ksiazki t_ksiazki := t_ksiazki('ksiazka_1');
BEGIN

moje_ksiazki.EXTEND(4);
FOR i IN 2..5 LOOP
moje_ksiazki(i) := 'ksiazka_' || i;
END LOOP;

DBMS_OUTPUT.PUT_LINE('Output:');
FOR i IN moje_ksiazki.FIRST .. moje_ksiazki.LAST LOOP
DBMS_OUTPUT.PUT_LINE(moje_ksiazki(i));
END LOOP;

-- usuniecie ostatniego elementu
moje_ksiazki.TRIM;

-- usuniecie przez przesuniecie

FOR i IN 2 .. moje_ksiazki.COUNT-1 LOOP
moje_ksiazki(i) := moje_ksiazki(i+1);
END LOOP;
moje_ksiazki.TRIM;


DBMS_OUTPUT.PUT_LINE('Delete');
FOR i IN moje_ksiazki.FIRST .. moje_ksiazki.LAST LOOP
DBMS_OUTPUT.PUT_LINE(moje_ksiazki(i));
END LOOP;

moje_ksiazki.EXTEND;
moje_ksiazki(moje_ksiazki.LAST) := 'ksiazka_nowadodana';
DBMS_OUTPUT.PUT_LINE('Add:');
FOR i IN moje_ksiazki.FIRST .. moje_ksiazki.LAST LOOP
DBMS_OUTPUT.PUT_LINE(moje_ksiazki(i));
END LOOP;


DBMS_OUTPUT.PUT_LINE('Limit: ' || moje_ksiazki.LIMIT);
DBMS_OUTPUT.PUT_LINE('Liczba elementów: ' || moje_ksiazki.COUNT);

END;




--8. Zbuduj kolekcję (tablicę zagnieżdżoną) zawierającą informacje o wykładowcach. Przetestuj działanie kolekcji podobnie jak w przykładzie 

 DECLARE
 TYPE t_wykladowcy IS TABLE OF VARCHAR2(20);
 moi_wykladowcy t_wykladowcy := t_wykladowcy();
BEGIN
 moi_wykladowcy.EXTEND(2);
 moi_wykladowcy(1) := 'MORZY';
 moi_wykladowcy(2) := 'WOJCIECHOWSKI';
 moi_wykladowcy.EXTEND(8);
 FOR i IN 3..10 LOOP
 moi_wykladowcy(i) := 'WYKLADOWCA_' || i;
 END LOOP;
 FOR i IN moi_wykladowcy.FIRST()..moi_wykladowcy.LAST() LOOP
 DBMS_OUTPUT.PUT_LINE(moi_wykladowcy(i));
 END LOOP;
 moi_wykladowcy.TRIM(2);
 FOR i IN moi_wykladowcy.FIRST()..moi_wykladowcy.LAST() LOOP
 DBMS_OUTPUT.PUT_LINE(moi_wykladowcy(i));
 END LOOP;
 moi_wykladowcy.DELETE(5,7);
 DBMS_OUTPUT.PUT_LINE('Limit: ' || moi_wykladowcy.LIMIT());
 DBMS_OUTPUT.PUT_LINE('Liczba elementow: ' || moi_wykladowcy.COUNT());
 FOR i IN moi_wykladowcy.FIRST()..moi_wykladowcy.LAST() LOOP
 IF moi_wykladowcy.EXISTS(i) THEN
 DBMS_OUTPUT.PUT_LINE(moi_wykladowcy(i));
 END IF;
 END LOOP;
 moi_wykladowcy(5) := 'ZAKRZEWICZ';
 moi_wykladowcy(6) := 'KROLIKOWSKI';
 moi_wykladowcy(7) := 'KOSZLAJDA';
 FOR i IN moi_wykladowcy.FIRST()..moi_wykladowcy.LAST() LOOP
 IF moi_wykladowcy.EXISTS(i) THEN
 DBMS_OUTPUT.PUT_LINE(moi_wykladowcy(i));
 END IF;
 END LOOP;
 DBMS_OUTPUT.PUT_LINE('Limit: ' || moi_wykladowcy.LIMIT());
DBMS_OUTPUT.PUT_LINE('Liczba elementow: ' || moi_wykladowcy.COUNT());
END;


--9. Zbuduj kolekcję (w oparciu o tablicę zagnieżdżoną) zawierającą listę miesięcy. Wstaw do kolekcji właściwe dane, usuń parę miesięcy, wyświetl zawartość kolekcji.
	
DECLARE
TYPE t_miesiace IS TABLE OF VARCHAR2(20);
lista_miesiecy t_miesiace := t_miesiace();
BEGIN
lista_miesiecy.EXTEND(12);
lista_miesiecy(1)  := 'Styczeń';
lista_miesiecy(2)  := 'Luty';
lista_miesiecy(3)  := 'Marzec';
lista_miesiecy(4)  := 'Kwiecień';
lista_miesiecy(5)  := 'Maj';
lista_miesiecy(6)  := 'Czerwiec';
lista_miesiecy(7)  := 'Lipiec';
lista_miesiecy(8)  := 'Sierpień';
lista_miesiecy(9)  := 'Wrzesień';
lista_miesiecy(10) := 'Październik';
lista_miesiecy(11) := 'Listopad';
lista_miesiecy(12) := 'Grudzień';

DBMS_OUTPUT.PUT_LINE('');
FOR i IN lista_miesiecy.FIRST .. lista_miesiecy.LAST LOOP
DBMS_OUTPUT.PUT_LINE(lista_miesiecy(i));
  END LOOP;


 lista_miesiecy.DELETE(2,3);

DBMS_OUTPUT.PUT_LINE('Delete:');
FOR i IN lista_miesiecy.FIRST .. lista_miesiecy.LAST LOOP
IF lista_miesiecy.EXISTS(i) THEN
DBMS_OUTPUT.PUT_LINE(lista_miesiecy(i));
END IF;
END LOOP;


lista_miesiecy(2) := 'Luty';
lista_miesiecy(3) := 'Marzec';

DBMS_OUTPUT.PUT_LINE('Add:');
FOR i IN lista_miesiecy.FIRST .. lista_miesiecy.LAST LOOP
IF lista_miesiecy.EXISTS(i) THEN
DBMS_OUTPUT.PUT_LINE(lista_miesiecy(i));
END IF;
END LOOP;

DBMS_OUTPUT.PUT_LINE('Liczba elementów: ' || lista_miesiecy.COUNT);
END;
/



--10. Sprawdź działanie obu rodzajów kolekcji w przypadku atrybutów bazodanowych. 

CREATE TYPE jezyki_obce AS VARRAY(10) OF VARCHAR2(20);
/
CREATE TYPE stypendium AS OBJECT (
 nazwa VARCHAR2(50),
 kraj VARCHAR2(30),
 jezyki jezyki_obce );
/
CREATE TABLE stypendia OF stypendium;
INSERT INTO stypendia VALUES
('SOKRATES','FRANCJA',jezyki_obce('ANGIELSKI','FRANCUSKI','NIEMIECKI'));
INSERT INTO stypendia VALUES
('ERASMUS','NIEMCY',jezyki_obce('ANGIELSKI','NIEMIECKI','HISZPANSKI'));
SELECT * FROM stypendia;
SELECT s.jezyki FROM stypendia s;
UPDATE STYPENDIA
SET jezyki = jezyki_obce('ANGIELSKI','NIEMIECKI','HISZPANSKI','FRANCUSKI')
WHERE nazwa = 'ERASMUS';
CREATE TYPE lista_egzaminow AS TABLE OF VARCHAR2(20);
/
CREATE TYPE semestr AS OBJECT (
 numer NUMBER,
 egzaminy lista_egzaminow );
/
CREATE TABLE semestry OF semestr
NESTED TABLE egzaminy STORE AS tab_egzaminy;
INSERT INTO semestry VALUES
(semestr(1,lista_egzaminow('MATEMATYKA','LOGIKA','ALGEBRA')));
INSERT INTO semestry VALUES
(semestr(2,lista_egzaminow('BAZY DANYCH','SYSTEMY OPERACYJNE')));
SELECT s.numer, e.*
FROM semestry s, TABLE(s.egzaminy) e;
SELECT e.*
FROM semestry s, TABLE ( s.egzaminy ) e;
SELECT * FROM TABLE ( SELECT s.egzaminy FROM semestry s WHERE numer=1 );
INSERT INTO TABLE ( SELECT s.egzaminy FROM semestry s WHERE numer=2 )
VALUES ('METODY NUMERYCZNE');
UPDATE TABLE ( SELECT s.egzaminy FROM semestry s WHERE numer=2 ) e
SET e.column_value = 'SYSTEMY ROZPROSZONE'
WHERE e.column_value = 'SYSTEMY OPERACYJNE';
DELETE FROM TABLE ( SELECT s.egzaminy FROM semestry s WHERE numer=2 ) e
WHERE e.column_value = 'BAZY DANYCH';




--11. Zbuduj tabelę ZAKUPY zawierającą atrybut zbiorowy KOSZYK_PRODUKTOW w postaci tabeli zagnieżdżonej. Wstaw do tabeli przykładowe dane. Wyświetl zawartość tabeli, usuń wszystkie transakcje zawierające wybrany produkt.


CREATE TYPE lista_produktow AS TABLE OF VARCHAR2(50);
/


CREATE TYPE zakup AS OBJECT (
    id NUMBER,
    klient VARCHAR2(50),
    koszyk_produktow lista_produktow
);
/


CREATE TABLE zakupy OF zakup
NESTED TABLE koszyk_produktow STORE AS tab_koszyk;
/

INSERT INTO zakupy VALUES (
    zakup(1, 'Kowalski', lista_produktow('Mleko','Chleb','Masło'))
);

INSERT INTO zakupy VALUES (
    zakup(2, 'Nowak', lista_produktow('Chleb','Jajka','Sok'))
);

INSERT INTO zakupy VALUES (
    zakup(3, 'Jankowski', lista_produktow('Mleko','Jajka','Czekolada'))
);


SELECT z.id, z.klient, p.column_value AS produkt
FROM zakupy z, TABLE(z.koszyk_produktow) p;


DELETE FROM zakupy
WHERE 'Chleb' MEMBER OF koszyk_produktow;


SELECT z.id, z.klient, p.column_value AS produkt
FROM zakupy z, TABLE(z.koszyk_produktow) p;


--POLIMORFIZM

--12. Zbuduj hierarchię reprezentującą instrumenty muzyczne. 

CREATE TYPE instrument AS OBJECT (
 nazwa VARCHAR2(20),
 dzwiek VARCHAR2(20),
 MEMBER FUNCTION graj RETURN VARCHAR2 ) NOT FINAL;
CREATE TYPE BODY instrument AS
 MEMBER FUNCTION graj RETURN VARCHAR2 IS
 BEGIN
 RETURN dzwiek;
 END;
END;
/
CREATE TYPE instrument_dety UNDER instrument (
 material VARCHAR2(20),
 OVERRIDING MEMBER FUNCTION graj RETURN VARCHAR2,
 MEMBER FUNCTION graj(glosnosc VARCHAR2) RETURN VARCHAR2 );
CREATE OR REPLACE TYPE BODY instrument_dety AS
 OVERRIDING MEMBER FUNCTION graj RETURN VARCHAR2 IS
 BEGIN
 RETURN 'dmucham: '||dzwiek;
 END;
 MEMBER FUNCTION graj(glosnosc VARCHAR2) RETURN VARCHAR2 IS
 BEGIN
 RETURN glosnosc||':'||dzwiek;
 END;
END;
/
CREATE TYPE instrument_klawiszowy UNDER instrument (
 producent VARCHAR2(20),
 OVERRIDING MEMBER FUNCTION graj RETURN VARCHAR2 );
CREATE OR REPLACE TYPE BODY instrument_klawiszowy AS
 OVERRIDING MEMBER FUNCTION graj RETURN VARCHAR2 IS
 BEGIN
 RETURN 'stukam w klawisze: '||dzwiek;
 END;
END;
/
DECLARE
 tamburyn instrument := instrument('tamburyn','brzdek-brzdek');
 trabka instrument_dety := instrument_dety('trabka','tra-ta-ta','metalowa');
 fortepian instrument_klawiszowy := instrument_klawiszowy('fortepian','pingping','steinway');
BEGIN
 dbms_output.put_line(tamburyn.graj);
 dbms_output.put_line(trabka.graj);
 dbms_output.put_line(trabka.graj('glosno'));
 dbms_output.put_line(fortepian.graj);
END;



--13. Zbuduj hierarchię zwierząt i przetestuj klasy abstrakcyjne.

CREATE TYPE istota AS OBJECT (
 nazwa VARCHAR2(20),
 NOT INSTANTIABLE MEMBER FUNCTION poluj(ofiara CHAR) RETURN CHAR )
 NOT INSTANTIABLE NOT FINAL;
CREATE TYPE lew UNDER istota (
 liczba_nog NUMBER,
 OVERRIDING MEMBER FUNCTION poluj(ofiara CHAR) RETURN CHAR );
CREATE OR REPLACE TYPE BODY lew AS
 OVERRIDING MEMBER FUNCTION poluj(ofiara CHAR) RETURN CHAR IS
 BEGIN
 RETURN 'upolowana ofiara: '||ofiara;
 END;
END;


DECLARE
 KrolLew lew := lew('LEW',4);
-- obeikt klasy abstrakcyjnej "istota" nie może być utworzony
-- PLS-00713: attempting to instantiate a type that is NOT INSTANTIABLE
 --InnaIstota istota := istota('JAKIES ZWIERZE');
BEGIN
 DBMS_OUTPUT.PUT_LINE( KrolLew.poluj('antylopa') );
END;



--14. Zbadaj własność polimorfizmu na przykładzie hierarchii instrumentów. 

DECLARE
 tamburyn instrument;
 cymbalki instrument;
 trabka instrument_dety;
 saksofon instrument_dety;
BEGIN
 tamburyn := instrument('tamburyn','brzdek-brzdek');
 cymbalki := instrument_dety('cymbalki','ding-ding','metalowe');
 trabka := instrument_dety('trabka','tra-ta-ta','metalowa');
 -- nie dziala bez rzutowania
 -- PLS-00382: expression is of wrong type
 -- saksofon := instrument('saksofon','tra-taaaa');
 -- nie dziala przez zla liczbe pol, oczekuje pola 'material'
 -- numeric or value error: cannot assign supertype instance to subtype
 -- saksofon := TREAT( instrument('saksofon','tra-taaaa') AS instrument_dety);
END;



--15. Zbuduj tabelę zawierającą różne instrumenty. Zbadaj działanie funkcji wirtualnych.


CREATE TABLE instrumenty OF instrument;
INSERT INTO instrumenty VALUES ( instrument('tamburyn','brzdek-brzdek') );
INSERT INTO instrumenty VALUES ( instrument_dety('trabka','tra-ta-ta','metalowa')
);
INSERT INTO instrumenty VALUES ( instrument_klawiszowy('fortepian','pingping','steinway') );
SELECT i.nazwa, i.graj() FROM instrumenty i;

