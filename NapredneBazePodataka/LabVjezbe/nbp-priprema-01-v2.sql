/* 1.  U bazi autoradionica: Napisati transakciju koja će sve rezervacije 
koje su vezane uz radionicu „R2“ dodijeliti radionici „R3“.
Nakon toga je potrebno obrisati radionicu „R2“. 
Potrebno je potvrditi da su se promjene u bazi dogodile (COMMIT). */

SET AUTOCOMMIT = 0;
BEGIN;
	UPDATE rezervacija
	SET oznRadionica = "R3"
	WHERE oznRadionica = "R2";
	
	DELETE FROM radionica 
	WHERE oznRadionica = "R2";
COMMIT;
SET AUTOCOMMIT = 1;

/* 2.  U bazi autoradionica: Napisati transakciju koja će sve radnike 
iz odjela sa šifrom 9 premjestiti u odjel sa šifrom 10, te nakon toga 
obrisati odjel sa šifrom 9. 
Potrebno je potvrditi da se navedene promjene nisu dogodile. */

SET AUTOCOMMIT = 0;
BEGIN;
	UPDATE radnik
	SET sifOdjel = 10
	WHERE sifOdjel = 9;
	
	DELETE FROM odjel
	WHERE sifOdjel = 9;
ROLLBACK;
SET AUTOCOMMIT = 1;

/* 3.  U bazi studenti: Napisati transakciju koja će svakom nastavniku 
koji ima tituluIspred postavljenu na bilo koju vrijednost, tu titulu
prepisati u atribut titulaIza. 
Potrebno je osigurati da se titulaIza ne poništi, već da se 
titulaIspred konkatenira na tituluIza (ostaviti u istom atributu
obje titule te ih odvojiti zarezima). 
Nakon toga potrebno je obrisati vrijednost atributa titulaIspred 
svim nastavnicima. 
Potrebno je potvrditi da su se promjene u bazi dogodile. */

SET AUTOCOMMIT = 0;
BEGIN;
	UPDATE nastavnici
	SET titulaIza = CONCAT(titulaIza, ",", titulaIspred)
	WHERE titulaIspred IS NOT NULL;
	
	UPDATE nastavnici
	SET titulaIspred = NULL;
COMMIT;
SET AUTOCOMMIT = 1;

/* 4.  U bazi autoradionica: Napisati proceduru koja će preko
parametra primiti oznaku radionice. 
Procedura mora ispisati ime i prezime te iznos plaće za onog 
radnika(radnike) koji radi u zadanoj radionici i ima najveću plaću.
Iznos plaće potrebno je računati kao umnožak vrijednosti atributa 
koefPlace i iznosOsnovice. */

DROP PROCEDURE IF EXISTS ispisiRadnika;
DELIMITER //
CREATE PROCEDURE ispisiRadnika(IN oznaka VARCHAR(50))
	BEGIN
		DECLARE najPlaca DOUBLE;
		SELECT MAX(KoefPlaca*IznosOsnovice) INTO najPlaca
		FROM radnik
		NATURAL JOIN odjel
		NATURAL JOIN kvar
		NATURAL JOIN rezervacija
		NATURAL JOIN radionica
		WHERE oznRadionica = oznaka;
		
		SELECT DISTINCT imeRadnik, prezimeRadnik, MAX(KoefPlaca*IznosOsnovice)
		FROM radnik
		NATURAL JOIN odjel
		NATURAL JOIN kvar
		NATURAL JOIN rezervacija
		NATURAL JOIN radionica
		WHERE oznRadionica = oznaka
		AND KoefPlaca*IznosOsnovice = najPlaca;
		
	END //
DELIMITER ;

CALL ispisiRadnika("R22");

/* 5.  U bazi autoradionica: Napisati proceduru koja preko iste 
varijable prima podatak o radniku (sifRadnik), te vraća ukupan broj
naloga na kojima je zadani radnik radio. */

DROP PROCEDURE IF EXISTS dohvatiBrojNaloga;
DELIMITER //
CREATE PROCEDURE dohvatiBrojNaloga(INOUT sifra INT)
	BEGIN
		SELECT COUNT(*) INTO sifra FROM nalog
		WHERE sifRadnik = sifra;
	END //
DELIMITER ;

SET @var = 122;
CALL dohvatiBrojNaloga(@var);
SELECT @var;

/* 6.  U bazi studenti: Tablici kolegiji dodati novi atribut
odlicnihStudenata odgovarajućeg tipa podatka.
Napisati proceduru koja će zadanom kolegiju u dotični atribut 
upisati koliko ukupno studenata ima ocjenu odličan iz tog kolegija.
Potrebno je prebrojati samo one studente koji su se na studij
upisali u posljednje 3 godine (koristiti funkciju curdate). */

ALTER TABLE kolegiji ADD odlicnihStudenata INT;

DROP PROCEDURE IF EXISTS dodajOdlicne;
DELIMITER //
CREATE PROCEDURE dodajOdlicne(IN imeKol VARCHAR(100))
	BEGIN
		DECLARE broj INT;
		SELECT COUNT(*) INTO broj FROM kolegiji
		JOIN ocjene ON kolegiji.id = ocjene.idKolegij
		JOIN studenti ON ocjene.jmbagStudent = studenti.jmbag
		WHERE kolegiji.naziv = imeKol
		AND ocjene.ocjena = 5
		AND YEAR(datumUpisa) >= YEAR(CURDATE())-3;
		
		UPDATE kolegiji
		SET odlicnihStudenata = broj
		WHERE kolegiji.naziv = imeKol;
	END //
DELIMITER ;

CALL dodajOdlicne("Statistika");

/* 7.  U bazi autoradionica: Napisati funkciju koja će svim radnicima
iz zadanog odjela povećati koeficijent plaće za 0,5, a svim ostalima
smanjiti za isti koeficijent. Funkcija vraća vrijednost 1. */

DROP FUNCTION IF EXISTS mijenjajKoef;
DELIMITER //
CREATE FUNCTION mijenjajKoef(naziv VARCHAR(100)) RETURNS INT
	BEGIN
		UPDATE radnik
		SET KoefPlaca = KoefPlaca + 0.5
		WHERE radnik.sifOdjel IN
		(SELECT odjel.sifOdjel FROM odjel
		WHERE odjel.nazivOdjel = naziv);
		
		UPDATE radnik
		SET KoefPlaca = KoefPlaca - 0.5
		WHERE radnik.sifOdjel NOT IN
		(SELECT odjel.sifOdjel FROM odjel
		WHERE odjel.nazivOdjel = naziv);
		
		RETURN 1;
	END //
DELIMITER ;

SELECT mijenjajKoef("Limarija");

/* 8.  U bazi studenti: Napisati funkciju koja će za zadani smjer
vratiti podatak o broju koliko ukupno studenata studira na 
zadanom smjeru, a poštanski brojevi prebivanja i stanovanja su 
im različiti. */

DROP FUNCTION IF EXISTS brojStudenata;
DELIMITER //
CREATE FUNCTION brojStudenata(imeSmjera VARCHAR(100)) RETURNS INT
	BEGIN
		DECLARE var INT;
		SELECT COUNT(*) INTO var FROM studenti
		JOIN smjerovi ON studenti.idSmjer = smjerovi.id
		WHERE postBrStanovanja <> postBrPrebivanje
		AND smjerovi.naziv = imeSmjera;
		
		RETURN var;
	END //
DELIMITER ;

SELECT brojStudenata("smjer računarstvo");

/* 9.  U bazi autoradionica: Napisati funkciju koja će preko parametra
primiti podatak o klijentu (sifKlijent). 
Funkcija mora za zadanog klijenta vratiti podatak o radionici 
(OznRadionica) u kojoj se radi na nalogu vezanom uz zadanog klijenta.
Ako je za klijenta evidentirano više naloga, tada je potrebno vratiti
radionicu posljednjeg zaprimljenog naloga. */

DROP FUNCTION IF EXISTS dohvatiRadionicu;
DELIMITER //
CREATE FUNCTION dohvatiRadionicu(sifra INT) RETURNS VARCHAR(50)
	BEGIN
		DECLARE var VARCHAR(50);
		SELECT radionica.oznRadionica INTO var FROM radionica
		NATURAL JOIN rezervacija
		NATURAL JOIN kvar
		NATURAL JOIN nalog
		NATURAL JOIN klijent
		WHERE sifKlijent = sifra
		ORDER BY datPrimitkaNalog DESC
		LIMIT 0,1;
		RETURN var;
	END //
DELIMITER ;

SELECT dohvatiRadionicu(1210);
