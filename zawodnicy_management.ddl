--naglówek mecze_management
CREATE OR REPLACE PACKAGE zawodnicy_management IS

--procedura DODAWANIA BRAMEK ZAWODNIKOWI
PROCEDURE dodaj_bramki
(
    db_id_zawodnika zawodnicy.id_zawodnika%TYPE,
    db_strzelone_bramki zawodnicy.strzelone_bramki%TYPE,
    db_id_meczu mecze.id_meczu%TYPE
);

--procedura TRANSFERU ZAWODNIKA DO INNEGO KLUBU
PROCEDURE transfer_zawodnika
(
    tz_id_zawodnika zawodnicy.id_zawodnika%TYPE,
    tz_dokad kluby.id_klubu%TYPE
);

FUNCTION krol_strzelcow
RETURN zawodnicy.id_zawodnika%TYPE;

END zawodnicy_management;

/

--cialo zawodnicy_management
CREATE OR REPLACE PACKAGE BODY zawodnicy_management IS

--procedura DODAWANIA BRAMEK ZAWODNIKOWI
PROCEDURE dodaj_bramki
(
    db_id_zawodnika zawodnicy.id_zawodnika%TYPE,
    db_strzelone_bramki zawodnicy.strzelone_bramki%TYPE,
    db_id_meczu mecze.id_meczu%TYPE
)
AS
    v_informacje_prawidlowe NUMBER := 0;
    v_id_klubu_zawodnika kluby.id_klubu%TYPE;
BEGIN
    --sprawdzenie, z którego klubu powinien byæ dany zawodnik
    --na podstawie jego identyfikatora
    SELECT k.id_klubu
    INTO v_id_klubu_zawodnika
    FROM kluby k
    JOIN zawodnicy z
    ON k.id_klubu = z.id_klubu
    WHERE z.id_zawodnika = db_id_zawodnika;
    
    --sprawdzenie, czy zawodnik faktycznie gra w danym meczu
    SELECT count(*)
    INTO v_informacje_prawidlowe
    FROM mecze_kluby 
    WHERE id_meczu = db_id_meczu AND id_klubu = v_id_klubu_zawodnika;
    
    
    IF v_informacje_prawidlowe = 1
        --zaktualizowanie rekordu w tabeli zawodnicy, dodanie do aktualnej liczby
        --strzelonych bramek tych, które zostaly wprowadzone przez u¿ytkownika
        --poprzez procedurê
        THEN 
            IF db_strzelone_bramki > 0 
                THEN 
                    UPDATE zawodnicy
                    SET strzelone_bramki = strzelone_bramki + db_strzelone_bramki
                    WHERE id_zawodnika = db_id_zawodnika;
            ELSE 
                dbms_output.put_line('Nie mo¿na podaæ ujemnej liczby strzelonych bramek!');
            END IF;
    ELSE     
        dbms_output.put_line('Zawodnik nie nale¿y do ¿adnego z klubów, które graly w podanym meczu.');
    END IF;
    
EXCEPTION 
    WHEN NO_DATA_FOUND THEN
    dbms_output.put_line('Sprawdz ponownie wprowadzone dane.');
END dodaj_bramki;

--procedura TRANSFERU ZAWODNIKA DO INNEGO KLUBU
PROCEDURE transfer_zawodnika
(
    tz_id_zawodnika zawodnicy.id_zawodnika%TYPE,
    tz_dokad kluby.id_klubu%TYPE
)
AS
    v_zawodnik_istnieje NUMBER := 0;
BEGIN
    --sprawdzenie czy dany zawodnik jest ju¿ w danym klubie
    SELECT count (*)
    INTO v_zawodnik_istnieje
    FROM zawodnicy
    WHERE id_klubu = tz_dokad AND id_zawodnika = tz_id_zawodnika;
    
    
    IF v_zawodnik_istnieje = 1
        THEN dbms_output.put_line('Zawodnik ju¿ nale¿y do tego klubu.');
   
    ELSE     
        UPDATE zawodnicy
        SET id_klubu = tz_dokad
        WHERE id_zawodnika = tz_id_zawodnika;
    END IF;
    
EXCEPTION 
    WHEN NO_DATA_FOUND THEN
    dbms_output.put_line('Sprawdz ponownie wprowadzone dane.');
END transfer_zawodnika;

--KRÓL STRZELCÓW
FUNCTION krol_strzelcow
RETURN zawodnicy.id_zawodnika%TYPE
AS
v_krol zawodnicy.id_zawodnika%TYPE;
BEGIN
    SELECT id_zawodnika
    INTO v_krol
    FROM (SELECT *
          FROM zawodnicy
          ORDER BY strzelone_bramki DESC, id_zawodnika)
    WHERE ROWNUM <=1;
    
    return(v_krol);
END krol_strzelcow;

END zawodnicy_management;
