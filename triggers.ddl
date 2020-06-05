CREATE OR REPLACE TRIGGER wstaw_zawodnik_trigger
BEFORE INSERT
ON zawodnicy
FOR EACH ROW
	WHEN (new.strzelone_bramki != 0)
BEGIN
	:new.strzelone_bramki := 0;
END;

ALTER TRIGGER wstaw_zawodnik_trigger ENABLE;


CREATE OR REPLACE TRIGGER zmien_zawodnik_trigger
BEFORE UPDATE OF strzelone_bramki
ON zawodnicy
FOR EACH ROW
    WHEN(new.strzelone_bramki < 0) 
BEGIN
    :new.strzelone_bramki := :old.strzelone_bramki;
    dbms_output.put_line('Nie mo�na zmieni� liczby strzelonych bramek zawodnika o id ' || :old.id_zawodnika || ' na liczb� ujemna!');
END;

ALTER TRIGGER zmien_zawodnik_trigger ENABLE;


CREATE OR REPLACE TRIGGER zmien_klub_trigger
BEFORE UPDATE OF punkty
ON kluby
FOR EACH ROW
    WHEN(new.punkty < 0) 
BEGIN
    :new.punkty := :old.punkty;
    dbms_output.put_line('Nie mo�na zmieni� liczby punkt�w klubu o id ' || :old.id_klubu || ' na liczb� ujemna!');
END;

ALTER TRIGGER zmien_klub_trigger ENABLE;