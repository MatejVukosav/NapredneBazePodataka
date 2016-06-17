CREATE DATABASE radionica;
CREATE DATABASE studenti;

/********TRANSAKCIJE***********/
/*
1.
U bazi radionica, 2 radnika su se preselila sa "Zamjena krovnog prozora" na rad
na kvaru "Popravak felgi". Napisite transakciju koja to omogucuje.
Pretpostavimo da na Zamjeni krovnog prozora rade 2+ radnika 
*/

SET AUTOCOMMIT = 0;
BEGIN;
	UPDATE kvar
	SET brojRadnika = brojRadnika - 2
	WHERE nazivKvar = "Zamjena krovnog prozora";
	
	UPDATE kvar
	SET brojRadnika = brojRadnika + 2
	WHERE nazivKvar = "Popravak felgi";
	
	COMMIT;

SET AUTOCOMMIT = 1;

SELECT brojRadnika FROM kvar WHERE nazivKvar = "Zamjena krovnog prozora"; -- 7 pa 5
SELECT brojRadnika FROM kvar WHERE nazivKvar = "Popravak felgi"; -- 1 pa 3

/*
2.
U bazi radionica, radniku Žarko Dubinko povećajte koeficijent place na 3.12
te postavite tocku pohranjivanja "vrati" nakon te izmjene.
Zatim svim radnicima uvecajte koeficijent place za 0.36.
Napravite opoziv natrag do tocke pohrane
Ipisite placu svih radnika pod imenom "Placa" sortirano uzlazno prije i 
nakon transakcije
*/

SET AUTOCOMMIT = 0;
BEGIN;
	UPDATE radnik
	SET koefPlaca = 3.12
	WHERE imeRadnik = "Žarko"
	AND prezimeRadnik = "Dubinko";
	
	SAVEPOINT tocka;
	
	UPDATE radnik
	SET KoefPlaca = KoefPlaca + 0.36;
	
	ROLLBACK TO SAVEPOINT tocka;		
		
	COMMIT;

SET AUTOCOMMIT = 1;

SELECT imeRadnik, prezimeRadnik, KoefPlaca*IznosOsnovice AS Placa FROM radnik
ORDER BY KoefPlaca*IznosOsnovice DESC;

SELECT imeRadnik, prezimeRadnik, KoefPlaca*IznosOsnovice AS Placa FROM radnik
WHERE prezimeRadnik = "Dubinko" AND imeRadnik = "Žarko"; -- 88 prije, 6864 poslije

/*
3.
Potrebno je napisati transakciju koja će radionicama s oznakom R13
umanjiti satServis za 5, te radionicama s oznakom R4 uvećati za 5.
Potvrditi da se promjene nisu dogodile;
*/

SET AUTOCOMMIT = 0;
BEGIN;
	UPDATE rezervacija
	SET satServis = satServis - 5
	WHERE oznRadionica = "R13";
	
	UPDATE rezervacija
	SET satServis = satServis + 5
	WHERE oznRadionica = "R4";
	
	ROLLBACK;
	
SET AUTOCOMMIT = 1;

SELECT satServis, oznRadionica FROM rezervacija 
WHERE oznRadionica = "R13" OR oznRadionica = "R4";


/*
4.
U bazi studenti, kreirati tablicu "ucione" koja podrzava transakcije te sadrzi:
int(11) auto increment primary key "id",
int(11) "kapacitet",
varchar(15) "naziv" 

kopirajte sljedeci upit:

BEGIN WORK;
INSERT INTO ucione(kapacitet,naziv) VALUES (22,'Račlab');
SELECT SLEEP(5);
INSERT INTO ucione(kapacitet,naziv) VALUES (18,'MsLab');
COMMIT WORK;

Pokrenite upit, i prekinite ga u trenutku spavanja. Koliko n-torki ce biti 
u tablici? 
ODG: "0, simulirana je greska u transakciji tj. rollback se izvrsio."
Izbrisite tablicu "ucione" te kreirajte novu tablicu "ucione" ali ovaj put 
koristite ENGINE=MYISAM
Ponovo pokrenite gornju transakciju te ju prekinite u trenutku spavanja. 
Koliko n-torki je u tablici? Zasto?
ODG: "1, MYISAM ne podrzava transakcije, te se ne vrsi rollback."
 */

CREATE TABLE ucione(
	id INT(11) PRIMARY KEY AUTO_INCREMENT,
	kapacitet INT(11),
	naziv VARCHAR(15)
) ENGINE=MYISAM

DROP TABLE ucione;

BEGIN WORK;
	INSERT INTO ucione(kapacitet,naziv) VALUES (22,'Račlab');
	SELECT SLEEP(5);
	INSERT INTO ucione(kapacitet,naziv) VALUES (18,'MsLab');
COMMIT WORK;


/**********PROCEURE I FUNKCIJE********/


/* 5.
U bazi studenti, napravite proceduru "dohvatiJMBAG"
koja ce za ulazne parametre imati:
- ime studenta - VARCHAR(50)
- prezime studenta - VARCHAR(50)

a ona ce ispisati ime, prezime, te jmbag pronađenih studenata.
*/

DROP PROCEDURE IF EXISTS dohvatiJMBAG;
DELIMITER //
CREATE PROCEDURE dohvatiJMBAG(
	IN ulazIme VARCHAR(50), 
	IN ulazPrezime VARCHAR(50))
	
	BEGIN
		SELECT ime, prezime, jmbag FROM studenti
		WHERE ime = ulazIme
		AND prezime = ulazPrezime;
	END //

DELIMITER ;

CALL dohvatiJMBAG('Ivan','Horvat');


/*6.
Potrebno je napisati proceduru koja će za određeni
odjel pronaći njegov nadređeni odjel. Ukoliko odjel nema
nadređeni odjel potrebno je vratiti naziv tog odjela.
Riješiti pomoću INOUT.
*/

DROP PROCEDURE IF EXISTS proc1;
DELIMITER //
CREATE PROCEDURE proc1(INOUT ulazNaziv VARCHAR(50))
	BEGIN	
		DECLARE nad INT;
		
		SELECT sifNadOdjel INTO nad
		FROM odjel
		WHERE nazivOdjel = ulazNaziv;
		
		SELECT nazivOdjel INTO ulazNaziv FROM odjel
		WHERE sifOdjel = nad;
	END //
DELIMITER ;

SET @a = "Elektropokretači";
CALL proc1(@a);
SELECT @a;

SET @a = "Auto centar kod veselog Zagorca";
CALL proc1(@a);
SELECT @a;

SELECT sifNadOdjel FROM odjel WHERE nazivOdjel = "Auto centar kod veselog Zagorca";
SELECT sifNadOdjel FROM odjel WHERE nazivOdjel = "Elektropokretači";


/* 7.
Potrebno je napisati proceduru koja će za zadani fakultet
vratiti broj profesora i asistenata(dvije vrijednosti)
na tom fakultetu. Zanemariti podatak ako je ista osoba i profesor
i asistent, te obratiti pažnju što ako jedan profesor/asistent
radi na više kolegija.
*/

DROP PROCEDURE IF EXISTS proc2;
DELIMITER //
CREATE PROCEDURE proc2(
	IN ulazOib CHAR(11),
	OUT izlazProfesori INT,
	OUT izlazAsistenti INT)
	
	BEGIN
		SELECT COUNT(*) INTO izlazProfesori FROM nastavnici
		JOIN izvrsitelji ON nastavnici.jmbg = izvrsitelji.jmbgNastavnik
		JOIN kolegiji ON izvrsitelji.idKolegij = kolegiji.id
		JOIN ulogaIzvrsitelja ON izvrsitelji.idUlogaIzvrsitelja = ulogaIzvrsitelja.id
		JOIN smjerovi ON kolegiji.idSmjer = smjerovi.id
		JOIN ustanove ON smjerovi.oibUstanova = ustanove.oib
		WHERE ulogaIzvrsitelja.naziv = "profesor"
		AND ustanove.oib = ulazOib;
		
		SELECT COUNT(*) INTO izlazAsistenti FROM nastavnici
		JOIN izvrsitelji ON nastavnici.jmbg = izvrsitelji.jmbgNastavnik
		JOIN kolegiji ON izvrsitelji.idKolegij = kolegiji.id
		JOIN ulogaIzvrsitelja ON izvrsitelji.idUlogaIzvrsitelja = ulogaIzvrsitelja.id
		JOIN smjerovi ON kolegiji.idSmjer = smjerovi.id
		JOIN ustanove ON smjerovi.oibUstanova = ustanove.oib
		WHERE ulogaIzvrsitelja.naziv = "asistent"
		AND ustanove.oib = ulazOib;
	END //
DELIMITER ;

CALL proc2('08814003451', @brP, @brA);
SELECT @brP AS broj_profesora, @brA AS broj_asistenata;


/* 8.
U bazi studenti, napravite proceduru "ispisiOcjeneIProsjek"
koja ce za ulazni parametar imati:
- JMBAG studenta - CHAR(10)

a kao izlazni parametar:
- prosjek ocjena studenta - DOUBLE

Procedura treba izlistati ocjene studenta zajedno s njegovima podacima 
(putem JOIN-a) te vratiti prosjek u izlazni parametar koji se nakon 
poziva procedure moze opcionalno provjeriti.

Test JMBAG '0036499965' (ocjene 1,1,3 - AVG 1.67)
*/

DROP PROCEDURE IF EXISTS ispisiOcjeneIProsjek;
DELIMITER //
CREATE PROCEDURE ispisiOcjeneIProsjek(IN ulazJmbag CHAR(10), OUT izlazProsjek DOUBLE)
	BEGIN
		SELECT ime, prezime, ocjena FROM ocjene
		JOIN studenti ON ocjene.jmbagStudent = studenti.jmbag
		WHERE studenti.jmbag = ulazJmbag;
		
		SELECT AVG(ocjena) INTO izlazProsjek FROM ocjene
		JOIN studenti ON ocjene.jmbagStudent = studenti.jmbag
		WHERE studenti.jmbag = ulazJmbag;
				
	END //
DELIMITER ;

CALL ispisiOcjeneIProsjek('0036499965',@prosjek);
SELECT @prosjek;


/* 9.
U bazi radionica, napravite funkciju brojVozilaRegUMjestu koja ce primati 
naziv mjesta a vracat ce broj vozila koje su klijenti registrirali u tom mjestu.

KORISTEĆI NOVOSTVORENU FUNKCIJU ispisati broj vozila u svim mjestima gdje 
je registrirano barem jedno vozilo.
Sortirati silazno po broju vozila.
*/

DROP FUNCTION IF EXISTS brojVozilaRegUMjestu;
DELIMITER //
CREATE FUNCTION brojVozilaRegUMjestu(ulazNaziv VARCHAR(50)) RETURNS INT
DETERMINISTIC
	BEGIN
		DECLARE brojVozila INT;
			
		SELECT COUNT(*) INTO brojVozila FROM klijent
		JOIN mjesto ON klijent.pbrReg = mjesto.pbrMjesto
		WHERE mjesto.nazivMjesto = ulazNaziv;
		
		RETURN brojVozila;
	END //
DELIMITER ;

SELECT nazivMjesto, brojVozilaRegUMjestu(nazivMjesto) FROM mjesto
WHERE brojVozilaRegUMjestu(nazivMjesto) > 0
ORDER BY brojVozilaRegUMjestu(nazivMjesto) DESC;


/* 10.
U bazi studenti, napravite funkciju prosjekOcjenaPoUstanoviISmjeru koja za 
ulazne parametre ima:
- naziv ustanove VARCHAR(45)
- naziv smjera VARCHAR(100)

Funkcija mora vratiti prosjek svih ocjena u odredenom smjeru i ustanovi 

Test podaci:
'Fakultet elektrotehnike i računarstva','računarstvo' - Prosjek FER-a Racunarstvo
'Tehničko Veleučilište u Zagrebu','smjer računarstvo' - Prosjek TVZ-a Racunarstvo
*/

DROP FUNCTION IF EXISTS prosjekOcjenaPoUstanoviISmjeru;
DELIMITER //
CREATE FUNCTION prosjekOcjenaPoUstanoviISmjeru(
	ulazNaziv VARCHAR(45),
	ulazSmjer VARCHAR(100)) RETURNS DOUBLE
DETERMINISTIC
	BEGIN
		DECLARE prosjek DOUBLE;
		
		SELECT AVG(ocjena) INTO prosjek FROM ocjene
		JOIN studenti ON ocjene.jmbagStudent = studenti.jmbag
		JOIN smjerovi ON studenti.idSmjer = smjerovi.id
		JOIN ustanove ON smjerovi.oibUstanova = ustanove.oib
		WHERE smjerovi.naziv = ulazSmjer
		AND ustanove.naziv = ulazNaziv;
		
		RETURN prosjek;
	END //
DELIMITER ;

SELECT prosjekOcjenaPoUstanoviISmjeru('Fakultet elektrotehnike i računarstva','računarstvo')
 AS prosjekFERaRacunarstvo,
prosjekOcjenaPoUstanoviISmjeru('Tehničko Veleučilište u Zagrebu','smjer računarstvo')
 AS prosjekTVZaRacunarstvo;


/* 11.
Napisat funkciju koja vraća datum sa najviše zaprimljenih naloga.
Ako ih je više vratiti najnoviji datum.
*/

DROP FUNCTION IF EXISTS func1;
DELIMITER //
CREATE FUNCTION func1() RETURNS DATE
DETERMINISTIC
	BEGIN
		DECLARE datum DATE;
		DECLARE broj INT;
	
		SELECT datPrimitkaNalog, COUNT(datPrimitkaNalog) INTO datum, broj
		FROM nalog
		GROUP BY datPrimitkaNalog
		ORDER BY COUNT(datPrimitkaNalog) DESC, datPrimitkaNalog DESC
		LIMIT 0, 1;
		
		RETURN datum;
	END //
DELIMITER ;

SELECT func1();


/* 12.
Napisite funkciju koja ce dohvatiti trenutno vrijeme s posluzitelja
te vratiti poruku "Danas je ime_mjeseca"*/

DROP FUNCTION IF EXISTS func2;
DELIMITER //
CREATE FUNCTION func2() RETURNS VARCHAR(50)
DETERMINISTIC
	BEGIN
		DECLARE mjesec VARCHAR(20);
	
		CASE MONTH(CURDATE())
			WHEN 1 THEN SET mjesec = "siječanj";
			WHEN 2 THEN SET mjesec = "veljača";
			WHEN 3 THEN SET mjesec = "ožujak";
			WHEN 4 THEN SET mjesec = "travanj";
			WHEN 5 THEN SET mjesec = "svibanj";
			WHEN 6 THEN SET mjesec = "lipanj";
			WHEN 7 THEN SET mjesec = "srpanj";
			WHEN 8 THEN SET mjesec = "kolovoz";
			WHEN 9 THEN SET mjesec = "rujan";
			WHEN 10 THEN SET mjesec = "listopad";
			WHEN 11 THEN SET mjesec = "studeni";
			WHEN 12 THEN SET mjesec = "prosinac";
			ELSE RETURN "Greška";
		END CASE;
		
		RETURN CONCAT("Danas je ", mjesec);
	END //
DELIMITER ;

SELECT func2();


/* 13.
U bazi radionica napisati funkciju koja ce za odredenu radionicu
povecati kapacitet za 1 ukoliko je taj kapacitet manji od 6,
ukoliko je kapacitet 6, postaviti kapacitet na 1.
Ako unesena radionica ima kapacitet veci od 6, javiti porukom da je radionica
presla maksimalni kapacitet i zatim ga postaviti na maksimalnu vrijednost 6 

(1 -> 2 -> 3 -> 4 -> 5 -> 6 -> 1      6+ -> 6)
*/

DROP FUNCTION IF EXISTS func3;
DELIMITER //
CREATE FUNCTION func3(ulazRadionica VARCHAR(10)) RETURNS VARCHAR(50)
DETERMINISTIC
	BEGIN
		DECLARE broj INT(11);
	
		SELECT kapacitetRadnika INTO broj FROM radionica
		WHERE oznRadionica = ulazRadionica;
		

		IF broj < 6 THEN
			UPDATE radionica
			SET kapacitetRadnika = broj + 1
			WHERE oznRadionica = ulazRadionica;
		ELSEIF broj = 6 THEN
			UPDATE radionica
			SET kapacitetRadnika = 1
			WHERE oznRadionica = ulazRadionica;
		ELSEIF broj > 6 THEN
			UPDATE radionica
			SET kapacitetRadnika = 6
			WHERE oznRadionica = ulazRadionica;
			RETURN "Radionica je prešla maksimalni kapacitet!";
		END IF;
		
		
		SELECT kapacitetRadnika INTO broj FROM radionica
		WHERE oznRadionica = ulazRadionica;
		
		
		RETURN CONCAT("Radionica ", ulazRadionica, " sad ima kapacitet ", broj);
		
	END //
DELIMITER ;

SELECT func3("R26");


/* 14.
Napisite proceduru koja ce za uneseni broj N ispisati N brojeva
fibonaccijevog niza. 
Koristiti bigint i blob kako bi omogucili ispis i do 90 brojeva.

Napomena: fibonaccijev niz pocinje brojem 1, i svaki sljedeci broj je zbroj 
samog sebe i onog prije njega:  1, 1, 2, 3, 5, 8 ...
*/

DROP PROCEDURE IF EXISTS proc3;
DELIMITER //
CREATE PROCEDURE proc3(IN ulazBroj INT)
	BEGIN
		DECLARE niz BLOB;
		DECLARE prvi INT DEFAULT 1;
		DECLARE tmp INT DEFAULT 0;
		DECLARE drugi INT DEFAULT 1;
		DECLARE i INT DEFAULT 0;
		SET niz = "1, 1";
		
		WHILE i < ulazBroj-2 DO

			SET tmp = prvi + drugi;
			SET niz = CONCAT(niz, ", ", tmp);

			SET prvi = drugi;
			SET drugi = tmp;
			
			SET i = i + 1;
		
		END WHILE;
		
		SELECT niz;
		
	END //
DELIMITER ;

CALL proc3(15);


/* 15.
Napraviti funkciju koja ce obraditi i vratiti string na nacin da je svaki 
neparni znak veliko slovo, svaki parni znak malo slovo, te dodati XxX na 
oba kraja stringa.
Napomena: ako znak nije slovo, ostaviti ga kakav je.

'...Ovo je neki   zanimljiv string...' 
-> 
'XxX...oVo jE NeKi   zAnImLjIv sTrInG...XxX'
*/

DROP FUNCTION IF EXISTS func4;
DELIMITER //
CREATE FUNCTION func4(ulazString VARCHAR(255)) RETURNS VARCHAR(255)
DETERMINISTIC
	BEGIN
		DECLARE znak CHAR(1) DEFAULT "";
		DECLARE i INT DEFAULT 0;
		DECLARE novi VARCHAR(255) DEFAULT "";
		
		WHILE i <= LENGTH(ulazString) DO
			SET znak = MID(ulazString, i, 1);
			
			IF ((i%2=0) AND (znak REGEXP '[a-z]')) THEN
				SET novi = CONCAT(novi, LCASE(znak));
			ELSEIF ((i%2=1) AND (znak REGEXP '[a-z]')) THEN
				SET novi = CONCAT(novi, UCASE(znak));
			ELSE
				SET novi = CONCAT(novi, MID(ulazString, i, 1));
			END IF;
			
			SET i=i+1;
		
		END WHILE;
		
		RETURN CONCAT("XxX", novi, "XxX");
	END //
DELIMITER ;

SELECT func4("...ovo je  neki  zanimljiv string...");


/********KURSORI********/


/* 16.
U bazi studenti dodati novi atribut studentima 'Putnik' tipa Boolean
a zatim napraviti funkciju koja ce popuniti tu kolonu,
te vratiti postotak putnika.
Pretpostavimo da su putnici oni studenti koji imaju razlicito mjesto 
prebivanja i stanovanja koristiti loop i handler.
*/ 

ALTER TABLE studenti ADD Putnik BOOL DEFAULT FALSE;

DROP FUNCTION IF EXISTS func5;
DELIMITER //
CREATE FUNCTION func5() RETURNS DOUBLE
DETERMINISTIC
	BEGIN
		DECLARE t_jmbag CHAR(10);
		DECLARE flag BOOL DEFAULT FALSE;
		DECLARE brojPutnika, brojSvih INT DEFAULT 0;
		DECLARE kur CURSOR FOR
			SELECT jmbag FROM studenti
			WHERE postBrPrebivanje <> postBrStanovanja;
		DECLARE CONTINUE HANDLER FOR NOT FOUND SET flag=TRUE;
		
		OPEN kur;
		petlja:LOOP
			FETCH kur INTO t_jmbag;
			IF flag=TRUE THEN
				LEAVE petlja;
			END IF;

			UPDATE studenti
			SET Putnik = TRUE
			WHERE jmbag = t_jmbag;
			
			SET brojPutnika = brojPutnika + 1;
		END LOOP;
		CLOSE kur;
		
		SELECT COUNT(jmbag) INTO brojSvih FROM studenti;
		
		RETURN (brojPutnika/brojSvih)*100.00;
	END //
DELIMITER ;

SELECT func5();


/* 17.
 U bazi studenti napraviti proceduru koja za zadani string X
svim studenatima cije prezime zapocinje sa X, mjenja ID smjera na
zadanu vrijednost:

Test podaci:
prezime     idSmjer
Adžija         1
Amulić	       2
Anđal          3
Antunović      4 

promjeniSmjer('A',1) mjenja smjer na sva 4 zapisa
promjeniSmjer('An',2) mjenja smjer na 2 zapisa
promjeniSmjer('Ant',3) mjenja smjer samo Antunovicu
promjeniSmjer('Ć',4) ne postoji nijedno prezime koje pocinje sa 'Ć'

*/

DROP PROCEDURE IF EXISTS proc4;
DELIMITER //
CREATE PROCEDURE proc4(IN ulazString VARCHAR(50), IN ulazIdSmjer INT)
	BEGIN
		DECLARE flag BOOL DEFAULT FALSE;
		DECLARE t_jmbag CHAR(10);
		DECLARE kur CURSOR FOR
			SELECT jmbag FROM studenti
			WHERE prezime LIKE CONCAT(ulazString,"%");
		DECLARE CONTINUE HANDLER FOR NOT FOUND SET flag=TRUE;
		
		OPEN kur;
		petlja:LOOP
			FETCH kur INTO t_jmbag;
			IF flag=TRUE THEN
				LEAVE petlja;
			END IF;
		
			UPDATE studenti
			SET idSmjer = ulazIdSmjer
			WHERE jmbag = t_jmbag;
			
		END LOOP;
		CLOSE kur;
	END //
DELIMITER ;

CALL proc4("An", 3);

SELECT * FROM studenti WHERE prezime LIKE 'A%' ORDER BY prezime ASC;


/*18.
U bazi studenti potrebno je tablici studenti dodati novi atribut prosjecnaOcjena.
Napisati proceduru koja će pomoću kursora i handlera svim studentima izračunati
njihovu prosječnu ocjenu te ju upisat u novokreirani atribut. Ukoliko student
nema nijednu ocjenu potrebno je upisati vrijednost 'NEOCJENJEN' (obratiti pažnju 
na tip podatka atributa prosjecnaOcjena). Procedura treba ispisat broj 
dohvaćenih podataka, te broj neocjenjenih studenata.
*/

ALTER TABLE studenti ADD prosjecnaOcjena VARCHAR(20);

DROP PROCEDURE IF EXISTS proc5;
DELIMITER //
CREATE PROCEDURE proc5()
	BEGIN
		DECLARE t_jmbag VARCHAR(20);
		DECLARE prosjek DECIMAL(5, 3) DEFAULT 0;
		DECLARE brojNeoc INT DEFAULT 0;
		DECLARE dohvaceno INT DEFAULT 0;
		DECLARE flag BOOL DEFAULT FALSE;
		DECLARE kur CURSOR FOR
			SELECT jmbag FROM studenti;
		DECLARE CONTINUE HANDLER FOR NOT FOUND SET flag=TRUE;
		OPEN kur;
		SELECT FOUND_ROWS() INTO dohvaceno;
		petlja:LOOP
			FETCH kur INTO t_jmbag;
			IF flag=TRUE THEN
				LEAVE petlja;
			END IF;
			
			SELECT AVG(ocjena) INTO prosjek FROM ocjene
			WHERE jmbagStudent = t_jmbag;
			
			IF prosjek IS NULL THEN
				UPDATE studenti
				SET prosjecnaOcjena = "NEOCIJENJEN"
				WHERE jmbag = t_jmbag;
				SET brojNeoc = brojNeoc + 1;
			ELSE
				UPDATE studenti
				SET prosjecnaOcjena = prosjek
				WHERE jmbag = t_jmbag;
			END IF;
			
		END LOOP;
		CLOSE kur;
		
		SELECT dohvaceno, brojNeoc AS 'brojneocijenjenih';
	END //
DELIMITER ;

CALL proc5();


/*19.
Napisati proceduru koja će ispisati podatke klijenta(ime, prezime i šifru), 
te uz njega ispisati iznos popusta koji je taj klijent ostvario. Popust se 
dodjeljuje po slijedećem principu:
5% popusta za svakih 10 sati kvara, do maksimalnog popusta od 20%.
Potrebno je koristiti kursor, handler i privremenu tablicu. Ispisati samo one 
klijente koji imaju pravo na popust. Osigurat da po završetku procedure 
privremena tablica više nije dostupna.
*/

DROP PROCEDURE IF EXISTS proc6;
DELIMITER //
CREATE PROCEDURE proc6()
	BEGIN
		DECLARE flag BOOL DEFAULT FALSE;
		DECLARE t_sif INT;
		DECLARE t_ime, t_prezime VARCHAR(50);
		DECLARE t_sati INT;
		DECLARE temp1 INT;
		DECLARE kur CURSOR FOR
			SELECT klijent.sifKlijent, klijent.imeKlijent, klijent.prezimeKlijent, SUM(kvar.satiKvar)
			FROM klijent
			JOIN nalog ON klijent.sifKlijent = nalog.sifKlijent
			JOIN kvar ON nalog.sifKvar = kvar.sifKvar
			GROUP BY klijent.sifKlijent
			HAVING SUM(kvar.satiKvar)>=10;
		DECLARE CONTINUE HANDLER FOR NOT FOUND SET flag=TRUE;
		DROP TEMPORARY TABLE IF EXISTS temp;
		CREATE TEMPORARY TABLE temp(
			tempSifra INT,
			tempPrezime VARCHAR(50),
			tempIme VARCHAR(50),
			tempPopust INT
		);
		
		OPEN kur;
		petlja:LOOP
			FETCH kur INTO t_sif, t_ime, t_prezime, t_sati;
			IF flag=TRUE THEN
				LEAVE petlja;
			END IF;
			
			IF t_sati >= 40 THEN
				INSERT INTO temp VALUES(t_sif, t_prezime, t_ime, 20);
			ELSEIF t_sati >=30 THEN
				INSERT INTO temp VALUES(t_sif, t_prezime, t_ime, 15);
			ELSEIF t_sati >=20 THEN
				INSERT INTO temp VALUES(t_sif, t_prezime, t_ime, 10);
			ELSE
				INSERT INTO temp VALUES(t_sif, t_prezime, t_ime, 5);
			END IF;	
		END LOOP;
		CLOSE kur;
		
		SELECT * FROM temp;
		
		-- drop temporary table temp;
	END //
DELIMITER ;

CALL proc6();


/*20.
U tablici studenti potrebno je dodati novi atribut brStanovnika tablici mjesto,
te tablici zupanija. Broj stanovnika se odnosi na studente i nastavnike koji tamo
prebivaju. Koristeći proceduru, kursor i handler potrebno je popuniti novokreirane
atribute.
*/

ALTER TABLE mjesta ADD brStanovnika INT;
ALTER TABLE zupanije ADD brStanovnika INT;

DROP PROCEDURE IF EXISTS proc7;
DELIMITER //
CREATE PROCEDURE proc7()
	BEGIN
		DECLARE t_post INT;
		DECLARE t_zup INT;
		DECLARE brNastavnika, brStudenata INT DEFAULT 0;
		DECLARE flag BOOL DEFAULT FALSE;
		DECLARE kur1 CURSOR FOR
			SELECT postbr FROM mjesta;
		DECLARE kur2 CURSOR FOR
			SELECT id FROM zupanije;
		DECLARE CONTINUE HANDLER FOR NOT FOUND SET flag=TRUE;
		OPEN kur1;
		petlja:LOOP
			FETCH kur1 INTO t_post;
			IF flag=TRUE THEN
				LEAVE petlja;
			END IF;
			
			SELECT COUNT(*) INTO brNastavnika FROM mjesta
			JOIN nastavnici ON mjesta.postbr = nastavnici.postbr
			WHERE mjesta.postbr = t_post;
			
			SELECT COUNT(*) INTO brStudenata FROM mjesta
			JOIN studenti ON mjesta.postbr = studenti.postBrPrebivanje
			WHERE mjesta.postbr = t_post;
			
			UPDATE mjesta
			SET brStanovnika = brNastavnika + brStudenata
			WHERE postbr = t_post;
			
		END LOOP;
		CLOSE kur1;
		
		SET flag=FALSE;
		
		OPEN kur2;
		petlja:LOOP
			FETCH kur2 INTO t_zup;
			IF flag=TRUE THEN
				LEAVE petlja;
			END IF;
			
			SELECT COUNT(*) INTO brNastavnika FROM zupanije
			JOIN mjesta ON zupanije.id = mjesta.idZupanija
			JOIN nastavnici ON mjesta.postbr = nastavnici.postbr
			WHERE zupanije.id = t_zup;
			
			SELECT COUNT(*) INTO brStudenata FROM zupanije
			JOIN mjesta ON zupanije.id = mjesta.idZupanija
			JOIN studenti ON mjesta.postbr = studenti.postBrPrebivanje
			WHERE zupanije.id = t_zup;
			
			UPDATE zupanije
			SET brStanovnika = brNastavnika + brStudenata
			WHERE id = t_zup;
			
		END LOOP;
		CLOSE kur2;
	END //
DELIMITER ;

CALL proc7();

SELECT * FROM mjesta;
SELECT * FROM zupanije;


/*21.
 U bazi Radionica, dodati novi atribut 'Procjena' u tablicu Radnik te ju popuniti 
 na sljedeci nacin - ukoliko je Koeficijent place radnika = 0 upisati 'Nema Placu!'
ukoliko je manji od 40% najveceg Koeficijenta medju radnicima upisati 'Niska Placa',
veci(ili jednak) od 40% a manji od 80% maximalnog -> 'Normalna placa'
veci(ili jednak) od 80% -> 'Visoka placa'

Ispisati maxKoef, 40% granicu, 80% granicu te 4 seta rezultata za svaki tip 
procjene (posebno 'nema placu', posebno 'niska placa' itd.)

*/

ALTER TABLE radnik ADD Procjena VARCHAR(20);

DROP PROCEDURE IF EXISTS proc8;
DELIMITER //
CREATE PROCEDURE proc8()
	BEGIN
		DECLARE flag BOOL DEFAULT FALSE;
		DECLARE t_sif INT;
		DECLARE t_koef DOUBLE;
		DECLARE najveci DOUBLE;
		DECLARE kur CURSOR FOR
			SELECT sifRadnik, KoefPlaca FROM radnik;
		DECLARE CONTINUE HANDLER FOR NOT FOUND SET flag=TRUE;
		
		SELECT MAX(KoefPlaca) INTO najveci FROM radnik;
		OPEN kur;
			petlja:LOOP
				FETCH kur INTO t_sif, t_koef;
				IF flag=TRUE THEN
					LEAVE petlja;
				END IF;
				
				
				
				IF t_koef=0 THEN
					UPDATE radnik
					SET Procjena = "Nema Placu!"
					WHERE sifRadnik = t_sif;
				ELSEIF t_koef < 0.4*najveci THEN
					UPDATE radnik
					SET Procjena = "Niska Placa!"
					WHERE sifRadnik = t_sif;
				ELSEIF t_koef < 0.8*najveci THEN
					UPDATE radnik
					SET Procjena = "Normalna Placa!"
					WHERE sifRadnik = t_sif;
				ELSE
					UPDATE radnik
					SET Procjena = "Visoka Placa!"
					WHERE sifRadnik = t_sif;
				END IF;	
			END LOOP;
		CLOSE kur;
		
		SELECT najveci AS 'najveca', najveci*0.4 AS '40%', 
			najveci*0.8 AS '80%';
		SELECT * FROM radnik WHERE Procjena = "Nema Placu!";
		SELECT * FROM radnik WHERE Procjena = "Niska Placa!";
		SELECT * FROM radnik WHERE Procjena = "Normalna Placa!";
		SELECT * FROM radnik WHERE Procjena = "Visoka Placa!";


	END //
DELIMITER ;

CALL proc8();


/* 22.
U bazi studenti napraviti proceduru koja ce studenta sa ocjenom 1 iz nekog kolegija
kopirati u privremenu tablicu s atributima (opisUsmenog, ime, prezime, jmbag).
U opis napisati "Usmeni iz: X, Y, Z..." XYZ su kolegiji iz kojih student ima 
barem jednu jedinicu */

DROP PROCEDURE IF EXISTS proc9;
DELIMITER //
CREATE PROCEDURE proc9()
	BEGIN
		DECLARE t_jmbag, t_ime, t_prezime, t_kolegij VARCHAR(50);
		DECLARE flag BOOL DEFAULT FALSE;
		DECLARE kur CURSOR FOR
			SELECT DISTINCT kolegiji.naziv, jmbag, ime, prezime FROM studenti
			JOIN ocjene ON studenti.jmbag = ocjene.jmbagStudent
			JOIN kolegiji ON ocjene.idKolegij = kolegiji.id
			WHERE ocjene.ocjena = 1;
		DECLARE CONTINUE HANDLER FOR NOT FOUND SET flag=TRUE;
		
		DROP TEMPORARY TABLE IF EXISTS temp;
		CREATE TEMPORARY TABLE temp(
			tempJmbag VARCHAR(50),
			tempIme VARCHAR(50),
			tempPrezime VARCHAR(50),
			tempOpis VARCHAR(255)
		);		
		
		OPEN kur;
			petlja:LOOP
				FETCH kur INTO t_kolegij, t_jmbag, t_ime, t_prezime;
				IF flag=TRUE THEN
					LEAVE petlja;
				END IF;
				
				IF (t_jmbag IN (SELECT tempJmbag FROM temp)) THEN
					UPDATE temp
					SET tempOpis = CONCAT(tempOpis, ", ", t_kolegij)
					WHERE tempJmbag = t_jmbag;
				ELSEIF (t_jmbag NOT IN (SELECT tempJmbag FROM temp)) THEN
					INSERT INTO temp VALUES(t_jmbag, t_ime, t_prezime, CONCAT("Usmeni iz: ", t_kolegij));
				END IF;

				
			END LOOP;
		CLOSE kur;
		
		SELECT * FROM temp;
	END //
DELIMITER ;

CALL proc9();