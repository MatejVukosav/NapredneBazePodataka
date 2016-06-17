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
CREATE PROCEDURE procNajmanja(IN ulazSif INT)
	BEGIN
		DECLARE sifraRad INT;
		DECLARE najmanja DOUBLE;
		SELECT MIN(KoefPlaca*IznosOsnovice) INTO
		najmanja FROM radnik
		WHERE sifOdjel = ulazSif;
		
		UPDATE odjel
		SET najmanjaPlaca = najmanja
		WHERE sifOdjel = ulazSif;	
	END //
DELIMITER ;
CALL procNajmanja(1);

SELECT * FROM odjel;
SELECT MIN(KoefPlaca*IznosOsnovice) FROM radnik
WHERE sifOdjel = 1;


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

DROP FUNCTION IF EXISTS funcTezina;
DELIMITER //
CREATE FUNCTION funcTezina(ulazNaziv VARCHAR(255)) RETURNS INT
DETERMINISTIC
	BEGIN
		DECLARE brTeskih, i INT DEFAULT 0;
		DECLARE t_id INT;
		DECLARE dohvaceno INT DEFAULT 0;
		DECLARE prosjek DOUBLE;
		
		DECLARE kur CURSOR FOR
			SELECT kolegiji.id FROM kolegiji
			JOIN smjerovi ON kolegiji.idSmjer = smjerovi.id
			WHERE smjerovi.naziv = ulazNaziv;
		SET i=0;
		SET brTeskih=0;
		
		OPEN kur;
		SELECT FOUND_ROWS() INTO dohvaceno;
		
		WHILE i<dohvaceno DO
			FETCH kur INTO t_id;
			
			SELECT AVG(ocjena) INTO prosjek FROM ocjene
			JOIN kolegiji ON ocjene.idKolegij = kolegiji.id
			WHERE kolegiji.id = t_id;
		
			IF prosjek>3.5 THEN
				UPDATE kolegiji
				SET opis = "Lagani kolegij"
				WHERE kolegiji.id = t_id;
			ELSE
				UPDATE kolegiji
				SET opis = "Težak kolegij"
				WHERE kolegiji.id = t_id;
				SET brTeskih = brTeskih+1;
			END IF;
		
			SET i = i+1;
		END WHILE;
		CLOSE kur;
	
		RETURN brTeskih;
	END //
DELIMITER ;
SELECT funcTezina("smjer računarstvo");


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

DROP PROCEDURE IF EXISTS procZup;
DELIMITER //
CREATE PROCEDURE procZup(IN ulazSifZup INT, OUT izlazDohv INT, OUT izlazObra INT)
	BEGIN
		DECLARE t_sifOdjel INT;
		DECLARE flag BOOL;
		DECLARE kur CURSOR FOR 
		SELECT DISTINCT sifOdjel FROM radnik
			JOIN mjesto ON radnik.pbrStan = mjesto.pbrMjesto
			NATURAL JOIN zupanija
			WHERE zupanija.sifZupanija = ulazSifZup;
		
		DECLARE CONTINUE HANDLER FOR NOT FOUND SET flag=TRUE;
		SET flag=FALSE;
		SET izlazDohv = 0;
		SET izlazObra = 0;
		
		OPEN kur;
		SELECT FOUND_ROWS() INTO izlazDohv;
		petlja:LOOP
			FETCH kur INTO t_sifOdjel;
			IF flag=TRUE THEN
				LEAVE petlja;
			END IF;
			
			CALL procNajmanja(t_sifOdjel);
			
			IF flag=TRUE THEN
				SET flag=FALSE;
			ELSE
				SET izlazObra = izlazObra+1;
			END IF;	
		END LOOP;
		CLOSE kur;
	END //
DELIMITER ;

CALL procZup(6, @a, @b);
SELECT @a, @b;



/* 4. U bazi studenti: 
Napisati funkciju koja će primiti naziv smjera. Funkcija mora svim studentima
sa zadanog smjera postaviti datum upisa na 1.9.2014. 
Funkcija vraća broj obrađenih zapisa..
Zadatak je potrebno riješiti koristeći kursore i odgovarajuće handlere.
Napisati primjer poziva funkcije. */

DROP FUNCTION IF EXISTS func;
DELIMITER //
CREATE FUNCTION func(ulazNaziv VARCHAR(255)) RETURNS INT
DETERMINISTIC
	BEGIN
		DECLARE t_jmbag VARCHAR(50);
		DECLARE flag BOOL DEFAULT FALSE;
		DECLARE brObr INT DEFAULT 0;
		
		DECLARE kur CURSOR FOR
			SELECT jmbag FROM studenti
			JOIN smjerovi ON studenti.idSmjer = smjerovi.id
			WHERE smjerovi.naziv = ulazNaziv;
		DECLARE CONTINUE HANDLER FOR NOT FOUND SET flag=TRUE;
		SET flag = FALSE;
		SET brObr = 0;
		OPEN kur;
		
		petlja:LOOP
			FETCH kur INTO t_jmbag;
			IF flag=TRUE THEN
				LEAVE petlja;
			END IF;
			
			UPDATE studenti
			SET datumUpisa = '2014-09-01'
			WHERE jmbag = t_jmbag;
			
			SET brObr=brObr+1;
		
		END LOOP;
		CLOSE kur;
		
		RETURN brObr;
	END //
DELIMITER ;

SELECT func("smjer računarstvo");

SELECT prezime, idSmjer, datumUpisa FROM studenti
INNER JOIN smjerovi ON studenti.idSmjer = smjerovi.id
WHERE smjerovi.naziv="smjer računarstvo";
	

/* 5. U bazi studenti: 
Napisati proceduru koja će primiti naziv županije i broj N. 
Procedura mora za sva mjesta u zadanoj županiji ispisati:
a. Naziv mjesta
b. „Velik broj nastavnika“ – ako u tom mjestu stanuje više od N nastavnika
c. „Mali broj nastavnika“ – ako u tom mjestu stanuje N ili manje nastavnika
Napisati primjer poziva procedure. */

DROP PROCEDURE IF EXISTS proc;
DELIMITER //
CREATE PROCEDURE proc(IN ulazNaziv VARCHAR(50), IN brojN INT)
	BEGIN
		DECLARE flag BOOL DEFAULT FALSE;
		DECLARE t_broj INT;
		DECLARE t_mjesto VARCHAR(50);
		DECLARE brojac INT DEFAULT 0;
		
		DECLARE kur CURSOR FOR
			SELECT COUNT(jmbg), mjesta.nazivMjesto FROM nastavnici
			JOIN mjesta ON nastavnici.postbr = mjesta.postbr
			JOIN zupanije ON mjesta.idZupanija = zupanije.id
			WHERE zupanije.nazivZupanija = ulazNaziv
			GROUP BY mjesta.nazivMjesto;
		DECLARE CONTINUE HANDLER FOR NOT FOUND SET flag=TRUE;
		DROP TEMPORARY TABLE IF EXISTS temp;
		CREATE TEMPORARY TABLE temp(
			tempMjesto VARCHAR(50),
			tempOpis VARCHAR(50)
		);
		
		OPEN kur;
		petlja:LOOP
			FETCH kur INTO t_broj, t_mjesto;

			IF flag=TRUE THEN
				leave petlja;
			end if;
	
			if t_broj>brojN then
				insert into temp (tempMjesto, tempOpis)
				values(t_mjesto, 'Velik broj nastavnika');
			else
				INSERT INTO temp (tempMjesto, tempOpis)
				VALUES(t_mjesto, 'Mali broj nastavnika');
			
			end if;
			
		end loop;
		close kur;
		select * from temp;
	end //
delimiter ;
call proc("Grad Zagreb", 1);


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

drop procedure if exists proc;
delimiter //
create procedure proc(
		in ulazIme varchar(50),
		in ulazPrez varchar(50),
		in ulazPbr int,
		in ulazSifOdjel int,
		in ulazKoef double,
		in ulazOsnovica double)
	begin
		declare sifra int default 0;
		declare najmanja double;
		
		set AUTOCOMMIT = 0;
		START TRANSACTION;
		
			select max(sifRadnik)+1 into sifra from radnik;
			
			call procNajmanja(ulazSifOdjel);
			
			select najmanjaPlaca into najmanja from odjel
			where sifOdjel = ulazSifOdjel;
			
			insert into radnik values
			(sifra, ulazIme, ulazPrez, ulazPbr, 
			ulazSifOdjel, ulazKoef, ulazOsnovica);
			
			if ulazKoef*ulazOsnovica < najmanja then
				rollback;
			else
				commit;
			end if;
		set AUTOCOMMIT = 1;
	end //
delimiter ;
CALL proc("Ivan", "Ivcevic", 44320, 2, 3, 1200);


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

drop function if exists func;
delimiter //
create function func(ulazLozinka varchar(30)) returns varchar(50)
	begin
		declare izlaz varchar(50);
		
		if length(ulazLozinka) < 8 then
			return "Prekratka lozinka!";
		elseif (ulazLozinka regexp '[^0-9a-zA-Z!#$%&/()=?]+') then
			return "Pogrešna lozinka!";
		elseif (ulazLozinka regexp '^[a-zA-Z]+$') OR 
			(ulazLozinka regexp '^[0-9]+$') then
			return "SLABO";
		ELSEIF (ulazLozinka REGEXP '[0-9]+') AND
			(ulazLozinka REGEXP '[a-zA-Z]+') AND
			(ulazLozinka REGEXP '[!#$%&/()=?*]+') THEN
			RETURN "JAKO";
		elseif (ulazLozinka regexp '[0-9]+') AND
			(ulazLozinka regexp '[a-zA-Z]+') then
			RETURN "SREDNJE";

		end if;
	end //
delimiter ;
select func("1234567abc&");


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

alter table studenti add lozinka varchar(30);

drop procedure if exists proc;
delimiter //
create procedure proc()
	begin
		
	end //
delimiter ;
call proc();










