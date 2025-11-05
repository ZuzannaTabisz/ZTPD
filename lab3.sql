--1. Utwórz w swoim schemacie tabelę DOKUMENTY o poniższej strukturze:
--ID        NUMBER(12) PRIMARY KEY  
--DOKUMENT  CLOB

CREATE TABLE DOKUMENTY (
    ID        NUMBER(12) PRIMARY KEY,
    DOKUMENT  CLOB
);

--2. Wstaw do tabeli DOKUMENTY dokument utworzony przez konkatenację 10000 kopii tekstu 'Oto tekst. ' nadając mu ID = 1. (Wskazówka: wykorzystaj anonimowy blok kodu PL/SQL).

DECLARE
    v_text CLOB := '';
BEGIN
    FOR i IN 1..10000 LOOP
        v_text := v_text || 'Oto tekst. ';
    END LOOP;

    INSERT INTO DOKUMENTY (ID, DOKUMENT)
    VALUES (1, v_text);

    COMMIT;
END;
/




--3. Wykonaj poniższe zapytania:
--a) odczyt całej zawartości tabeli DOKUMENTY

SELECT * FROM DOKUMENTY;

--b) odczyt treści dokumentu po zamianie na wielkie litery


SELECT UPPER(DOKUMENT) FROM DOKUMENTY;

--c) odczyt rozmiaru dokumentu funkcją LENGTH

SELECT LENGTH(DOKUMENT) AS ROZMIAR_ZNAKOW FROM DOKUMENTY;



--d) odczyt rozmiaru dokumentu odpowiednią funkcją z pakietu DBMS_LOB

SELECT DBMS_LOB.GETLENGTH(DOKUMENT) AS ROZMIAR_LOB FROM DOKUMENTY;

 --e) odczyt 1000 znaków dokumentu począwszy od znaku na pozycji 5 funkcją SUBSTR

SELECT SUBSTR(DOKUMENT, 5, 1000) FROM DOKUMENTY;

--f) odczyt 1000 znaków dokumentu począwszy od znaku na pozycji 5 odpowiednią funkcją z pakietu DBMS_LOB

SELECT DBMS_LOB.SUBSTR(DOKUMENT, 1000, 5) FROM DOKUMENTY;

--4. Wstaw do tabeli drugi dokument jako pusty obiekt CLOB, nadając mu ID = 2.

INSERT INTO DOKUMENTY (ID, DOKUMENT)
VALUES (2, EMPTY_CLOB());
COMMIT;

--5. Wstaw do tabeli trzeci dokument jako NULL, nadając mu ID = 3. Zatwierdź transakcję.

INSERT INTO DOKUMENTY (ID, DOKUMENT)
VALUES (3, NULL);
COMMIT;

--6. Sprawdź, jaki będzie efekt zapytań z punktu 3 dla wszystkich trzech dokumentów.

SELECT * FROM DOKUMENTY;

SELECT UPPER(DOKUMENT) FROM DOKUMENTY;

SELECT LENGTH(DOKUMENT) AS ROZMIAR_ZNAKOW FROM DOKUMENTY;

SELECT DBMS_LOB.GETLENGTH(DOKUMENT) AS ROZMIAR_LOB FROM DOKUMENTY;

SELECT SUBSTR(DOKUMENT, 5, 1000) FROM DOKUMENTY;

SELECT DBMS_LOB.SUBSTR(DOKUMENT, 1000, 5) FROM DOKUMENTY;


--7. Napisz program w formie anonimowego bloku PL/SQL, który do dokumentu o identyfikatorze 2 przekopiuje tekstową zawartość pliku dokument.txt znajdującego się w katalogu systemu plików serwera udostępnionym przez obiekt DIRECTORY o nazwie TPD_DIR do pustego w tej chwili obiektu CLOB w tabeli DOKUMENTY.

DECLARE
    v_bfile  BFILE;
    v_clob   CLOB;
    v_dest_offset  INTEGER := 1;
    v_src_offset   INTEGER := 1;
    v_lang_ctx     INTEGER := 0;
    v_warning      INTEGER;
BEGIN

    v_bfile := BFILENAME('TPD_DIR', 'dokument.txt');

    DBMS_LOB.FILEOPEN(v_bfile, DBMS_LOB.FILE_READONLY);


    SELECT DOKUMENT INTO v_clob
    FROM DOKUMENTY
    WHERE ID = 2
    FOR UPDATE;


    DBMS_LOB.LOADCLOBFROMFILE(
        dest_lob     => v_clob,
        src_bfile    => v_bfile,
        amount       => DBMS_LOB.GETLENGTH(v_bfile),
        dest_offset  => v_dest_offset,
        src_offset   => v_src_offset,
        bfile_csid   => 0,
        lang_context => v_lang_ctx,
        warning      => v_warning
    );

    DBMS_LOB.FILECLOSE(v_bfile);

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Copying, warning=' || v_warning);
END;
/


--8. Do dokumentu o identyfikatorze 3 przekopiuj tekstową zawartość pliku dokument.txt znajdującego się w katalogu systemu plików serwera (za pośrednictwem obiektu BFILE),
 tym razem nie korzystając z PL/SQL, a ze zwykłego polecenia UPDATE z poziomu SQL.
Wskazówka: Od wersji Oracle 12.2 funkcje TO_BLOB i TO_CLOB zostały rozszerzone o obsługę parametru typu BFILE.

UPDATE DOKUMENTY
SET DOKUMENT = TO_CLOB(BFILENAME('TPD_DIR', 'dokument.txt'))
WHERE ID = 3;
COMMIT;

--9. Odczytaj zawartość tabeli DOKUMENTY.

SELECT * FROM DOKUMENTY;

--10. Odczytaj rozmiar wszystkich dokumentów z tabeli DOKUMENTY.

SELECT ID, DBMS_LOB.GETLENGTH(DOKUMENT) AS ROZMIAR
FROM DOKUMENTY;

--11. Usuń tabelę DOKUMENTY.

DROP TABLE DOKUMENTY;

--12. Zaimplementuj w PL/SQL procedurę CLOB_CENSOR, która w podanym jako pierwszy parametr dużym obiekcie CLOB zastąpi wszystkie wystąpienia tekstu podanego jako drugi parametr (typu VARCHAR2) kropkami, tak aby każdej zastępowanej literze odpowiadała jedna kropka.

CREATE OR REPLACE PROCEDURE CLOB_CENSOR(
    p_clob IN OUT CLOB,
    p_word IN VARCHAR2
) IS
    v_pos INTEGER := 1;
    v_len INTEGER := LENGTH(p_word);
BEGIN
    LOOP
        v_pos := DBMS_LOB.INSTR(p_clob, p_word, v_pos);
        EXIT WHEN v_pos = 0;

        DBMS_LOB.WRITE(
            lob_loc => p_clob,
            amount  => v_len,
            offset  => v_pos,
            buffer  => RPAD('.', v_len, '.')
        );

        v_pos := v_pos + v_len;
    END LOOP;
END;
/

-- sprawdzenie

DECLARE
    v_clob CLOB;
BEGIN
    SELECT DOKUMENT INTO v_clob
    FROM DOKUMENTY
    WHERE ID = 2
    FOR UPDATE;


    CLOB_CENSOR(v_clob, 'testowy');

    COMMIT;
END;
/


SELECT DOKUMENT FROM DOKUMENTY WHERE ID = 2;


--13. Utwórz w swoim schemacie kopię tabeli BIOGRAPHIES ze schematu ZTPD i przetestuj swoją procedurę, zastępując nazwisko „Cimrman” kropkami w biografii Jary Cimrmana.

CREATE TABLE BIOGRAPHIES AS SELECT * FROM ZTPD.BIOGRAPHIES;

CREATE TABLE BIOGRAPHIES AS SELECT * FROM ZTPD.BIOGRAPHIES;

DECLARE
    v_bio CLOB;
BEGIN
    SELECT BIO INTO v_bio
    FROM BIOGRAPHIES
    WHERE PERSON = 'Jara Cimrman'
    FOR UPDATE;

    CLOB_CENSOR(v_bio, 'Cimrman');

    UPDATE BIOGRAPHIES
    SET BIO = v_bio
    WHERE PERSON = 'Jara Cimrman';

    COMMIT;
END;
/



SELECT * FROM BIOGRAPHIES;


--14. Usuń kopię tabeli BIOGRAPHIES ze swojego schematu.

DROP TABLE BIOGRAPHIES;
