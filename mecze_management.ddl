--nagl�wek mecze_management
CREATE OR REPLACE PACKAGE mecze_management IS

--procedura DODAWANIA MECZU DO TABELI
PROCEDURE dodaj_mecz
(
    dm_id_gospodarza kluby.id_klubu%TYPE,
    dm_bramki_gospodarza NUMBER,
    dm_id_goscia kluby.id_klubu%TYPE,
    dm_bramki_goscia NUMBER,
    dm_nr_licencji_sedziego s�dziowie.nr_licencji%TYPE,
    dm_nr_kolejki mecze.kolejka%TYPE
);


-- wyliczenie punkt�w dla klub�w
FUNCTION wylicz_punkty
RETURN kluby.id_klubu%TYPE;


--liczba mecz�w klub�w
FUNCTION ile_meczow
RETURN NUMBER;

END mecze_management;

/

--cialo mecze_management
CREATE OR REPLACE PACKAGE BODY mecze_management IS

--procedura DODAWANIA MECZU DO TABELI
PROCEDURE dodaj_mecz
(
    dm_id_gospodarza kluby.id_klubu%TYPE,
    dm_bramki_gospodarza NUMBER,
    dm_id_goscia kluby.id_klubu%TYPE,
    dm_bramki_goscia NUMBER,
    dm_nr_licencji_sedziego s�dziowie.nr_licencji%TYPE,
    dm_nr_kolejki mecze.kolejka%TYPE
)
AS
    v_mecz_istnieje NUMBER := 0;
    v_mecz_nie_istnieje NUMBER := 0;
    v_id_meczu mecze.id_meczu%TYPE := mecze_seq.NEXTVAL;
    v_id_stadionu stadiony.id_stadionu%TYPE := 0;
BEGIN

    --sprawdzenie, na kt�rym stadionie odbyl si� mecz na podstawie 
    --podanego id gospodarza (mecz zawsze odbywa si� na stadionie
    -- gospodarza)
    SELECT id_stadionu 
    INTO v_id_stadionu
    FROM kluby 
    WHERE id_klubu = dm_id_gospodarza;
    
    --sprawdzenie, czy rekord dotyczacy danego meczu (jego nr kolejki i
    --id stadionu [tym samym id gospodarza] w zupelno�ci wystarczy, poniewa�
    --podczas jednej kolejki klub mo�e by� gospodarzem tylko raz)
    SELECT count(*)
    INTO v_mecz_istnieje
    FROM mecze m
    WHERE m.kolejka = dm_nr_kolejki AND m.id_stadionu = v_id_stadionu;
    
    --sprawdzenie, czy podany mecz w og�le ma prawo bytu, poniewa� ka�dy klub 
    --w ka�dej kolejce powinien gra� tylko jeden mecz
    SELECT count(*)
    INTO v_mecz_nie_istnieje
    FROM mecze_kluby mk
    JOIN mecze m
    ON mk.id_meczu = m.id_meczu
    WHERE m.kolejka = dm_nr_kolejki AND mk.id_klubu IN (dm_id_gospodarza, dm_id_goscia);
    
    
    IF v_mecz_nie_istnieje = 1
        THEN dbms_output.put_line('Podany mecz nie odbyl si�! Kt�ra� z podanych dru�yn zagrala ju� mecz w tej kolejce. ');
        
    ELSIF v_mecz_istnieje = 1
        THEN dbms_output.put_line('Mecz jest ju� w tabeli.');
        
    ELSE     
        --wstawienie calego rekordu do tabeli mecze, wraz z numerem kolejki, punktami zdobytymi przez gospodarza i go�cia, 
        --numerem licencji s�dziego oraz stadionem
        IF dm_bramki_gospodarza >= 0 AND dm_bramki_goscia >=0
        THEN
            INSERT INTO mecze VALUES(v_id_meczu, dm_nr_kolejki, dm_bramki_gospodarza, dm_bramki_goscia, dm_nr_licencji_sedziego, v_id_stadionu, 0);
            
            --dodanie meczu do tabeli mecze_klubu
            INSERT INTO mecze_kluby VALUES(dm_id_gospodarza, v_id_meczu);
            INSERT INTO mecze_kluby VALUES(dm_id_goscia, v_id_meczu);
        
        ELSE 
            dbms_output.put_line('Nie mo�na poda� ujemnej liczby bramek!');
        END IF;
    END IF;
    
EXCEPTION 
    WHEN NO_DATA_FOUND THEN
    dbms_output.put_line('Sprawdz ponownie wprowadzone dane.');
END dodaj_mecz;


-- wyliczenie punkt�w dla klub�w

FUNCTION wylicz_punkty
RETURN kluby.id_klubu%TYPE
AS
v_zwyciezca kluby.id_klubu%TYPE;
id_go�cia kluby.id_klubu%TYPE;

--Aby u�y� operacji UPDATE w funkcji i u�y� tej funkcji testujac ja w zapytaniu SELECT
--trzeba u�y� PRAGMA AUTONOMOUS_TRANSACTION, a nast�pnie "zcommitowa�" zmiany
pragma autonomous_transaction;

CURSOR c IS
    SELECT m.id_meczu, m.punkty_gospodarza, m.punkty_go�cia, m.rozliczony, k.id_klubu as id_gospodarza
    FROM mecze m, kluby k
    WHERE m.id_stadionu = k.id_stadionu;
BEGIN
    FOR i in c
    LOOP
        --je�li warto�� pola rozliczony jest r�na od zera, to znaczy, �e dru�yny dostaly
        --ju� punkty za ten mecz
        IF i.rozliczony != 0
        THEN 
            dbms_output.put_line('Mecz o id' || i.id_meczu || 'zostal juz rozliczony');
        
        --w przeciwnym wypadku rozpoczyna si� wyliczanie punkt�w dla danego meczu
        --zwyci�ska dru�yna otrzymuje 3 punkty, przegrana dru�yna 0
        --je�li jest remis - ka�da z dru�yn otrzymuje po 1 punkcie
        ELSE
            --je�eli wygral gospodarz, to sprawa jest prosta,
            --bo do id_gospodarza jest bezpo�redni dost�p z kursora
            IF i.punkty_gospodarza > i.punkty_go�cia
            THEN 
                UPDATE kluby
                SET punkty = punkty + 3
                WHERE id_klubu = i.id_gospodarza;
            
            --w przeciwnym wypadku wiadomo, �e go�ciowi te� trzeba dopisa�
            --punkt lub 3, dlatego teraz zajm� si� wyluskaniem z moich danych
            --(a dokladniej z tabeli Mecze_kluby) id_go�cia
            ELSE
                SELECT id_klubu
                INTO id_go�cia
                FROM mecze_kluby
                WHERE id_meczu = i.id_meczu AND id_klubu != i.id_gospodarza;
                
                --teraz, majac zar�wno id_gospodarza, jak i id_go�cia, mo�na
                --przej�� do sprawdzenia kolejnych opcji wyniku meczu 
                
                --je�li jest remis
                IF i.punkty_gospodarza = i.punkty_go�cia
                THEN 
                    UPDATE kluby
                    SET punkty = punkty + 1
                    WHERE id_klubu IN (i.id_gospodarza, id_go�cia);
                
                --zostaje tylko opcja, �e wygral go��
                ELSE
                    UPDATE kluby
                    SET punkty = punkty + 3
                    WHERE id_klubu = id_go�cia;
                END IF;
                
            END IF;           
        END IF;
    END LOOP;
    
    --niezale�nie od wyniku wszystkie mecze zostay on obslu�one, mecz mo�na uzna�
    --wszystkie za rozliczone
    UPDATE mecze
    SET rozliczony = 1
    WHERE rozliczony = 0;
    commit;
    
    --zwrocenie id_klubu z najwieksza ilo�cia dotychczas zebranych punkt�w 
    SELECT id_klubu
    INTO v_zwyciezca
    FROM (SELECT *
          FROM kluby
          ORDER BY punkty DESC, id_klubu)
    WHERE ROWNUM <=1;
    
    return v_zwyciezca;
    
END wylicz_punkty;


--liczba mecz�w danego klubu

FUNCTION ile_meczow
RETURN NUMBER
AS
v_najwiecej_meczow_klub kluby.id_klubu%TYPE;

CURSOR c IS
    SELECT k.id_klubu, k.nazwa_klubu, count(UNIQUE mk.id_meczu) as liczba_meczow
    FROM mecze_kluby mk
    JOIN kluby k
    ON k.id_klubu = mk.id_klubu
    GROUP BY k.id_klubu, k.nazwa_klubu
    ORDER BY nazwa_klubu;

BEGIN
    FOR i in c
    LOOP
    dbms_output.put_line('No co jest');
        dbms_output.put_line('Klub ' || i.nazwa_klubu || ' zagral do tej pory ' || i.liczba_meczow || ' mecz�w.');
    END LOOP;
    
    SELECT id_klubu
    INTO v_najwiecej_meczow_klub
    FROM (
            SELECT id_klubu, count(UNIQUE id_meczu) as liczba_meczow
            FROM mecze_kluby 
            GROUP BY id_klubu
            ORDER BY liczba_meczow DESC)
    WHERE ROWNUM <= 1;
    
    return v_najwiecej_meczow_klub;

END ile_meczow;

END mecze_management;
