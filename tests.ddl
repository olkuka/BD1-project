--TRIGGERS

--test trigger wstaw_zawodnik_trigger

INSERT INTO zawodnicy VALUES(zawodnicy_seq.NEXTVAL, 'Rafal', 'Adamski', 1988, 912, 0);
INSERT INTO zawodnicy VALUES(zawodnicy_seq.NEXTVAL, 'Patryk', 'Makuch', 1988, 912, 20);

--test trigger zmien_zawodnik_trigger

UPDATE zawodnicy
SET strzelone_bramki = 20
WHERE id_zawodnika = 1001;

UPDATE zawodnicy
SET strzelone_bramki = -20
WHERE id_zawodnika = 1002;

--test trigger zmien_klub_trigger

UPDATE kluby
SET punkty = 10
WHERE id_klubu = 901;

UPDATE kluby
SET punkty = -10
WHERE id_klubu = 902;


--PROCEDURES

--test dodaj_mecz()

BEGIN
    mecze_management.dodaj_mecz(913, 0, 906, 1, 'h36d', 1);
    mecze_management.dodaj_mecz(913, 0, 906, 1, 'h36d', 1);
    mecze_management.dodaj_mecz(911, 0, 913, 1, 'h36d', 1);
    mecze_management.dodaj_mecz(910, -2, 905, 1, 'h36d', 5);
END;

--test dodaj_bramki()

BEGIN 
    zawodnicy_management.dodaj_bramki(1428, 3, 2000);
    zawodnicy_management.dodaj_bramki(1234, 2, 2023);
    zawodnicy_management.dodaj_bramki(1428, -5, 2000);
    
END;

--test transfer_zawodnika()

BEGIN 
    zawodnicy_management.transfer_zawodnika(1016,912);
    zawodnicy_management.transfer_zawodnika(1016,912);
END;


--FUNCTIONS

--test krol_strzelcow()

SELECT *
FROM zawodnicy
WHERE id_zawodnika = (SELECT mecze_management.krol_strzelcow() 
                      FROM dual);

--test wylicz_punkty()

SELECT nazwa_klubu 
FROM kluby
WHERE id_klubu = (SELECT mecze_management.wylicz_punkty()
                  FROM dual);

--test ile_meczow()

SELECT nazwa_klubu
FROM kluby
WHERE id_klubu = (SELECT mecze_management.ile_meczow()
                  FROM dual);


--ADDITIONAL SQL QUERIES

SELECT m.id_meczu, k.id_klubu as gospodarz, m.punkty_gospodarza, 
    (SELECT mk.id_klubu
     FROM mecze_kluby mk
     WHERE mk.id_klubu != k.id_klubu AND mk.id_meczu = m.id_meczu) as gosc, 
     m.punkty_gościa 
FROM mecze m
JOIN kluby k
ON m.id_stadionu = k.id_stadionu;


SELECT s.nr_licencji, count(m.id_meczu) as ilosc_meczow
FROM sędziowie s
JOIN mecze m
ON m.nr_licencji_sędziego = s.nr_licencji
GROUP BY s.nr_licencji;


SELECT s.nr_licencji, mk.id_klubu, count(mk.id_klubu)
FROM sędziowie s
JOIN mecze m
ON m.nr_licencji_sędziego = s.nr_licencji
JOIN mecze_kluby mk
ON m.id_meczu = mk.id_meczu
GROUP BY s.nr_licencji, mk.id_klubu
ORDER BY mk.id_klubu;

