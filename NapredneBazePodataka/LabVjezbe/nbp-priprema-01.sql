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

SELECT * FROM radionica WHERE oznRadionica = "R2";

/* 2.  U bazi autoradionica: Napisati transakciju koja će sve radnike 
iz odjela sa šifrom 9 premjestiti u odjel sa šifrom 10, te nakon toga 
obrisati odjel sa šifrom 9. 
Potrebno je potvrditi da se navedene promjene nisu dogodile. */

SET AUTOCOMMIT = 0;
BEGIN;
	UPDATE radnik
	SET sifOdjel = 10
	WHERE sifOdjel = 9;
	
	DELETE FROM odjel WHERE sifOdjel = 9;
ROLLBACK;
SET AUTOCOMMIT = 1;
	
SELECT * FROM radnik WHERE sifOdjel = 9; -- 4 ntorke prije, 4 poslije
SELECT * FROM radnik WHERE sifOdjel = 10; -- 3 ntorke prije, 3 poslije

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
	SET titulaIza = CONCAT(titulaIza,',',titulaIspred)
	WHERE titulaIspred IS NOT NULL;
	
	UPDATE nastavnici
	SET titulaIspred = NULL;
COMMIT;
SET AUTOCOMMIT = 1;

SELECT titulaIza, titulaIspred FROM nastavnici;

/* 4.  U bazi autoradionica: Napisati proceduru koja će preko
parametra primiti oznaku radionice. 
Procedura mora ispisati ime i prezime te iznos plaće za onog 
radnika(radnike) koji radi u zadanoj radionici i ima najveću plaću.
Iznos plaće potrebno je računati kao umnožak vrijednosti atributa 
koefPlace i iznosOsnovice. */

DROP PROCEDURE IF EXISTS ispisiRadnike;
DELIMITER //
CREATE PROCEDURE ispisiRadnike(IN oznaka VARCHAR(50))
	BEGIN
		DECLARE najPlaca DOUBLE;
		SELECT MAX(KoefPlaca*IznosOsnovice) INTO najPlaca FROM radnik
		NATURAL JOIN odjel 
		NATURAL JOIN kvar 
		NATURAL JOIN rezervacija
		NATURAL JOIN radionica
		WHERE radionica.oznRadionica = oznaka;
		
		/*
		select imeRadnik, prezimeRadnik, KoefPlaca*IznosOsnovice
		from radnik
		where KoefPlaca*IznosOsnovice = najPlaca;
		*/
		
		SELECT DISTINCT imeRadnik, prezimeRadnik, KoefPlaca*IznosOsnovice
		FROM radnik
		NATURAL JOIN odjel
		NATURAL JOIN kvar
		NATURAL JOIN rezervacija
		NATURAL JOIN radionica
		WHERE radionica.oznRadionica = oznaka
		AND KoefPlaca*IznosOsnovice = najPlaca;
		
	END //
DELIMITER ;

CALL ispisiRadnike("R22");

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
CREATE PROCEDURE dodajOdlicne(IN idKol INT)
	BEGIN
		DECLARE brOdlicnih INT;
		SELECT COUNT(*) INTO brOdlicnih FROM ocjene
		JOIN kolegiji ON ocjene.idKolegij = kolegiji.id
		JOIN studenti ON ocjene.jmbagStudent = studenti.jmbag
		WHERE kolegiji.id = idKol
		AND ocjena = 5
		AND YEAR(studenti.datumUpisa) >= YEAR(CURDATE())-3;
		
		UPDATE kolegiji
		SET odlicnihStudenata = brOdlicnih
		WHERE kolegiji.id = idKol;
	END //
DELIMITER ;

CALL dodajOdlicne(10);

/* 7.  U bazi autoradionica: Napisati funkciju koja će svim radnicima
iz zadanog odjela povećati koeficijent plaće za 0,5, a svim ostalima
smanjiti za isti koeficijent. Funkcija vraća vrijednost 1. */

DROP FUNCTION IF EXISTS promijeniKoef;

DELIMITER //
CREATE FUNCTION promijeniKoef(sifra INT) RETURNS INT
	BEGIN
		UPDATE radnik
		SET KoefPlaca = KoefPlaca + 0.5
		WHERE sifOdjel = sifra;
		
		UPDATE radnik
		SET KoefPlaca = KoefPlaca - 0.5
		WHERE sifOdjel <> sifra;
		
		RETURN 1;
	END //
DELIMITER ;

SELECT promijeniKoef(2);

/* 8.  U bazi studenti: Napisati funkciju koja će za zadani smjer
vratiti podatak o broju koliko ukupno studenata studira na 
zadanom smjeru, a poštanski brojevi prebivanja i stanovanja su 
im različiti. */

DROP FUNCTION IF EXISTS brojStudenata;

DELIMITER //
CREATE FUNCTION brojStudenata(idSm INT) RETURNS INT
	BEGIN
		RETURN
		(SELECT COUNT(*) FROM studenti
		WHERE postBrPrebivanje <> postBrStanovanja
		AND idSmjer = idSm);
	END //
DELIMITER ;

SELECT brojStudenata(2);

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
		RETURN
		(SELECT oznRadionica FROM radionica
		NATURAL JOIN rezervacija
		NATURAL JOIN kvar
		NATURAL JOIN nalog
		NATURAL JOIN klijent
		WHERE sifKlijent = sifra
		ORDER BY datPrimitkaNalog DESC
		LIMIT 0,1);
	END //
DELIMITER ;

SELECT dohvatiRadionicu(1210);