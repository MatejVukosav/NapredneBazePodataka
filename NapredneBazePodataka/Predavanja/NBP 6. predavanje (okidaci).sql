/*Prilikom unosa novog imena u tablicu klijent, 
provjeriti da li je ime klijenta kraće od 5 slova. 
Ako jest, pridijeliti mu sufiks "_test".*/


DELIMITER //
DROP TRIGGER IF EXISTS provjeraImena //
CREATE TRIGGER provjeraImena BEFORE INSERT ON klijent FOR EACH ROW 
	BEGIN
		/* zašto nije ispravno: IF LENGTH(klijent.imeklijent)<5 THEN... ?
		
		pogrešno je pokušati napraviti UPDATE na NEW:
			UPDATE NEW set NEW.imeklijent=CONCAT(NEW.imeklijent,'_test'); */
			
			
		IF LENGTH(new.imeklijent)<5 THEN
			SET NEW.imeklijent=CONCAT(NEW.imeklijent,'_test');
		END IF;
	END//
DELIMITER ;
/*Primjer naredbe koja će aktivirati okidač:*/
INSERT INTO klijent (sifKlijent, imeKlijent) VALUES (12, 'Pero');
INSERT INTO klijent (sifKlijent, imeKlijent) VALUES (13, 'Perislav');




/*Zadatak kao i prethodni, ali za ažuriranje umjesto za unos podataka – 
sufiks "_test" se dodaje ako je staro ime kraće od 5 znakova). */
DELIMITER //
DROP TRIGGER IF EXISTS provjeraImenaNaUpdate //
CREATE TRIGGER provjeraImenaNaUpdate BEFORE UPDATE ON klijent 
	FOR EACH ROW 
	BEGIN
		IF LENGTH(old.imeKlijent)<5
			THEN SET NEW.imeklijent=CONCAT(NEW.imeklijent,'_test');
		END IF;
			
	END//   
DELIMITER ;

UPDATE klijent SET imeKlijent = "Jan" WHERE imeKlijent="Nikola" AND prezimeKlijent="Bačić";
UPDATE klijent SET imeKlijent = "Ivo" WHERE imeKlijent="Jan" AND prezimeKlijent="Bačić";


UPDATE klijent SET imeKlijent = "Ivo" WHERE sifKlijent=1137;





/* Napisati okidač koji će prilikom unosa zapisa u tablicu mjesto provjeriti je li dobro unesena županija. 
Ako je šifra županije neispravna, postavit će je na nula. */

DELIMITER $$
DROP TRIGGER IF EXISTS provjeriZupanijuMjesta $$
CREATE TRIGGER provjeriZupanijuMjesta BEFORE INSERT ON mjesto
FOR EACH ROW
BEGIN
	DECLARE br INT;
	SELECT COUNT(*) INTO br FROM zupanija 
		WHERE zupanija.sifZupanija=NEW.sifZupanija;
	IF br=0 THEN
		SET NEW.sifZupanija=0;
	END IF;
END;
$$
DELIMITER ; 

INSERT INTO mjesto VALUES (12345, 'Novo mjesto', 22);


/* Riješimo isti problem preko procedure i okidača koji će je pozivati. */

DELIMITER $$
DROP PROCEDURE IF EXISTS zupanija $$
CREATE PROCEDURE zupanija(INOUT sifrazup INT)
BEGIN
	DECLARE br INT;
	SELECT COUNT(*) INTO br FROM zupanija WHERE zupanija.sifZupanija=sifrazup;
	IF br =0 THEN
		SET sifrazup=0;
	END IF;
END;
$$
DELIMITER ;

DROP TRIGGER IF EXISTS provjeriZupanijuMjesta ;
CREATE TRIGGER provjeriZupanijuMjesta
	BEFORE INSERT ON mjesto
	FOR EACH ROW
	CALL zupanija(NEW.sifZupanija);

INSERT INTO mjesto VALUES(10001,'Test',22);



/*Za svako brisanje zapisa u tablici mjesto, postaviti pbrKlijenta klijenata koji stanuju u mjestu koje se briše na NULL. */
DELIMITER $$
DROP TRIGGER mjesto $$
CREATE TRIGGER mjesto AFTER DELETE ON mjesto
FOR EACH ROW
BEGIN
	UPDATE klijent SET pbrKlijent=NULL WHERE klijent.pbrKlijent=OLD.pbrMjesto;
END;
$$
DELIMITER ;

DELETE FROM mjesto WHERE pbrMjesto=10000;
SELECT * FROM klijent WHERE pbrKlijent=10000;


/*Napravite „socijalni“ okidač. Ako se ažuriraju podaci u tablici radnik na način da se unosi koeficijent plaće manji od 1 potrebno ga je odmah korigirati na 1.*/

DROP TRIGGER koef1;
DELIMITER $$
CREATE TRIGGER koef1 BEFORE UPDATE ON radnik
	FOR EACH ROW
BEGIN
IF NEW.KoefPlaca<1  THEN
	SET NEW.KoefPlaca=1;
END IF;
END;
$$
DELIMITER ;

/*Napravite okidač za „mogućnosti napredovanja“. 
Ako se ažurira tablica radnik na način da se unosi 
koeficijent plaće povećan za više od 2, 
potrebno ga je odmah korigirati da je uvećan za točno 2. */

DROP TRIGGER koef2;
DELIMITER $$
CREATE TRIGGER koef2 BEFORE UPDATE ON radnik
FOR EACH ROW
BEGIN
IF NEW.KoefPlaca+2> OLD.KoefPlaca THEN
	SET NEW.KoefPlaca=OLD.KoefPlaca+2;
END IF;
END;
$$
DELIMITER ;



/*U bazi studenti u tablicu nastavnici dodati novu kolonu 
'lozinkaTimestamp'. 
Potrebno je osigurati da se nakon svake promjene lozinke nekom od nastavnika, automatski upiše vremenska oznaka promjene lozinke u kolonu 'lozinkaTimestamp’ (za tog nastavnika).*/

ALTER TABLE nastavnici ADD COLUMN lozinkaTimestamp TIMESTAMP ;
DELIMITER %%
DROP TRIGGER IF EXISTS lozinkaZig %%
CREATE TRIGGER lozinkaZig BEFORE UPDATE ON nastavnici 
FOR EACH ROW
BEGIN
	IF old.lozinka != new.lozinka 
		THEN SET new.lozinkaTimestamp=NOW();
	END IF;
END;
%%
DELIMITER ;

UPDATE nastavnici SET lozinka=MD5('123') WHERE jmbg=0110959390037;



/*U bazi studenti potrebno je osigurati da se prilikom unosa 
novog studenta u tablicu studenti ne može unijeti krivi podatak za datum upisa. 
Datum upisa uvijek mora biti postavljen na današnji dan.*/

DELIMITER %%
DROP TRIGGER IF EXISTS provjeriDatumUpisa %%
CREATE TRIGGER provjeriDatumUpisa BEFORE INSERT ON studenti 
FOR EACH ROW
BEGIN
	IF new.datumUpisa != CURDATE() THEN 
		SET new.datumUpisa=CURDATE();
	END IF;
END;
%%
DELIMITER ;

INSERT INTO studenti VALUES ('1234567891', 'Ivan', 'Horvat', '2014-01-01', 10000, 10000, 1);



/*U tablicu kolegiji dodati novi atribut brPolozenih. 
Napisati proceduru koja će primiti naziv kolegija, 
te za taj kolegij popuniti atribut brPolozenih na način 
da upiše koliko studenata iz tog kolegija ima pozitivnu ocjenu.
Napisati okidač koji će korištenjem prethodne procedure držati 
vrijednost tog atributa uvijek točnim (ažurnim).*/

ALTER TABLE kolegiji ADD COLUMN brPolozenih INT ;

DELIMITER %%
DROP PROCEDURE IF EXISTS brojiPolozene %%
CREATE PROCEDURE brojiPolozene (IN kolegij INT)
BEGIN
	DECLARE pozitivni INT DEFAULT NULL;
	SELECT COUNT(*) INTO pozitivni FROM ocjene 
		WHERE idKolegij=kolegij AND ocjena>1;
	UPDATE kolegiji SET  brPolozenih=pozitivni 
		WHERE kolegiji.id=kolegij;
END; %%
DELIMITER %%

CALL brojiPolozene(1);
CALL brojiPolozene(2);

DELIMITER %%
DROP TRIGGER IF EXISTS osvjeziBrojPolozenih %%
CREATE TRIGGER osvjeziBrojPolozenih AFTER INSERT ON ocjene 
FOR EACH ROW
BEGIN
	CALL brojiPolozene(new.idKolegij);
END;
%%
DELIMITER ;



INSERT INTO ocjene VALUES (1, '0016199452', CURDATE(), CURTIME(), 5);