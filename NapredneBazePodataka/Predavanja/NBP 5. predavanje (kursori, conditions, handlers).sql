/*Dohvat podataka iz nepostojeće tablice. Obratiti pažnju na ispis poruke o pogrešci. */
SELECT * FROM nepostojeca_tablica;











/*Definirati handler za slučaj dupliciranog unosa podataka za 
atribut koji je definiran kao primary key.*/
/*Prvo je stvorena tablica 'test' za potrebe testiranja.*/

CREATE TABLE `test` (
  `t` INT(11) NOT NULL,
  PRIMARY KEY (`t`)
) ENGINE=MYISAM DEFAULT CHARSET=utf8;

DELIMITER //
DROP PROCEDURE IF EXISTS handlerdemo //
CREATE PROCEDURE handlerdemo()
BEGIN
DECLARE CONTINUE HANDLER FOR SQLSTATE '23000' 
	SET @x=1;
SET @x=1;
INSERT INTO test VALUES(1);
SET @x=2;
INSERT INTO test VALUES(1);
SET @x=3;
END;
//
DELIMITER ;

CALL handlerdemo();
SELECT @x;


INSERT INTO test VALUES(1);
INSERT INTO studenti.test VALUES(1);



/* Napisati proceduru koja će za zadani poštanski broj pronaći sve nazive mjesta u županiji 
u kojoj se nalazi zadano mjesto. Neka procedura ispiše nazive tih mjesta na ekran. */
DELIMITER //
DROP PROCEDURE IF EXISTS pbr //
CREATE PROCEDURE pbr(ulaz INT)
BEGIN
	DECLARE p_zup INT;
	DECLARE naziv VARCHAR(50);
	DECLARE error INT DEFAULT 0;
	DECLARE kursor CURSOR FOR SELECT nazivMjesto 
		FROM mjesto WHERE mjesto.sifZupanija=p_zup;
	DECLARE CONTINUE HANDLER FOR NOT FOUND 
		SET error=1;		
	SELECT sifzupanija INTO p_zup FROM mjesto 
		WHERE mjesto.pbrmjesto=ulaz;
	OPEN kursor;
	petlja: LOOP
		FETCH kursor INTO naziv;
		IF error=1 THEN
			LEAVE petlja;
		END IF;
		SELECT naziv;
	END LOOP;
	CLOSE kursor;
END;
//
DELIMITER ;

CALL pbr(43280);



/*Dorada prethodnog zadatka na način da se izbjegne n setova rezultata - rješenje pomoću konkatenacije vrijednosti u niz.*/
DELIMITER //
DROP PROCEDURE IF EXISTS pbr //
CREATE PROCEDURE pbr(ulaz INT)
BEGIN
	DECLARE p_zup INT DEFAULT NULL;
	DECLARE naziv VARCHAR(50) DEFAULT NULL;
	DECLARE popis BLOB DEFAULT '';
	DECLARE error INT DEFAULT 0;
	DECLARE kursor CURSOR FOR SELECT nazivMjesto 
		FROM mjesto WHERE mjesto.sifZupanija=p_zup;
	DECLARE CONTINUE HANDLER FOR NOT FOUND 
		SET error=1;
	DROP TEMPORARY TABLE IF EXISTS bbzup;
	CREATE TEMPORARY TABLE bbzup(mjesto VARCHAR(50));
	SELECT sifzupanija INTO p_zup FROM mjesto 
		WHERE mjesto.pbrmjesto=ulaz;
	OPEN kursor;
	petlja: LOOP
		FETCH kursor INTO naziv;
		IF error=1 THEN
			LEAVE petlja;
		END IF; 
		SET popis = CONCAT(popis, "; ", naziv);
	END LOOP;
	SELECT popis;
	CLOSE kursor;
	END; //
DELIMITER ;
CALL pbr(43280);



/*Dorada prethodnog zadatka na način da se izbjegne n setova rezultata - rješenje pomoću privremene tablice.*/

DELIMITER //
DROP PROCEDURE IF EXISTS pbr //
CREATE PROCEDURE pbr(ulaz INT)
BEGIN
	DECLARE p_zup INT;
	DECLARE naziv VARCHAR(50);
	DECLARE error INT DEFAULT 0;
	DECLARE kursor CURSOR FOR SELECT nazivMjesto 
		FROM mjesto WHERE mjesto.sifZupanija=p_zup;
	DECLARE CONTINUE HANDLER FOR NOT FOUND 
		SET error=1;
	DROP TEMPORARY TABLE IF EXISTS bbzup;
	CREATE TEMPORARY TABLE bbzup(mjesto VARCHAR(50));
	SELECT sifzupanija INTO p_zup FROM mjesto 
		WHERE mjesto.pbrmjesto=ulaz;
	OPEN kursor;
	petlja: LOOP
		FETCH kursor INTO naziv;
		IF error=1 THEN
			LEAVE petlja;
		END IF; 
		INSERT INTO bbzup VALUES(naziv);
	END LOOP;
	SELECT * FROM bbzup;
	CLOSE kursor;
	END; //
DELIMITER ;
CALL pbr(43280);


/* Možemo li isto rješenje realizirati izradom funkcije? (Pazi: funkcija ne može ispisati sadržaj privremene tablice) */

DROP FUNCTION IF EXISTS pbr_func;
DELIMITER //
CREATE FUNCTION pbr_func(ulaz INT) RETURNS INT DETERMINISTIC
BEGIN
	DECLARE p_zup INT;
	DECLARE naziv VARCHAR(50);
	DECLARE error INT DEFAULT 0;
	DECLARE kursor CURSOR FOR SELECT nazivMjesto
		FROM mjesto WHERE mjesto.sifZupanija=p_zup;
	DECLARE CONTINUE HANDLER FOR NOT FOUND
		SET error=1;
		DROP TEMPORARY TABLE IF EXISTS bbzup;
	CREATE TEMPORARY TABLE bbzup(mjesto VARCHAR(50));
	SELECT sifzupanija INTO p_zup FROM mjesto WHERE mjesto.pbrmjesto=ulaz;
	OPEN kursor;
	petlja: LOOP
	FETCH kursor INTO naziv;
	IF error=1 THEN
		LEAVE petlja;
	END IF;
	INSERT INTO bbzup VALUES(naziv);
	END LOOP;
	CLOSE kursor; 
	RETURN 1; 
END; // 
DELIMITER ;

SELECT pbr(43280); /*poziv funkcije*/

SELECT * FROM bbzup; /*ispis rezultata ‘ručno’ izvan funkcije*/









/* Napisati proceduru koja će svim radnicima koji imaju koeficijent 
plaće manji od 1.00 povisiti ga ZA 1.00. 
Ostalim radnicima čiji je koeficijent plaće veći od 2.00 smanjiti ga ZA 0.50. 
Procedura mora vratiti broj n-torki koje je obradila, 
broj radnika kojima je plaća uvećana te broj radnika kojima je plaća smanjena.*/


DROP PROCEDURE IF EXISTS korigiraj_koef;
DELIMITER //
CREATE PROCEDURE korigiraj_koef()
BEGIN
	DECLARE koef DECIMAL(3,2);
	DECLARE sif, dohvaceno, smanjena, povecana INT;
	DECLARE flag BOOL DEFAULT FALSE;
	DECLARE kursor CURSOR FOR SELECT sifRadnik, koefPlaca FROM radnik;
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET flag=TRUE;
	SET smanjena=0;
	SET povecana=0;

	OPEN kursor;
	SELECT FOUND_ROWS() INTO dohvaceno;
	petlja:LOOP
		FETCH kursor INTO sif, koef;
		IF flag=TRUE THEN
			LEAVE petlja;
		END IF;
		IF  koef<1.00 THEN
			UPDATE radnik SET koefPlaca=koefPlaca+1 WHERE sifRadnik=sif;
			SET povecana=povecana+1;
		ELSEIF koef>=2.00 THEN
			SET koef=koef-0.5;
			UPDATE radnik SET koefPlaca=koef WHERE sifRadnik=sif;
			SET smanjena=smanjena+1;
			END IF;
	END LOOP;
	CLOSE kursor;
	SELECT dohvaceno AS dohvaceno_rezultata, 
		smanjena AS smanjena_placa, povecana AS povecana_placa;
END; //
DELIMITER ;
CALL korigiraj_koef();

SELECT CURDATE();
SELECT FOUND_ROWS();


/* Napisati proceduru koja će primiti šifre dvaju radnika (rOduzmiID i rDodajID) te iznos. 
Prvom radniku je potrebno smanjiti iznosOsnovice za zadani iznos, a drugom ga uvećati. 
Potrebno je provjeriti da li prvi radnik ima iznosOsnovice veći od zadanog iznosa. 
Također, ne smije se dogoditi da je prvom iznos oduzet, a drugome nije dodan.
*/

DROP PROCEDURE IF EXISTS obaviTransakciju ;
DELIMITER &&
CREATE PROCEDURE obaviTransakciju 
	(IN rOduzmiID INT, 
	IN rDodajID INT, 
	IN iznos DOUBLE, 
	OUT poruka VARCHAR(50))
BEGIN
	DECLARE r1trenutnoStanje DOUBLE(10,2) DEFAULT 0;
	BEGIN
		DECLARE EXIT HANDLER FOR NOT FOUND
			SET poruka='Radnik nije pronađen pod zadanim brojem!';
		DECLARE EXIT HANDLER FOR SQLEXCEPTION
		BEGIN
			ROLLBACK;
			SET poruka='Greska!';
		END;
	SET autocommit=0;
	START TRANSACTION;
		SELECT iznosOsnovice INTO r1trenutnoStanje
			FROM radnik WHERE sifRadnik=rOduzmiID;
		/*'ako ima dovoljno', obavi transakciju*/
		IF r1trenutnoStanje>iznos THEN 
			UPDATE radnik SET iznosOsnovice=iznosOsnovice-iznos
				WHERE sifRadnik=rOduzmiID;
			UPDATE radnik SET iznosOsnovice=iznosOsnovice+iznos
				WHERE sifRadnik=rDodajID;
		ELSE
			SET poruka='Radnik nema dovoljan iznos osnovice!';
		END IF;
	END;
	IF poruka != '' THEN ROLLBACK;
		ELSE COMMIT;
		SET poruka='SUCCESS! Transakcija je uspješno obavljena!';
	END IF;
	SELECT poruka;
  SET autocommit=1;
END &&
DELIMITER ;

CALL obaviTransakciju(518,514,1000,@a);
CALL obaviTransakciju(518,514,5000,@a);


/* 19.	Napisati funkciju koja za ulazni parametar prima ulaznu varijablu pbr tipa integer. 
Funkcija nad tablicom radnik umanjuje vrijednost atributa KoefPlaca za 1 za sve 
zapise kod kojih je pbrStan jednak ulaznoj varijabli (pbr). 
Funkcija vraća broj 1. Zadatak je potrebno riješiti pomoću kursora.
*/
DELIMITER // 
DROP FUNCTION IF EXISTS smanjiKoef //
CREATE FUNCTION smanjiKoef(pbr INT) RETURNS INT 
DETERMINISTIC 
BEGIN 
	DECLARE sif INT DEFAULT NULL; 
	DECLARE koef DECIMAL(6,2) DEFAULT NULL;
	DECLARE kraj INT DEFAULT 0; 
	DECLARE kursor CURSOR FOR 
		SELECT koefPlaca, sifRadnik FROM radnik 
		WHERE pbrStan=pbr; 
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET kraj=1; 
	OPEN kursor; 
	petlja:LOOP FETCH kursor INTO koef, sif; 
		IF kraj=1 THEN LEAVE petlja; 
		END IF; 
		SET koef=koef-1;
		UPDATE radnik SET koefPlaca=koef WHERE sifRadnik=sif; 
	END LOOP; 
	CLOSE kursor; 
	RETURN 1; 
END; // 
DELIMITER ; 

SELECT smanjiKoef(21000);


/*20.	Napisati proceduru koja će sve radnike promaknuti u viši odjel (odjel veći za 1 od trenutnog odjela).  
Procedura vraća broj promaknutih radnika. Obavezno je koristiti kursore.*/
DELIMITER //
DROP PROCEDURE IF EXISTS promakni1 //
CREATE PROCEDURE promakni1() 
	BEGIN	
		DECLARE n INT DEFAULT 0;
		DECLARE kraj BOOL DEFAULT FALSE;
		DECLARE sif, odj INT DEFAULT NULL;
		DECLARE kursor CURSOR FOR 
			SELECT sifradnik, sifOdjel FROM radnik; 
		DECLARE CONTINUE HANDLER FOR NOT FOUND SET kraj=TRUE;
		
		OPEN kursor;
		vrti:LOOP
			FETCH kursor INTO sif, odj;
			IF kraj=TRUE THEN LEAVE vrti;
			END IF;
			UPDATE radnik SET sifOdjel=odj+1 
				WHERE radnik.sifradnik=sif;
			SET n =n +1;
		END LOOP;
		CLOSE kursor;
		SELECT n ;
	END;
	//
DELIMITER ;

CALL promakni1();


/*21.	Modificirati proceduru iz prethodnog zadatka na način da promakne samo one 
radnike koji su iz zadanog mjesta (procedura prima naziv mjesta).*/
DELIMITER //
DROP PROCEDURE IF EXISTS promakni2 //
CREATE PROCEDURE promakni2(IN zadanoMjesto VARCHAR(50)) 
	BEGIN	
		DECLARE n INT DEFAULT 0;
		DECLARE kraj BOOL DEFAULT FALSE;
		DECLARE sif, odj INT DEFAULT NULL;
		DECLARE kursor CURSOR FOR 
			SELECT sifradnik, sifOdjel 
				FROM radnik JOIN mjesto ON pbrStan=pbrMjesto 
				WHERE nazivMjesto=zadanoMjesto; 
		DECLARE CONTINUE HANDLER FOR NOT FOUND SET kraj=TRUE;
		
		OPEN kursor;
		vrti:LOOP
			FETCH kursor INTO sif, odj;
			IF kraj=TRUE THEN LEAVE vrti;
			END IF;
			UPDATE radnik SET sifOdjel=odj+1 
				WHERE radnik.sifradnik=sif;
			SET n=n+1;
		END LOOP;
		CLOSE kursor;
		SELECT n ;
	END;
	//
DELIMITER ;

CALL promakni2('zagreb');


/*22.	Modificirati proceduru iz prethodnog zadatka na način da ako se radnik promiče u 
nepostojeći odjel (šifra odjela veća od maksimalne moguće), 
onda je potrebno opozvati promaknuće (rollback) a inače potvrditi promaknuće(commit).
*/

DELIMITER //
DROP PROCEDURE IF EXISTS promakni3 //
CREATE PROCEDURE promakni3(IN zadanoMjesto VARCHAR(50)) 
	BEGIN	
		DECLARE n, maxOdjel INT DEFAULT 0;
		DECLARE kraj BOOL DEFAULT FALSE;
		DECLARE sif, odj INT DEFAULT NULL;
		DECLARE kursor CURSOR FOR 
			SELECT sifradnik, sifOdjel FROM radnik 
				JOIN mjesto ON pbrStan=pbrMjesto 
				WHERE nazivMjesto=zadanoMjesto; 
		DECLARE CONTINUE HANDLER FOR NOT FOUND SET kraj=TRUE;
		SELECT MAX(sifOdjel) INTO maxOdjel FROM odjel;
		OPEN kursor;
		vrti:LOOP
			FETCH kursor INTO sif, odj;
			IF kraj=TRUE THEN LEAVE vrti;
			END IF;
			SET autocommit=0;
			START TRANSACTION;
				SET odj=odj+1;
				UPDATE radnik SET sifOdjel=odj 
					WHERE radnik.sifradnik=sif;
				IF odj>maxOdjel THEN ROLLBACK;
					ELSE COMMIT;SET n=n+1;
				END IF; /*Možemo li sličnu funkcionalnost postići bez otvaranja transakcije? Ponuditi rješenje.*/
			SET autocommit=0;
		END LOOP;
		CLOSE kursor;
		SELECT n ;
	END;
	//
DELIMITER ;
CALL promakni3('dubrovnik');
/*
->  na početku (odnosno nakon deklaracija varijabli i kursora), 
potrebno je pronaći kolika je najveća šifra odjela SELECT MAX(sifOdjel) INTO maxOdjel FROM odjel;
-> kursor funkcionira identično kao u prethodnom zadatku - dohvaća šifre radnika i odjela, 
ali samo iz zadanog mjesta
- > unutar klasične petlje koja se koristi kod kursora, 
nakon dohvata podataka sa naredbom FETCH i provjerom je li podatak dohvaćen, 
započinje se transakcija: SET autocommit=0; START TRANSACTION;
-> u transakciji se izvršava promicanje TRENUTNOG radnika UPDATE radnik SET sifOdjel=odj WHERE radnik.sifradnik=sif;, 
ali se ne potvrđuje (COMMIT) ako se radnik promiče u nepostojeći odjel - IF odj>maxOdjel već se tada izvršava ROLLBACK
*/





/*23.	Nadograditi proceduru iz prethodnog zadatka tako da vraća podatke o 
promaknutim radnicima (šifru radnika) te odjel kojem radnik nakon promaknuća pripada.*/
DELIMITER //
DROP PROCEDURE IF EXISTS promakni4 //
CREATE PROCEDURE promakni4(IN zadanoMjesto VARCHAR(50)) 
	BEGIN	
		DECLARE n, maxOdjel INT DEFAULT 0;
		DECLARE kraj BOOL DEFAULT FALSE;
		DECLARE sif, odj INT DEFAULT NULL;
		DECLARE kursor CURSOR FOR 
			SELECT sifradnik, sifOdjel FROM radnik 
JOIN mjesto ON pbrStan=pbrMjesto 
WHERE nazivMjesto=zadanoMjesto; 
		DECLARE CONTINUE HANDLER FOR NOT FOUND SET kraj=TRUE;
		DROP TEMPORARY TABLE IF EXISTS tmpRadnik;
		CREATE TEMPORARY TABLE 
			tmpRadnik(sifRad INT, noviOdjel INT);
		SELECT MAX(sifOdjel) INTO maxOdjel FROM odjel;
		OPEN kursor;
		vrti:LOOP
			FETCH kursor INTO sif, odj;
			IF kraj=TRUE THEN LEAVE vrti;
			END IF;
			SET autocommit=0;
			START TRANSACTION;
				SET odj=odj+1;
				UPDATE radnik SET sifOdjel=odj 
					WHERE radnik.sifradnik=sif;
				INSERT INTO tmpRadnik VALUES(sif,odj);
				IF (odj>maxOdjel) THEN ROLLBACK;
					ELSE COMMIT; SET n=n+1;
				END IF;
			SET autocommit=0;
		END LOOP;
		CLOSE kursor;
		SELECT * FROM tmpRadnik ;
	END;
	//
DELIMITER ;
CALL promakni4('dubrovnik');


/*24.	Tablici radnik dodati novi atribut brNaloga inicijalno postavljen na -1. 
Napisati proceduru koja će u novostvoreni atribut upisati koliko je naloga radnik obradio. 
Potrebno je obraditi sve radnike.
*/
ALTER TABLE radnik ADD brNaloga INT DEFAULT -1;
DROP PROCEDURE IF EXISTS brojiNaloge1;
DELIMITER //
CREATE PROCEDURE brojiNaloge1() 
BEGIN
	DECLARE kraj BOOL DEFAULT FALSE;
	DECLARE sifra, n INT DEFAULT NULL;
	DECLARE dohvaceno, obradeno INT DEFAULT 0;
	DECLARE k CURSOR FOR SELECT sifRadnik FROM radnik;
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET kraj=TRUE;
	
	OPEN k;
	SELECT FOUND_ROWS() INTO dohvaceno;
	vrti:LOOP
		FETCH k INTO sifra;
		IF kraj=TRUE THEN LEAVE vrti;
		END IF;
		SELECT COUNT(*) INTO n FROM nalog NATURAL JOIN radnik 
			WHERE sifRadnik=sifra;
		UPDATE radnik SET brNaloga=n WHERE sifRadnik=sifra;
		SET obradeno=obradeno+1;
	END LOOP;
	CLOSE k;
	SELECT obradeno AS obradeno_zapisa;
END
//
DELIMITER ;
CALL brojiNaloge1();



/*25.	Modificirati proceduru iz prethodnog zadatka da obradi samo 
one radnike koji su radili na zadanom kvaru 
(ulazni parametar u proceduru neka bude naziv kvara).
*/
DROP PROCEDURE IF EXISTS brojiNaloge2;
DELIMITER //
CREATE PROCEDURE brojiNaloge2(IN kv VARCHAR(50)) 
BEGIN
	DECLARE kraj BOOL DEFAULT FALSE;
	DECLARE sifra, n INT DEFAULT NULL;
	DECLARE dohvaceno, obradeno INT DEFAULT 0;
	DECLARE k CURSOR FOR 
		SELECT radnik.sifRadnik FROM radnik 
		JOIN nalog ON radnik.sifRadnik=nalog.sifRadnik 
		JOIN kvar ON nalog.sifKvar=kvar.sifKvar WHERE nazivKvar=kv;
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET kraj=TRUE;
	
	OPEN k;
	SELECT FOUND_ROWS() INTO dohvaceno;
	vrti:LOOP
		FETCH k INTO sifra;
		IF kraj=TRUE THEN LEAVE vrti;
		END IF;
		SELECT COUNT(*) INTO n FROM nalog NATURAL JOIN radnik 
			WHERE sifRadnik=sifra;
		UPDATE radnik SET brNaloga=n WHERE sifRadnik=sifra;
		SET obradeno=obradeno+1;
	END LOOP;
	CLOSE k;
	SELECT dohvaceno,obradeno;
END
//
DELIMITER ;
CALL brojiNaloge2('Zamjena blatobrana');



/*26.	Modificirati proceduru iz prethodnog zadatka na način da se upiše 
vrijednost brNaloga samo ako je veća od 10.
*/
DROP PROCEDURE IF EXISTS brojiNaloge3;
DELIMITER //
CREATE PROCEDURE brojiNaloge3(IN kv VARCHAR(50)) 
BEGIN
	DECLARE kraj BOOL DEFAULT FALSE;
	DECLARE sifra, n INT DEFAULT NULL;
	DECLARE k CURSOR FOR SELECT radnik.sifRadnik FROM radnik 
		JOIN nalog ON radnik.sifRadnik=nalog.sifRadnik 
		JOIN kvar ON nalog.sifKvar=kvar.sifKvar WHERE nazivKvar=kv;
DECLARE CONTINUE HANDLER FOR NOT FOUND SET kraj=TRUE;
	
	OPEN k;
	vrti:LOOP
		FETCH k INTO sifra;
		IF kraj=TRUE THEN LEAVE vrti;
		END IF;
		SET autocommit=0;
		START TRANSACTION;
			SELECT COUNT(*) INTO n FROM nalog NATURAL JOIN radnik 
			WHERE sifRadnik=sifra;
			UPDATE radnik SET brNaloga=n WHERE sifRadnik=sifra;
			IF n<10 THEN ROLLBACK;
				ELSE COMMIT;
			END IF;
			SET autocommit=0;
		END LOOP;
	CLOSE k;
END
//
DELIMITER ;

CALL brojiNaloge3('Zamjena blatobrana');



/*27.	Modificirati proceduru iz prethodnog zadatka na način da se ispisuju i podaci 
o radnicima kojima je promijenjena vrijednost atributa brNaloga. 
Neka se ispišu atributi sifRadnik i brNaloga.
*/
UPDATE radnik SET brNaloga=-1;
DROP PROCEDURE IF EXISTS brojiNaloge4;
DELIMITER //
CREATE PROCEDURE brojiNaloge4(IN kv VARCHAR(50)) 
BEGIN
	DECLARE kraj BOOL DEFAULT FALSE;
	DECLARE sifra, n INT DEFAULT NULL;
	DECLARE dohvaceno, obradeno INT DEFAULT 0;
	DECLARE k CURSOR FOR 
		SELECT radnik.sifRadnik FROM radnik 
		JOIN nalog ON radnik.sifRadnik=nalog.sifRadnik 
		JOIN kvar ON nalog.sifKvar=kvar.sifKvar WHERE nazivKvar=kv;
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET kraj=TRUE;
	DROP TEMPORARY TABLE IF EXISTS tmpRadnik;
	CREATE TEMPORARY TABLE tmpRadnik (sRad INT, brNal INT);
	OPEN k;
	SELECT FOUND_ROWS() INTO dohvaceno;
	vrti:LOOP
		FETCH k INTO sifra;
		IF kraj=TRUE THEN LEAVE vrti;
		END IF;
		SET autocommit=0;
		START TRANSACTION;
			SELECT COUNT(*) INTO n FROM nalog NATURAL JOIN radnik
				WHERE sifRadnik=sifra;
			UPDATE radnik SET brNaloga=n WHERE sifRadnik=sifra;
			INSERT INTO tmpRadnik  VALUES(sifra,n);
			IF n<10 THEN ROLLBACK;
				ELSE COMMIT;
			END IF;
		SET autocommit=0;
	END LOOP;
	CLOSE k;
	
	SELECT * FROM tmpRadnik ;
END
//
DELIMITER ;
CALL brojiNaloge4('Zamjena blatobrana');

