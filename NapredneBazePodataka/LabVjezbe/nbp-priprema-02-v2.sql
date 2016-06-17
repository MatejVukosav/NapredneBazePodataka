/* 1. U bazi autoradionica: 
Modificirati tablicu odjel tako da dodate novi atribut 
najmanjaPlaca tipa DOUBLE 

Napisati proceduru koja će:
• primiti šifru odjela
• za zadani odjel izračunati plaću radnika koji radi u zadanom
odjelu a ima najmanju plaću u tom odjelu
• u novostvoreni atribut najmanjaPlaca unijeti prethodno 
izračunat iznos
• plaću je potrebno izračunati kao umnožak iznosa osnovice i 
koeficijenta plaće
Napisati primjer poziva procedure*/

ALTER TABLE odjel ADD najmanjaPlaca DOUBLE;

DROP PROCEDURE IF EXISTS procNajmanja;
DELIMITER //
CREATE PROCEDURE procNajmanja(IN ulazSifOdjel INT)
	BEGIN
		DECLARE najmanja DOUBLE;
		
		SELECT MIN(KoefPlaca*IznosOsnovice) INTO najmanja
		FROM radnik WHERE sifOdjel = ulazSifOdjel;
		
		UPDATE odjel
		SET najmanjaPlaca = najmanja
		WHERE sifOdjel = ulazSifOdjel;
	END //
DELIMITER ;

CALL procNajmanja(2);



/* 2. U bazi studenti:
Napisati funkciju koja prima naziv smjera. 
Funkcija mora za sve kolegije sa zadanog smjera u 
atribut opis upisati tekst:
a. „Lagani kolegij“ – ako je prosjek ocjena na tom kolegiju 
veći od 3.5
b. „Težak kolegij“ – ako je prosjek ocjena na tom kolegiju 
manji ili jednak 3.5
c. Funkcija vraća broj kolegija kojima je upisala u opis 
„Težak kolegij“.
Zadatak je obavezno riješiti koristeći kursore.
Napisati primjer poziva funkcije */

DROP FUNCTION IF EXISTS func1;
DELIMITER //
CREATE FUNCTION func1(ulazNaziv VARCHAR(50)) RETURNS INT
DETERMINISTIC
	BEGIN
		DECLARE broj INT DEFAULT 0;
		DECLARE flag BOOL DEFAULT FALSE;
		DECLARE t_id INT DEFAULT 0;
		DECLARE prosjek DOUBLE;
		DECLARE kur CURSOR FOR
			SELECT kolegiji.id FROM kolegiji
			JOIN smjerovi ON kolegiji.idSmjer = smjerovi.id
			WHERE smjerovi.naziv = ulazNaziv;
		
		DECLARE CONTINUE HANDLER FOR NOT FOUND SET flag=TRUE;
		SET flag = FALSE;
		SET broj = 0;
		OPEN kur;
		
		petlja:LOOP
			FETCH kur INTO t_id;
			IF flag=TRUE THEN
				LEAVE petlja;
			END IF;	
			SELECT AVG(ocjena) INTO prosjek FROM ocjene
			JOIN kolegiji ON ocjene.idKolegij = kolegiji.id
			WHERE kolegiji.id = t_id;
			
			IF prosjek>3.5 THEN
				UPDATE kolegiji
				SET opis = "Lagani kolegij"
				WHERE id = t_id;
			ELSE
				UPDATE kolegiji
				SET opis = "Težak kolegij"
				WHERE id = t_id;
				SET broj = broj + 1;
			END IF;
			
		END LOOP;
		#close kur;
		
		RETURN broj;
	END //
DELIMITER ;

SELECT func1("smjer računarstvo");


/* 3. U bazi autoradionica: 
Napisati proceduru koja će koristeći proceduru iz prvog zadatka
popuniti u tablici odjel atribut najmanjaPlaca. 
Procedura prima podatak o županiji te popunjava atribut najmanjaPlaca
isključivo za odjele koji se odnose na radnika iz zadane županije.
Zadatak je obavezno riješiti koristeći kursore.
Ako za određeni odjel procedura ne uspije pronaći zapis (pogreška NOT FOUND),
potrebno je problem riješiti koristeći odgovarajući handler.
Procedura vraća broj dohvaćenih i broj obrađenih zapisa.
Napisati primjer poziva procedure */

DROP PROCEDURE IF EXISTS proc2;
DELIMITER //
CREATE PROCEDURE proc2(IN ulazZup INT, OUT dohv INT, OUT obra INT)
	BEGIN
		DECLARE flag BOOL DEFAULT FALSE;
		DECLARE t_sifOdjel INT;
		DECLARE kur CURSOR FOR
			SELECT radnik.sifOdjel FROM radnik
			JOIN mjesto ON radnik.pbrStan = mjesto.pbrMjesto
			WHERE mjesto.sifZupanija = ulazZup;
			
		DECLARE CONTINUE HANDLER FOR NOT FOUND SET flag=TRUE;
		SET dohv = 0;
		SET obra = 0;
		SET flag = FALSE;
		
		OPEN kur;
		SELECT FOUND_ROWS() INTO dohv;
		petlja: LOOP
			FETCH kur INTO t_sifOdjel;
			
			IF flag=TRUE THEN
				LEAVE petlja;
			END IF;
			
			CALL procNajmanja(t_sifOdjel);
			
			SET obra = obra+1;
			
		END LOOP;
		
		CLOSE kur;
	END //
DELIMITER ;

CALL proc2(10,@a,@b);
SELECT @a,@b;
	

/* 4. U bazi studenti: 
Napisati funkciju koja će primiti naziv smjera. Funkcija mora svim studentima
sa zadanog smjera postaviti datum upisa na 1.9.2014. 
Funkcija vraća broj obrađenih zapisa..
Zadatak je potrebno riješiti koristeći kursore i odgovarajuće handlere.
Napisati primjer poziva funkcije. */

DROP FUNCTION IF EXISTS func2;
DELIMITER //
CREATE FUNCTION func2(ulazNaziv VARCHAR(100)) RETURNS INT
DETERMINISTIC
	BEGIN
		DECLARE flag BOOL DEFAULT FALSE;
		DECLARE obra INT DEFAULT 0;
		DECLARE t_jmbag VARCHAR(20);
		DECLARE kur CURSOR FOR
			SELECT studenti.jmbag FROM studenti
			JOIN smjerovi ON studenti.idSmjer = smjerovi.id
			WHERE smjerovi.naziv = ulazNaziv;
		DECLARE CONTINUE HANDLER FOR NOT FOUND SET flag=TRUE;
		
		OPEN kur;
		petlja:LOOP
			FETCH kur INTO t_jmbag;
			IF flag=TRUE THEN
				LEAVE petlja;
			END IF;
			
			UPDATE studenti
			SET datumUpisa = '2014-09-01'
			WHERE jmbag = t_jmbag;
			
			SET obra = obra + 1;
		END LOOP;
		
		CLOSE kur;
		
		RETURN obra;
		
	END //
DELIMITER ;

SELECT func2("smjer računarstvo");

			
/* 5. U bazi studenti: 
Napisati proceduru koja će primiti naziv županije i broj N. 
Procedura mora za sva mjesta u zadanoj županiji ispisati:
a. Naziv mjesta
b. „Velik broj nastavnika“ – ako u tom mjestu stanuje više od N nastavnika
c. „Mali broj nastavnika“ – ako u tom mjestu stanuje N ili manje nastavnika
Napisati primjer poziva procedure. */

DROP PROCEDURE IF EXISTS proc3;
DELIMITER //
CREATE PROCEDURE proc3(IN ulazNazivZup VARCHAR(100), IN ulazN INT)
	BEGIN
		DECLARE t_mjesto VARCHAR(50); 
		DECLARE t_brojac INT;
		DECLARE flag BOOL DEFAULT FALSE;
		DECLARE kur CURSOR FOR
			SELECT mjesta.nazivMjesto, COUNT(nastavnici.jmbg) FROM nastavnici
			JOIN mjesta ON nastavnici.postBr = mjesta.postbr
			JOIN zupanije ON mjesta.idZupanija = zupanije.id
			WHERE zupanije.nazivZupanija = ulazNazivZup
			GROUP BY mjesta.nazivMjesto;
		DECLARE CONTINUE HANDLER FOR NOT FOUND SET flag=TRUE;
			
		DROP TEMPORARY TABLE IF EXISTS temp;
		CREATE TEMPORARY TABLE temp(
			tempNaziv VARCHAR(50),
			tempVelicina VARCHAR(50)
		);
			
		OPEN kur;
		petlja:LOOP
			FETCH kur INTO t_mjesto, t_brojac;
			IF flag=TRUE THEN
				LEAVE petlja;
			END IF;
			
			IF t_brojac > ulazN THEN
				INSERT INTO temp (tempNaziv, tempVelicina) VALUES(t_mjesto, "Velik br nast");
			ELSE
				INSERT INTO temp (tempNaziv, tempVelicina) VALUES(t_mjesto, "Mali br nast");
			END IF;
			
		END LOOP;
		
		CLOSE kur;
		SELECT * FROM temp;
		
	END //
DELIMITER ;

CALL proc3("Grad Zagreb", 41);


/* 6. U bazi autoradionica: 
Napisati proceduru za unos novog radnika u tablicu radnik.
Procedura preko parametra prima vrijednosti za sve atribute iz tablice radnik, 
osim atributa sifRadnik. Prilikom unosa novog radnika, potrebno je:
• radniku dodijeliti šifru (za jedan veća od najveće šifre radnika)
Procedura mora provjeriti da li se radniku dodjeljuje plaća manja od najmanje plaće radnika u
tom odjelu (koristiti proceduru iz prvog zadatka i pročitati podatak u novom atributu):
• ako plaća novog radnika nije manja od najmanje plaće za taj odjel, potvrditi sve
radnje (COMMIT)
• ako je plaća novog radnika manja od najmanje plaće za taj odjel, opovrgnuti sve
radnje (ROLLBACK)
Napisati primjer poziva procedure */

DROP PROCEDURE IF EXISTS proc4;
DELIMITER //
CREATE PROCEDURE proc4(IN ulazIme VARCHAR(50),
			IN ulazPrezime VARCHAR(50),
			IN ulazPbrStan INT,
			IN ulazSifOdjel INT,
			IN ulazKoefPlaca DOUBLE,
			IN ulazIznos DOUBLE)
	BEGIN
		DECLARE sifra INT;
		DECLARE najmanja DOUBLE;
		
		SET AUTOCOMMIT = 0;
		START TRANSACTION;
		
			SELECT MAX(sifRadnik)+1 INTO sifra FROM radnik;
			
			CALL procNajmanja(ulazSifOdjel);
			SELECT najmanjaPlaca INTO najmanja FROM odjel
			WHERE sifOdjel = ulazSifOdjel;
			
		
			INSERT INTO radnik
			VALUES (sifra, ulazIme,ulazPrezime,ulazPbrStan,
				ulazSifOdjel,ulazKoefPlaca,ulazIznos);
			
			IF ulazKoefPlaca*ulazIznos<najmanja THEN
				ROLLBACK;
			ELSE
				COMMIT;
			END IF;
		
		SET AUTOCOMMIT = 1;
	END //
DELIMITER ;

CALL proc4("Ivan", "Ivcevic", 44320, 2, 5, 1200);


/* 7. U bazi studenti:
Napisati funkciju za provjeru jačine unesene lozinke. Funkcija prima string
koji će predstavljati lozinku, te nakon toga provjeriti:
• ne smije se unositi string koji je kreći od 8 znakova
(samostalno definirati ponašanje funkcije)
• string se smije sastojati od brojki, malih i velikih slova,
ostalih znakova (samostalno definirati ponašanje funkcije)

Funkcija vraća poruku:
• SLABO - ako se string sastoji isključivo od slova ili isključivo od brojki
• SREDNJE - ako se string sastoji samo od slova i brojki
• JAKO - ako se string sastoji od kombinacija slova, brojki i posebnih znakova
Napisati primjer poziva funkcije. */

DROP FUNCTION IF EXISTS func3;
DELIMITER //
CREATE FUNCTION func3(ulazLozinka VARCHAR(30)) RETURNS VARCHAR(50)
	BEGIN
		DECLARE izlaz VARCHAR(50);
		
		IF LENGTH(ulazLozinka) < 8 THEN
			RETURN "Prekratka lozinka!";
		ELSEIF (ulazLozinka REGEXP '[^0-9a-zA-Z!#$%&/()=?]+') THEN
			RETURN "Pogrešna lozinka!";
		ELSEIF (ulazLozinka REGEXP '^[a-zA-Z]+$') OR 
			(ulazLozinka REGEXP '^[0-9]+$') THEN
			RETURN "SLABO";
		ELSEIF (ulazLozinka REGEXP '[0-9]+') AND
			(ulazLozinka REGEXP '[a-zA-Z]+') AND
			(ulazLozinka REGEXP '[!#$%&/()=?*]+') THEN
			RETURN "JAKO";
		ELSEIF (ulazLozinka REGEXP '[0-9]+') AND
			(ulazLozinka REGEXP '[a-zA-Z]+') THEN
			RETURN "SREDNJE";

		END IF;
	END //
DELIMITER ;
SELECT func3("1234567abc&");


/* 8. U bazi studenti:
U tablicu studenti dodati novi atribut lozinka (tip podataka procjeniti u
skladu s ostatkom zadatka).
Napisati proceduru koja će primiti studentov JMBAG i lozinku.
Koristeći funkciju iz prethodnog zadatka, provjeriti da li se unosi
lozinka čija je jačina definirana kao srednja ili jaka, te ako jest,
unijeti dotičnom studentu lozinku u bazu, ali zaštićenu sa MD5 algoritmom.
Ako je pak lozinka preslaba, onemogućiti njen upis u bazu i ispisati
odgovarajuću poruku.
Napisati primjer poziva procedure */

ALTER TABLE studenti ADD lozinka VARCHAR(50);

DROP PROCEDURE IF EXISTS proc5;
DELIMITER //
CREATE PROCEDURE proc5(IN ulazJmbag VARCHAR(50), IN ulazLozinka VARCHAR(50))
	BEGIN
		DECLARE jacina VARCHAR(50);
		SELECT func3(ulazLozinka) INTO jacina;
		
		IF jacina = "JAKO" THEN
			UPDATE studenti
			SET lozinka = MD5(ulazLozinka)
			WHERE ulazJmbag = jmbag;
		ELSE
			SELECT "POGREŠKA";
			
		END IF;
	END //
DELIMITER ;

CALL proc5("0013020125", "1234567891abc((");








