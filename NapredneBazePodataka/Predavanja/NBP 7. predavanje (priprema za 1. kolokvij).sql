/********TRANSAKCIJE***********/
/*
1.
U bazi radionica, 2 radnika su se preselila sa "Zamjena krovnog prozora" na rad
na kvaru "Popravak felgi". Napisite transakciju koja to omogucuje.
Pretpostavimo da na Zamjeni krovnog prozora rade 2+ radnika 
*/

-- Za provjeru trenutnog stanja 
SELECT nazivKvar, brojRadnika FROM radionica.kvar WHERE nazivKvar IN ('Zamjena krovnog prozora','Popravak felgi');

BEGIN WORK;
UPDATE kvar
	SET brojRadnika=brojRadnika-2
	WHERE nazivKvar='Zamjena krovnog prozora';
UPDATE kvar
	SET brojRadnika=brojRadnika+2
	WHERE nazivKvar='Popravak felgi';
COMMIT WORK;
SELECT nazivKvar, brojRadnika FROM radionica.kvar WHERE nazivKvar IN ('Zamjena krovnog prozora','Popravak felgi');






/*
2.
U bazi radionica, radniku Žarko Dubinko povećajte koeficijent place na 3.12
te postavite tocku pohranjivanja "vrati" nakon te izmjene.
Zatim svim radnicima uvecajte koeficijent place za 0.36.
Napravite opoziv natrag do tocke pohrane
Ipisite placu svih radnika pod imenom "Placa" sortirano uzlazno prije i nakon transakcije
*/


SELECT imeRadnik, prezimeRadnik, (KoefPlaca*IznosOsnovice) AS Placa FROM radnik ORDER BY Placa ASC;
/*Žarko trenutno radi za samo 88kn mjesečno.*/

BEGIN WORK;
UPDATE radnik 
	SET KoefPlaca=3.12 
	WHERE imeRadnik='Žarko' AND prezimeRadnik='Dubinko';
	
SAVEPOINT vrati;

UPDATE radnik
	SET KoefPlaca=KoefPlaca+0.36;
	
ROLLBACK TO SAVEPOINT vrati;
COMMIT WORK;

SELECT imeRadnik, prezimeRadnik, (KoefPlaca*IznosOsnovice) AS Placa FROM radnik ORDER BY Placa ASC










/*
3.
Potrebno je napisati transakciju koja će radionicama s oznakom R13
umanjiti satServis za 5, te radionicama s oznakom R4 uvećati za 5.
Potvrditi da se promjene nisu dogodile;
*/
SET AUTOCOMMIT = 0;
START TRANSACTION;
  UPDATE rezervacija SET satServis = satServis - 5
  WHERE oznRadionica = 'R13';
  UPDATE rezervacija SET satServis = satServis + 5
  WHERE oznRadionica = 'R4';
ROLLBACK;
SET AUTOCOMMIT = 1;

SELECT *FROM rezervacija;



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

Pokrenite upit, i prekinite ga u trenutku spavanja. Koliko n-torki ce biti u tablici? 
ODG: "0, simulirana je greska u transakciji tj. rollback se izvrsio."

Izbrisite tablicu "ucione" te kreirajte novu tablicu "ucione" ali ovaj put koristite ENGINE=MYISAM
Ponovo pokrenite gornju transakciju te ju prekinite u trenutku spavanja. Koliko n-torki je u tablici? Zasto?
ODG: "1, MYISAM ne podrzava transakcije, te se ne vrsi rollback."
 */

-- DROP TABLE ucione
CREATE TABLE ucione 
(
        id INT(11) PRIMARY KEY AUTO_INCREMENT, 
	kapacitet INT(11),
	naziv VARCHAR(15)
)  -- ENGINE=MYISAM  
      ENGINE=INNODB

BEGIN WORK;
INSERT INTO ucione(kapacitet,naziv) VALUES (22,'Račlab');
SELECT SLEEP(5);
INSERT INTO ucione(kapacitet,naziv) VALUES (18,'MsLab');
COMMIT WORK;
SELECT * FROM ucione;





/**********PROCEURE I FUNKCIJE********/


/* 5.
U bazi studenti, napravite proceduru "dohvatiJMBAG"
koja ce za ulazne parametre imati:
- ime studenta - VARCHAR(50)
- prezime studenta - VARCHAR(50)

a ona ce ispisati ime, prezime, te jmbag pronađenih studenata.
*/

DELIMITER //
DROP PROCEDURE IF EXISTS  dohvatiJMBAG //
CREATE PROCEDURE dohvatiJMBAG
	(IN input_ime VARCHAR(50), IN input_prezime VARCHAR(50))

BEGIN
	SELECT ime, prezime, jmbag FROM studenti
	WHERE ime=input_ime AND prezime=input_prezime;
END //
DELIMITER ;

-- Test podaci
CALL dohvatiJMBAG('Antonio','Pavić');
CALL dohvatiJMBAG('Ivan','Horvat'); -- 3 Horvata 
CALL dohvatiJMBAG('Karla','Rolj');






/*6.
Potrebno je napisati proceduru koja će za određeni
odjel pronaći njegov nadređeni odjel. Ukoliko odjel nema
nadređeni odjel potrebno je vratiti naziv tog odjela.
Riješiti pomoću INOUT.
*/

DROP PROCEDURE IF EXISTS nadjiNadodjel;
DELIMITER //
CREATE PROCEDURE nadjiNadodjel(INOUT naziv VARCHAR(50))
BEGIN
  SELECT nadOdjel.nazivOdjel INTO naziv 
	FROM odjel nadOdjel 
		JOIN odjel podOdjel ON nadOdjel.sifOdjel = podOdjel.sifNadOdjel
			WHERE podOdjel.nazivOdjel = naziv;
END//
DELIMITER ;


SET @naziv = 'Elektropokretači';
CALL nadjiNadodjel(@naziv);
SELECT @naziv;

SET @naziv = 'Auto centar kod veselog Zagorca';
CALL nadjiNadodjel(@naziv);
SELECT @naziv;



/* 7.
Potrebno je napisati proceduru koja će za zadani fakultet
vratiti broj profesora i asistenata(dvije vrijednosti)
na tom fakultetu. Zanemariti podatak ako je ista osoba i profesor
i asistent, te obratiti pažnju što ako jedan profesor/asistent
radi na više kolegija.
*/


DROP PROCEDURE IF EXISTS brNastavnika;
DELIMITER //
CREATE PROCEDURE brNastavnika(IN oib CHAR(11), OUT brP INT, OUT brA INT)
BEGIN
  SELECT COUNT(DISTINCT jmbg) INTO brP FROM nastavnici JOIN
    izvrsitelji ON jmbg = jmbgNastavnik JOIN
    kolegiji ON idKolegij = kolegiji.id JOIN
    smjerovi ON idSmjer = smjerovi.id
  WHERE oibUstanova = oib
  AND idUlogaIzvrsitelja = 1;
  SELECT COUNT(DISTINCT jmbg) INTO brA FROM nastavnici JOIN
    izvrsitelji ON jmbg = jmbgNastavnik JOIN
    kolegiji ON idKolegij = kolegiji.id JOIN
    smjerovi ON idSmjer = smjerovi.id
  WHERE oibUstanova = oib
  AND idUlogaIzvrsitelja = 2;
END//
DELIMITER ;

CALL brNastavnika('02024882310', @brP, @brA);
SELECT @brP AS broj_profesora, @brA AS broj_asistenata;




/* 8.
U bazi studenti, napravite proceduru "ispisiOcjeneIProsjek"
koja ce za ulazni parametar imati:
- JMBAG studenta - CHAR(10)

a kao izlazni parametar:
- prosjek ocjena studenta - DOUBLE

Procedura treba izlistati ocjene studenta zajedno s njegovima podacima (putem JOIN-a)
te vratiti prosjek u izlazni parametar koji se nakon poziva procedure moze opcionalno provjeriti.

Test JMBAG '0036499965' (ocjene 1,1,3 - AVG 1.67)
*/

DROP PROCEDURE IF EXISTS ispisiOcjeneIProsjek;
DELIMITER //
CREATE PROCEDURE ispisiOcjeneIProsjek(IN input_jmbag CHAR(10), OUT output_prosjek DOUBLE)
	BEGIN
		SELECT * FROM ocjene 
			JOIN studenti ON studenti.jmbag = ocjene.jmbagStudent
			WHERE studenti.jmbag = input_jmbag;
		
		SELECT AVG(ocjene.ocjena) INTO output_prosjek FROM ocjene
			JOIN studenti ON studenti.jmbag = ocjene.jmbagStudent
			WHERE studenti.jmbag = input_jmbag;
	END //
DELIMITER ;

CALL ispisiOcjeneIProsjek('0036499965',@prosjek);
SELECT @prosjek;









/* 9.
U bazi radionica, napravite funkciju brojVozilaRegUMjestu koja ce primati naziv mjesta
a vracat ce broj vozila koje su klijenti registrirali u tom mjestu.

KORISTEĆI NOVOSTVORENU FUNKCIJU ispisati broj vozila u svim mjestima gdje je registrirano barem jedno vozilo.
Sortirati silazno po broju vozila.
*/

DELIMITER //
DROP FUNCTION IF EXISTS brojVozilaRegUMjestu //
CREATE FUNCTION brojVozilaRegUMjestu (input_nazivMjesto VARCHAR(255)) RETURNS INT
DETERMINISTIC
	BEGIN
		DECLARE brojVozila INT DEFAULT NULL;
		SELECT COUNT(klijent.pbrReg) INTO brojVozila FROM klijent
			JOIN mjesto ON mjesto.pbrMjesto = klijent.pbrReg
			WHERE mjesto.nazivMjesto = input_nazivMjesto;
		RETURN brojVozila;
	END //
DELIMITER ;

SELECT nazivMjesto, brojVozilaRegUMjestu(nazivMjesto) FROM mjesto
WHERE brojVozilaRegUMjestu(nazivMjesto) > 0
ORDER BY 2 DESC;








/* 10.
U bazi studenti, napravite funkciju prosjekOcjenaPoUstanoviISmjeru koja za ulazne parametre ima:
- naziv ustanove VARCHAR(45)
- naziv smjera VARCHAR(100)

Funkcija mora vratiti prosjek svih ocjena u odredenom smjeru i ustanovi 

Test podaci:
'Fakultet elektrotehnike i računarstva','računarstvo' - Prosjek FER-a Racunarstvo
'Tehničko Veleučilište u Zagrebu','smjer računarstvo' - Prosjek TVZ-a Racunarstvo
*/

DELIMITER //
DROP FUNCTION IF EXISTS prosjekOcjenaPoUstanoviISmjeru //
CREATE FUNCTION prosjekOcjenaPoUstanoviISmjeru
(input_nazivUstanove VARCHAR(45), input_nazivSmjer VARCHAR(100))
RETURNS DECIMAL(6,2)
DETERMINISTIC
	BEGIN
		DECLARE prosjek DOUBLE;
		SELECT AVG(ocjene.ocjena) INTO prosjek FROM ocjene
			JOIN kolegiji ON kolegiji.id = ocjene.idKolegij
			JOIN smjerovi ON smjerovi.id = kolegiji.idSmjer
			JOIN ustanove ON ustanove.oib = smjerovi.oibUstanova		
		WHERE ustanove.naziv = input_nazivUstanove
		AND smjerovi.naziv = input_nazivSmjer;
		
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
DROP FUNCTION IF EXISTS maxNaloga;
DELIMITER //
CREATE FUNCTION maxNaloga() RETURNS DATE
DETERMINISTIC
BEGIN
  DECLARE datum DATE;
  DECLARE brNaloga INT;
  SELECT datPrimitkaNalog, COUNT(datPrimitkaNalog) INTO datum, brNaloga
  FROM nalog
  GROUP BY datPrimitkaNalog
  ORDER BY COUNT(datPrimitkaNalog) DESC, datPrimitkaNalog DESC
  LIMIT 1;
  RETURN datum;
END//
DELIMITER ;

SELECT maxNaloga();




/* 12.
Napisite funkciju koja ce dohvatiti trenutno vrijeme s posluzitelja
te vratiti poruku "Danas je ime_mjeseca"*/

DELIMITER //
DROP FUNCTION IF EXISTS tekuciMjesec //
CREATE FUNCTION tekuciMjesec() RETURNS VARCHAR(100)
DETERMINISTIC
	BEGIN
		DECLARE poruka VARCHAR(100);
		
		CASE MONTH(DATE(NOW())) -- alternativa CURDATE()-a
		WHEN 1 THEN SET poruka='Danas je Siječanj';
		WHEN 2 THEN SET poruka='Danas je Veljača';
		WHEN 3 THEN SET poruka='Danas je Ožujak';
		WHEN 4 THEN SET poruka='Danas je Travanj';
		WHEN 5 THEN SET poruka='Danas je Svibanj';
		WHEN 6 THEN SET poruka='Danas je Lipanj';
		WHEN 7 THEN SET poruka='Danas je Srpanj';
		WHEN 8 THEN SET poruka='Danas je Kolovoz';
		WHEN 9 THEN SET poruka='Danas je Rujan';
		WHEN 10 THEN SET poruka='Danas je Listopad';  
		WHEN 11 THEN SET poruka='Danas je Studeni';
		WHEN 12 THEN SET poruka='Danas je Prosinac';	
		ELSE SET poruka='Greška u sustavu';	
		END CASE;
		
		RETURN poruka;
	END //
DELIMITER ;

SELECT tekuciMjesec();





/* 13.
U bazi radionica napisati funkciju koja ce za odredenu radionicu
povecati kapacitet za 1 ukoliko je taj kapacitet manji od 6,
ukoliko je kapacitet 6, postaviti kapacitet na 1.
Ako unesena radionica ima kapacitet veci od 6, javiti porukom da je radionica
presla maksimalni kapacitet i zatim ga postaviti na maksimalnu vrijednost 6 

(1 -> 2 -> 3 -> 4 -> 5 -> 6 -> 1      6+ -> 6)
*/

DELIMITER //
DROP FUNCTION IF EXISTS promjeniKapacitet //
CREATE FUNCTION promjeniKapacitet(i_oznRadionica VARCHAR(50)) 
RETURNS VARCHAR(100)
DETERMINISTIC
	BEGIN
		DECLARE temp_kapacitet INT(11);
		
		SELECT kapacitetRadnika INTO temp_kapacitet FROM radionica
		WHERE oznRadionica = i_oznRadionica;
	
		IF temp_kapacitet = 1 THEN
			UPDATE radionica
			SET kapacitetRadnika = 2
			WHERE radionica.oznRadionica = i_oznRadionica;
		ELSEIF 	temp_kapacitet = 2 THEN
			UPDATE radionica
			SET kapacitetRadnika = 3
			WHERE radionica.oznRadionica = i_oznRadionica;
		ELSEIF 	temp_kapacitet = 3 THEN
			UPDATE radionica
			SET kapacitetRadnika = 4
			WHERE radionica.oznRadionica = i_oznRadionica;
		ELSEIF 	temp_kapacitet = 4 THEN
			UPDATE radionica
			SET kapacitetRadnika = 5
			WHERE radionica.oznRadionica = i_oznRadionica;
		ELSEIF 	temp_kapacitet = 5 THEN
			UPDATE radionica
			SET kapacitetRadnika = 6
			WHERE radionica.oznRadionica = i_oznRadionica;
		ELSEIF 	temp_kapacitet = 6 THEN
			UPDATE radionica
			SET kapacitetRadnika = 1
			WHERE radionica.oznRadionica = i_oznRadionica;
		ELSEIF temp_kapacitet > 6 THEN
			UPDATE radionica
			SET kapacitetRadnika = 6
			WHERE radionica.oznRadionica = i_oznRadionica;
			RETURN 'Radionica je presla maksimalni kapacitet! Kapacitet postavljen na 6.';
		ELSEIF i_oznRadionica NOT IN (SELECT oznRadionica FROM radionica)  THEN			
			RETURN 'Ta radionica ne postoji!';
		END IF;
		
		SELECT kapacitetRadnika INTO temp_kapacitet FROM radionica
		WHERE oznRadionica = i_oznRadionica; -- refreshaj kapacitet nakon promjene
		
		RETURN CONCAT('Radionica ',i_oznRadionica,' sada ima kapaciteta za ', temp_kapacitet, ' radnika.');
		
	END //
DELIMITER ;

SELECT promjeniKapacitet('R26');  -- pokrenuti upit par puta  
SELECT promjeniKapacitet('R30');  -- ne postoji

UPDATE radionica 
SET kapacitetRadnika = 8 
WHERE oznRadionica = 'R26';   -- prelazi limit radionice
SELECT promjeniKapacitet('R26');  -- ispravlja gresku ^




/* 14.
Napisite proceduru koja ce za uneseni broj N ispisati N brojeva fibonaccijevog niza. 
Koristiti bigint i blob kako bi omogucili ispis i do 90 brojeva.

Napomena: fibonaccijev niz pocinje brojem 1, i svaki sljedeci broj je zbroj samog sebe i 
onog prije njega:  1, 1, 2, 3, 5, 8 ...
*/


DELIMITER //
DROP PROCEDURE IF EXISTS fibonacci //
CREATE PROCEDURE fibonacci(i_numOfNumbers INT)
	BEGIN
		DECLARE i INT DEFAULT 2;
		DECLARE trenutniBroj BIGINT DEFAULT 1;
		DECLARE prosliBroj BIGINT DEFAULT 1;
		DECLARE niz BLOB DEFAULT ' 1\n 1';
		
		WHILE i < i_numOfNumbers DO
		SET trenutniBroj = trenutniBroj + prosliBroj;
		SET prosliBroj = trenutniBroj - prosliBroj;
		SET i = i + 1;
		SET niz = CONCAT(niz,'\n ',trenutniBroj);
		END WHILE;
		
		IF i_numOfNumbers = 0 THEN
			SET niz = ' ';
		ELSEIF i_numOfNumbers = 1 THEN
			SET niz = ' 1';
		END IF;
		
		SELECT niz AS FibonnacijevNiz;		
	END //

DELIMITER ;

CALL fibonacci(92); -- kliknuti na zapis dolje ("1K")






/* 15.
Napraviti funkciju koja ce obraditi i vratiti string na nacin da je svaki neparni znak
veliko slovo, svaki parni znak malo slovo, te dodati XxX na oba kraja stringa.
Napomena: ako znak nije slovo, ostaviti ga kakav je.

'...Ovo je neki   zanimljiv string...' -> 'XxX...oVo jE NeKi   zAnImLjIv sTrInG...XxX'
*/


DELIMITER //
DROP FUNCTION IF EXISTS obradi //
CREATE FUNCTION obradi(i_string VARCHAR(255)) RETURNS VARCHAR(255)
DETERMINISTIC
	BEGIN
		DECLARE i INT DEFAULT 1;
		DECLARE trenutniZnak CHAR(1) DEFAULT '';
		DECLARE noviString VARCHAR(255) DEFAULT '';
		
		REPEAT 
			SET trenutniZnak = MID(i_string,i,1);
			IF ( (i%2 = 0) AND (trenutniZnak REGEXP '[a-z]') ) THEN
				SET noviString = CONCAT(noviString, LCASE(trenutniZnak));
				
			ELSEIF ( (i%2 = 1) AND (trenutniZnak REGEXP '[a-z]') ) THEN
				SET noviString = CONCAT(noviString, UCASE(trenutniZnak));
				
			ELSE 
				SET noviString = CONCAT(noviString, MID(i_string,i,1));
			END IF;	
			
			SET i = i + 1;
		UNTIL i > LENGTH(i_string)
		END REPEAT;
		
		SET noviString = CONCAT('XxX',noviString,'XxX');
		
		RETURN noviString;
	END //
DELIMITER ; 

SELECT obradi('...Ovo je neki   zanimljiv string...');
SELECT obradi('*?=)(/&%$#" Ovi znakovi moraju ostati isti :)');









/********KURSORI********/


/* 16.
U bazi studenti dodati novi atribut studentima 'Putnik' tipa Boolean
a zatim napraviti funkciju koja ce popuniti tu kolonu,
te vratiti postotak putnika.
Pretpostavimo da su putnici oni studenti koji imaju razlicito mjesto prebivanja i stanovanja
koristiti loop i handler.
*/ 


ALTER TABLE studenti
ADD COLUMN putnik BOOLEAN DEFAULT NULL;

DELIMITER //
DROP FUNCTION IF EXISTS putnici //
CREATE FUNCTION putnici() RETURNS VARCHAR (50)
DETERMINISTIC
	BEGIN
		DECLARE poruka VARCHAR(50);
		DECLARE brStudenta INT DEFAULT 0;
		DECLARE brPutnika INT DEFAULT 0;
		DECLARE error BOOLEAN DEFAULT FALSE;
		DECLARE t_jmbag CHAR(10);
		DECLARE t_PBP, t_PBS INT(11);
		DECLARE postotak DECIMAL (4,2);
	
		
		DECLARE kur CURSOR FOR SELECT jmbag, postBrPrebivanje, postBrStanovanja FROM studenti;
		DECLARE CONTINUE HANDLER FOR NOT FOUND SET error=TRUE;
		OPEN kur;
		SELECT FOUND_ROWS() INTO brStudenta;
	
		petlja:LOOP
		IF error=TRUE THEN LEAVE petlja; END IF;
		FETCH kur INTO t_jmbag, t_PBP, t_PBS;
		
		IF t_PBP = t_PBS THEN 
			UPDATE studenti
			SET putnik = FALSE
			WHERE jmbag=t_jmbag;
		ELSE 
			UPDATE studenti
			SET putnik = TRUE
			WHERE jmbag=t_jmbag;
			SET brPutnika = brPutnika + 1;
		END IF;
	
		END LOOP petlja;
		SET postotak = brPutnika / brStudenta * 100;
		SET poruka = CONCAT(postotak,'% studenata su putnici');
	RETURN poruka;
	END //
DELIMITER ;

SELECT putnici();
SELECT ime, prezime, putnik FROM studenti;




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


DELIMITER //
DROP PROCEDURE IF EXISTS promjeniSmjer //
CREATE PROCEDURE promjeniSmjer(IN i_prez VARCHAR(255), IN i_idSmjer INT(11))
	BEGIN
		DECLARE dohvaceno,i,br_uredenih INT DEFAULT 0;
		DECLARE trenutni_jmbag CHAR(10);
		DECLARE trenutno_prezime VARCHAR(50);
		DECLARE trenutni_idSmjer INT(11);
		DECLARE kur CURSOR FOR SELECT jmbag,prezime,idSmjer FROM studenti;
		OPEN kur;
		SELECT FOUND_ROWS() INTO dohvaceno;
	
		WHILE i<dohvaceno DO
			FETCH kur INTO trenutni_jmbag,trenutno_prezime,trenutni_idSmjer;
			IF trenutno_prezime REGEXP CONCAT('^',i_prez,'.+') THEN 
			-- primjetio sam da LIKE Ć% izbacuje 6 rezultata, pa sam stavio regexp
				UPDATE studenti
				SET idSmjer = i_idSmjer
				WHERE prezime = trenutno_prezime;
				SET br_uredenih = br_uredenih + 1;
			END IF;
			SET i = i + 1;
		END WHILE;
		
		CLOSE kur;
		SELECT CONCAT('Uredeno je ', br_uredenih, ' n-torki.');
	END //
DELIMITER ; 

CALL promjeniSmjer('A',1);
CALL promjeniSmjer('An',2);
CALL promjeniSmjer('Ant',3);
CALL promjeniSmjer('Ć',4);
SELECT * FROM studenti;



/*18.
U bazi studenti potrebno je tablici studenti dodati novi atribut prosjecnaOcjena.
Napisati proceduru koja će pomoću kursora i handlera svim studentima izračunati
njihovu prosječnu ocjenu te ju upisat u novokreirani atribut. Ukoliko student
nema nijednu ocjenu potrebno je upisati vrijednost 'NEOCJENJEN' (obratiti pažnju na
tip podatka atributa prosjecnaOcjena). Procedura treba ispisat broj dohvaćenih
podataka, te broj neocjenjenih studenata.
*/
ALTER TABLE studenti ADD COLUMN prosjek VARCHAR(10);
DROP PROCEDURE IF EXISTS izracunajProsjek;
DELIMITER //
CREATE PROCEDURE izracunajProsjek()
BEGIN
  DECLARE prosjekOcjena DECIMAL(5, 3) DEFAULT 0;
  DECLARE dohvaceno INT;
  DECLARE brNeocjenjenih INT DEFAULT 0;
  DECLARE id CHAR(10);
  DECLARE zaustavi BOOL;
  DECLARE kur CURSOR FOR SELECT jmbag FROM studenti;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET zaustavi = TRUE;
  SET zaustavi = FALSE;
  OPEN kur;
  SELECT FOUND_ROWS() INTO dohvaceno;
  petlja:LOOP
    FETCH kur INTO id;
    IF zaustavi = TRUE THEN
      LEAVE petlja;
    END IF;
    SELECT AVG(ocjena) INTO prosjekOcjena FROM ocjene WHERE jmbagStudent = id;
    IF prosjekOcjena IS NULL THEN
      UPDATE studenti SET prosjek = 'NEOCJENJEN' WHERE jmbag = id;
      SET brNeocjenjenih = brNeocjenjenih + 1;
    ELSE
      UPDATE studenti SET prosjek = prosjekOcjena WHERE jmbag = id;
    END IF;
  END LOOP;
  CLOSE kur;
  SELECT dohvaceno, brNeocjenjenih AS 'Broj neocjenjenih';
END//
DELIMITER ;

CALL izracunajProsjek();
SELECT *FROM studenti;





/*19.
Napisati proceduru koja će ispisati podatke klijenta(ime, prezime i šifru), te uz njega ispisati
iznos popusta koji je taj klijent ostvario. Popust se dodjeljuje po slijedećem principu:
5% popusta za svakih 10 sati kvara, do maksimalnog popusta od 20%.
Potrebno je koristiti kursor, handler i privremenu tablicu. Ispisati samo one klijente koji imaju
pravo na popust. Osigurat da po završetku procedure privremena tablica više nije dostupna.
*/
DROP PROCEDURE IF EXISTS ispisiPopuste;
DELIMITER //
CREATE PROCEDURE ispisiPopuste()
BEGIN
  DECLARE sif, brSati, popust INT;
  DECLARE ime, prezime VARCHAR(255);
  DECLARE nastavi BOOL;
  DECLARE kur CURSOR FOR SELECT klijent.sifKlijent, klijent.imeKlijent, klijent.prezimeKlijent,
				SUM(kvar.satiKvar)
			 FROM klijent JOIN
			   nalog ON klijent.sifKlijent = nalog.sifKlijent JOIN
			   kvar ON nalog.sifKvar = kvar.sifKvar
			 GROUP BY klijent.sifKlijent;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET nastavi = FALSE;
  SET nastavi = TRUE;
  DROP TEMPORARY TABLE IF EXISTS tmp;
  CREATE TEMPORARY TABLE tmp (
    sif INT,
    ime VARCHAR(255),
    prezime VARCHAR(255),
    popust INT
  );
  OPEN kur;
  petlja:LOOP
    FETCH kur INTO sif, ime, prezime, brSati;
    IF nastavi = FALSE THEN
      LEAVE petlja;
    END IF;
    SET popust = 0;
    IF brSati >= 40 THEN
      INSERT INTO tmp VALUES(sif, ime, prezime, 20);
    ELSEIF brSati >= 30 THEN
      INSERT INTO tmp VALUES(sif, ime, prezime, 15);
    ELSEIF brSati >= 20 THEN
      INSERT INTO tmp VALUES(sif, ime, prezime, 10);
    ELSEIF brSati >= 10 THEN
      INSERT INTO tmp VALUES(sif, ime, prezime, 5);
    END IF;
  END LOOP;
  SELECT *FROM tmp;
  DROP TEMPORARY TABLE IF EXISTS tmp;
END//
DELIMITER ;

CALL ispisiPopuste();





/*20.
U tablici studenti potrebno je dodati novi atribut brStanovnika tablici mjesto,
te tablici zupanija. Broj stanovnika se odnosi na studente i nastavnike koji tamo
prebivaju. Koristeći proceduru, kursor i handler potrebno je popuniti novokreirane
atribute.
*/
ALTER TABLE mjesta ADD COLUMN brStanovnika INT;
ALTER TABLE zupanije ADD COLUMN brStanovnika INT;
DROP PROCEDURE IF EXISTS popisiStanovnike;
DELIMITER //
CREATE PROCEDURE popisiStanovnike()
BEGIN
  DECLARE sifZup, pbr, broj, brojStanovnika INT;
  DECLARE zaustavi BOOL;
  DECLARE kurMj CURSOR FOR SELECT postbr FROM mjesta;
  DECLARE kurZup CURSOR FOR SELECT id FROM zupanije;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET zaustavi = TRUE;
  SET zaustavi = FALSE;
  OPEN kurMj;
  petlja:LOOP
    FETCH kurMj INTO pbr;
    IF zaustavi = TRUE THEN
      LEAVE petlja;
    END IF;
    SELECT COUNT(*) INTO broj FROM studenti WHERE postbrprebivanje = pbr;
    SET brojStanovnika = broj;
    SELECT COUNT(*) INTO broj FROM nastavnici WHERE postbr = pbr;
    SET brojStanovnika = brojStanovnika + broj;
    UPDATE mjesta SET brStanovnika = brojStanovnika WHERE postbr = pbr;
  END LOOP;
  SET zaustavi = FALSE;
  OPEN kurZup;
  petlja:LOOP
    FETCH kurZup INTO sifZup;
    IF zaustavi = TRUE THEN
      LEAVE petlja;
    END IF;
    SELECT SUM(brStanovnika) INTO broj FROM mjesta WHERE idZupanija = sifZup;
    UPDATE zupanije SET brStanovnika = broj WHERE id = sifZup;
  END LOOP;
END//
DELIMITER ;

CALL popisiStanovnike();
SELECT *FROM mjesta;
SELECT *FROM zupanije;

















/*21.
 U bazi Radionica, dodati novi atribut 'Procjena' u tablicu Radnik te ju popuniti na
sljedeci nacin - ukoliko je Koeficijent place radnika = 0 upisati 'Nema Placu!'
ukoliko je manji od 40% najveceg Koeficijenta medju radnicima upisati 'Niska Placa',
veci(ili jednak) od 40% a manji od 80% maximalnog -> 'Normalna placa'
veci(ili jednak) od 80% -> 'Visoka placa'

Ispisati maxKoef, 40% granicu, 80% granicu te 4 seta rezultata za svaki tip procjene
(posebno 'nema placu', posebno 'niska placa' itd.)

*/

ALTER TABLE radnik
ADD COLUMN Procjena VARCHAR(50) DEFAULT NULL;

DELIMITER //
DROP PROCEDURE IF EXISTS procjeniPlace //
CREATE PROCEDURE procjeniPlace()
	BEGIN
		DECLARE dohvaceno,i INT DEFAULT 0;
		DECLARE trenutna_sifRadnik INT(11);
		DECLARE trenutna_KoefPlaca DECIMAL(6,2);
		DECLARE maxKoef DECIMAL(6,3);
		DECLARE kur CURSOR FOR SELECT sifRadnik, KoefPlaca FROM radnik;
			
		SELECT MAX(KoefPlaca) INTO maxKoef FROM radnik;
		OPEN kur;
		SELECT FOUND_ROWS() INTO dohvaceno;
	
		WHILE i<dohvaceno DO
			FETCH kur INTO trenutna_sifRadnik, trenutna_KoefPlaca;
				IF trenutna_KoefPlaca = 0.0 THEN
					UPDATE radnik
					SET Procjena = 'Nema Placu!'
					WHERE sifRadnik = trenutna_sifRadnik;
				ELSEIF (trenutna_KoefPlaca > 0) AND (trenutna_KoefPlaca < 0.4*maxKoef) THEN
					UPDATE radnik
					SET Procjena = 'Niska Placa'
					WHERE sifRadnik = trenutna_sifRadnik;
				ELSEIF (trenutna_KoefPlaca >= 0.4*maxKoef) AND (trenutna_KoefPlaca < 0.8*maxKoef) THEN
					UPDATE radnik
					SET Procjena = 'Normalna Placa'
					WHERE sifRadnik = trenutna_sifRadnik;
				ELSE 
					UPDATE radnik
					SET Procjena = 'Visoka Placa'
					WHERE sifRadnik = trenutna_sifRadnik;
				END IF;
			SET i = i + 1;
		END WHILE;
		
		CLOSE kur;
		SELECT maxKoef AS 'MAX_KOEFICIJENT', 0.4*maxKoef AS '0.4_GRANICA', 0.8*maxKoef AS '0.8_GRANICA';
		SELECT * FROM radnik WHERE procjena = 'Nema Placu!';
	 	SELECT * FROM radnik WHERE procjena = 'Niska Placa';
	 	SELECT * FROM radnik WHERE procjena = 'Normalna Placa';
	 	SELECT * FROM radnik WHERE procjena = 'Visoka Placa';
	END //
DELIMITER ; 

UPDATE radnik SET KoefPlaca = 0 WHERE sifRadnik = 199; -- za provjeru procjene = 'Nema Placu!'
CALL procjeniPlace();



/* 22.
U bazi studenti napraviti proceduru koja ce studenta sa ocjenom 1 iz nekog kolegija
kopirati u privremenu tablicu s atributima (opisUsmenog, ime, prezime, jmbag).
U opis napisati "Usmeni iz: X, Y, Z..." XYZ su kolegiji iz kojih student ima barem jednu jedinicu */

DELIMITER //
DROP PROCEDURE IF EXISTS tkoMoraIciNaUsmeni//
CREATE PROCEDURE tkoMoraIciNaUsmeni()
	BEGIN
	
	DECLARE error BOOL DEFAULT FALSE;
	DECLARE t_nazivKolegij VARCHAR(100);
	DECLARE t_jmbagStudent CHAR(10);
	DECLARE t_ime, t_prezime VARCHAR(50);
	DECLARE t_ocjena INT;
	DECLARE dohvaceno INT;
	
	DECLARE kur CURSOR FOR 
	SELECT DISTINCT kolegiji.naziv,jmbagStudent,ime,prezime,ocjena FROM ocjene
	JOIN studenti ON studenti.jmbag = ocjene.jmbagStudent
	JOIN kolegiji ON kolegiji.id = ocjene.idKolegij
	WHERE ocjena = 1;
	
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET error = TRUE;
	
	DROP TEMPORARY TABLE IF EXISTS usmeni;
	CREATE TEMPORARY TABLE usmeni
	(
		opisUsmenog VARCHAR(255),
		jmbagStudent CHAR(10),
		imeStudenta VARCHAR(50),
		prezimeStudenta VARCHAR(50)
	);
	
	OPEN kur;
	
	petlja:LOOP
		FETCH kur INTO t_nazivKolegij, t_jmbagStudent, t_ime, t_prezime, t_ocjena;
		IF error = TRUE 
		 THEN LEAVE petlja; 
		END IF;
	
		IF (t_jmbagStudent IN (SELECT jmbagStudent FROM usmeni)) THEN
			UPDATE usmeni
			SET opisUsmenog = CONCAT(opisUsmenog,', ',t_nazivKolegij)
			WHERE jmbagStudent = t_jmbagStudent;
		ELSEIF (t_jmbagStudent NOT IN (SELECT jmbagStudent FROM usmeni)) THEN  --
			INSERT INTO usmeni(opisUsmenog,	jmbagStudent, imeStudenta, prezimeStudenta) 
			VALUES (CONCAT('Usmeni iz: ',t_nazivKolegij), t_jmbagStudent, t_ime, t_prezime);
		END IF;
	END LOOP petlja;
	
	CLOSE kur;	
        SELECT * FROM usmeni;
	END //
DELIMITER ;

UPDATE ocjene 
SET ocjena = 1, jmbagStudent = '0128050853'
WHERE jmbagStudent = '0010081356'; -- dadnemo Evi par jedinica iz nekoliko kolegija u svrhu testiranja 

CALL tkoMoraIciNaUsmeni();










