--1. Utwórz w swoim schemacie kopię tabeli MOVIES ze schematu ZTPD.
 Wskazówka: Skorzystaj z polecenia CREATE TABLE … AS SELECT …
 

CREATE TABLE movies AS
SELECT * FROM ztpd.movies;

SELECT * FROM movies;


--2. Zapoznaj się ze schematem tabeli MOVIES, zwracając uwagę na kolumnę typu BLOB.

DESC movies;


--3. Sprawdź zapytaniem SQL do tabeli MOVIES, które filmy nie mają okładek.
--ID  TITLE
--65  Where Eagles Dare
--66  The Great Escape


SELECT id, title
FROM movies
WHERE cover IS NULL;


--4. Dla filmów, które mają okładki, odczytaj rozmiar obrazka w bajtach.
--ID  TITLE                            FILESIZE
--61  Aces Go Places 5                 56477
--62  Gone In 60 Seconds               35780
--63  American Gigolo                  37571
--64  Deuce Bigalow: Male Gigolo       5608


SELECT id, title, DBMS_LOB.getlength(cover) AS filesize
FROM movies
WHERE cover IS NOT NULL;


--5. Sprawdź, co się stanie, gdy zostanie dokonana próba odczytu rozmiaru obrazków dla filmów, które nie posiadają okładek w tabeli MOVIES.
--ID  TITLE                FILESIZE
--65  Where Eagles Dare
--66  The Great Escape

SELECT id, title, DBMS_LOB.getlength(cover) AS filesize
FROM movies
WHERE id IN (65, 66);

-- filesize (null)


--6. Brakujące okładki zostały umieszczone w jednym z katalogów systemu plików serwera bazy danych w plikach eagles.jpg i escape.jpg.Został on udostępniony w bazie danych jako obiekt DIRECTORY o nazwie TPD_DIR.Upewnij się zapytaniem do perspektywy ALL_DIRECTORIES, czy widzisz katalog TPD_DIR, i odczytaj, jaką ścieżkę w systemie plików on reprezentuje.Uwaga: Z poziomu bazy danych do katalogu odwołuje się poprzez nazwę obiektu DIRECTORY (czyli TPD_DIR w naszym przypadku).Gdy nazwa ta pojawia się jako tekstowy parametr procedur/funkcji, to musi być zachowana wielkość liter jak w słowniku bazy danych.
--DIRECTORY_NAME  DIRECTORY_PATH
--TPD_DIR         /u01/oradata/dblab11g/directories/mbd


SELECT directory_name, directory_path
FROM all_directories
WHERE directory_name = 'TPD_DIR';



--7. Zmodyfikuj okładkę filmu o identyfikatorze 66 w tabeli MOVIES na pusty obiekt BLOB (lokalizator bez wartości),a jako typ MIME (w przeznaczonej do tego celu kolumnie tabeli) podaj: image/jpeg.
 

UPDATE movies
SET cover = EMPTY_BLOB(),
    mime_type = 'image/jpeg'
WHERE id = 66;

COMMIT;



--8. Odczytaj z tabeli MOVIES rozmiar obrazków dla filmów o identyfikatorach 65 i 66.
--ID  TITLE              FILESIZE
--65  Where Eagles Dare
–66  The Great Escape    0


SELECT id, title, DBMS_LOB.getlength(cover) AS filesize
FROM movies
WHERE id IN (65, 66);




--9. Napisz program w formie anonimowego bloku PL/SQL, który dla filmu o identyfikatorze 66 przekopiuje binarną zawartość obrazka z pliku escape.jpg znajdującego się w katalogu systemu plików serwera (za pośrednictwem obiektu BFILE) do pustego w tej chwili obiektu BLOB w tabeli MOVIES.

DECLARE
  v_bfile  BFILE;
  v_blob   BLOB;
BEGIN

  v_bfile := BFILENAME('TPD_DIR', 'escape.jpg');

 
  SELECT cover INTO v_blob
  FROM movies
  WHERE id = 66
  FOR UPDATE;


  DBMS_LOB.fileopen(v_bfile, DBMS_LOB.file_readonly);


  DBMS_LOB.loadfromfile(v_blob, v_bfile, DBMS_LOB.getlength(v_bfile));


  DBMS_LOB.fileclose(v_bfile);
  COMMIT;
END;
/


--10. Utwórz tabelę TEMP_COVERS o poniższej strukturze:
--movie_id   NUMBER(12)
--image      BFILE
--mime_type  VARCHAR2(50)


CREATE TABLE temp_covers (
  movie_id   NUMBER(12),
  image      BFILE,
  mime_type  VARCHAR2(50)
);



--11. Wstaw do tabeli TEMP_COVERS obrazek z pliku eagles.jpg z udostępnionego katalogu. Nadaj mu identyfikator filmu, którego jest okładką (65). Jako typ MIME podaj:image/jpeg.



INSERT INTO temp_covers
VALUES (65, BFILENAME('TPD_DIR', 'eagles.jpg'), 'image/jpeg');

COMMIT;



--12. Odczytaj rozmiar w bajtach dla obrazka załadowanego jako BFILE.
--MOVIE_ID  FILESIZE
--65         33470

SELECT movie_id, DBMS_LOB.getlength(image) AS filesize
FROM temp_covers;




--13. Napisz program w formie anonimowego bloku PL/SQL, który dla filmu o identyfikatorze 65 utworzy obiekt BLOB, przekopiuje do niego binarną zawartość okładki BFILE z tabeli TEMP_COVERS i umieści BLOB w odpowiednim wierszu tabeli MOVIES.

DECLARE
  v_bfile   BFILE;
  v_blob    BLOB;
  v_mime    VARCHAR2(50);
BEGIN

  SELECT image, mime_type INTO v_bfile, v_mime
  FROM temp_covers
  WHERE movie_id = 65;


  DBMS_LOB.createtemporary(v_blob, TRUE);


  DBMS_LOB.fileopen(v_bfile, DBMS_LOB.file_readonly);


  DBMS_LOB.loadfromfile(v_blob, v_bfile, DBMS_LOB.getlength(v_bfile));


  UPDATE movies
  SET cover = v_blob,
      mime_type = v_mime
  WHERE id = 65;


  DBMS_LOB.fileclose(v_bfile);
  DBMS_LOB.freetemporary(v_blob);
  COMMIT;
END;
/



--14. Odczytaj rozmiar w bajtach dla okładek filmów 65 i 66 z tabeli MOVIES.
--MOVIE_ID  FILESIZE
--65         33470
--66         50567

SELECT id AS movie_id, DBMS_LOB.getlength(cover) AS filesize
FROM movies
WHERE id IN (65, 66);




--15. Usuń tabelę MOVIES ze swojego schematu.

DROP TABLE movies PURGE;
