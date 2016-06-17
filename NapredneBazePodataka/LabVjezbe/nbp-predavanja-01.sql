/* Napisati funkciju koja će dohvatiti trenutni datum s poslužitelja 
i ispisati koji je dan u tjednu. */

DROP FUNCTION IF EXISTS danUTjednu;
DELIMITER //
CREATE FUNCTION danUTjednu() RETURNS VARCHAR(50) 
DETERMINISTIC	
	BEGIN
		DECLARE izlaz VARCHAR(50);
		
		CASE DAYOFWEEK(CURDATE())
			WHEN 2 THEN SET izlaz = "pon";
			WHEN 3 THEN SET izlaz = "uto";
			WHEN 4 THEN SET izlaz = "sri";
			WHEN 5 THEN SET izlaz = "cet";
			WHEN 6 THEN SET izlaz = "pet";
			ELSE SET izlaz = "vikend";
		END CASE;
		RETURN izlaz;
	END //
DELIMITER ;
SELECT danUTjednu();


/* WHILE */

DROP PROCEDURE IF EXISTS proc;
DELIMITER //
CREATE PROCEDURE proc()
	BEGIN
		DECLARE var INT;
		SET var = 1;
		WHILE var<=5 DO
			SET var=var+1;
			SELECT var;
		END WHILE;
	END //
DELIMITER ;
CALL proc();


/* REPEAT */

DROP PROCEDURE IF EXISTS proc;
DELIMITER //
CREATE PROCEDURE proc()
	BEGIN
		DECLARE var INT;
		SET var = 1;
		REPEAT
			SET var=var+1;
			SELECT var;
		UNTIL var>5
		END REPEAT;
	END //
DELIMITER ;
CALL proc();


/* LOOP */

DROP PROCEDURE IF EXISTS proc;
DELIMITER //
CREATE PROCEDURE proc()
	BEGIN
		DECLARE var INT;
		SET var = 1;
		petlja:LOOP
			SET var=var+1;
			SELECT var;
			IF var>5 THEN
				LEAVE petlja;
			END IF;		
		END LOOP;
		
	END //
DELIMITER ;
CALL proc();


/* Napisati proceduru koja će ispisati prvih n prirodnih brojeva 
u jednoj varijabli. Brojevi moraju biti razdvojeni zarezom.
(Zanemarite ako se zarez ispisuje i nakon zadnjeg broja.) */

DROP PROCEDURE IF EXISTS proc;
DELIMITER //
CREATE PROCEDURE proc(IN ulaz INT)
	BEGIN
		DECLARE var INT;
		DECLARE izlaz VARCHAR(50);
		SET var = 1;
		SET izlaz = "";
		
		petlja:LOOP
			IF(var>ulaz) THEN
				LEAVE petlja;
			END IF;
			
			IF(var = ulaz) THEN
				SET izlaz = CONCAT(izlaz, var);
			
			ELSE SET izlaz = CONCAT(izlaz, var, ",");
			END IF;
			
			SET var = var+1;
		END LOOP;
		SELECT izlaz;
	END //
DELIMITER ;
CALL proc(10);


/* Napisati proceduru koja za zadani odjel broji radnike koji 
pripadaju tom odjelu. Ako odjel ima više od 10 radnika,
procedura mora vratiti -1, a ako odjel nema radnika, 
procedura mora vratiti 0. U ostalim slučajevima, procedura 
vraća stvarni broj radnika. 
Napisati poziv procedure za odjel 100005. 
Napisati poziv procedure za odjel 5. */

DROP PROCEDURE IF EXISTS proc;
DELIMITER //
CREATE PROCEDURE proc(IN odj INT, OUT vrati INT)
	BEGIN
		DECLARE brojRad INT;
		
		SELECT COUNT(*) INTO brojRad
		FROM radnik WHERE sifOdjel = odj;
		
		IF brojRad>10 THEN
			SET vrati=-1;
		ELSEIF brojRad=0 THEN
			SET vrati=0;
		ELSE SET vrati=brojRad;
		END IF;
	END //
DELIMITER ;
SET @var = 0;
CALL proc(5, @var);
SELECT @var;


/* Napisati funkciju za unos novog odjela u tablicu odjel.
Funkcija treba provjeriti postoji li već odjel sa zadanim imenom.
Ako postoji, završiti s radom (vrati 0). Ako ne postoji, 
pridijeliti mu šifru i unijeti u tablicu (vrati 1).
(Primijetiti da na šifri odjela ne postoji autoincrement.) */

DROP FUNCTION IF EXISTS func;
DELIMITER //
CREATE FUNCTION func(imeUlaz VARCHAR(50)) RETURNS INT
DETERMINISTIC
	BEGIN
		DECLARE var INT;
		DECLARE sifNovi INT;
		SELECT COUNT(*) INTO var FROM odjel
		WHERE nazivOdjel = imeUlaz;
		
		IF var>0 THEN
			RETURN 0;
		ELSE
			SELECT MAX(sifOdjel)+1 INTO sifNovi
			FROM odjel;

			INSERT INTO odjel (sifOdjel, nazivOdjel)
			VALUES(sifNovi, imeUlaz);
			
			RETURN 1;
		END IF;
	END //
DELIMITER ;

SELECT func("Odjel za reklamacije");
SELECT * FROM odjel;


/* Napisati proceduru koja će dohvatiti svaki kvar zasebno i uz 
njegovo ime ispisati radi li se o velikom ili malom kvaru.
Kriterij je iznos atributa satiKvar. Kvar se smatra velikim
ako je satiKvar veći od 3. (BEZ POMOCNE TABLICE, BEZ NOT FOUND) */

DROP PROCEDURE IF EXISTS proc;
DELIMITER //
CREATE PROCEDURE proc()
	BEGIN
		DECLARE t_sif INT DEFAULT NULL;
		DECLARE t_naziv VARCHAR(255) DEFAULT NULL;
		DECLARE t_sati INT DEFAULT NULL;
		DECLARE dohvaceno INT;
		DECLARE i INT DEFAULT 0;
		DECLARE kur CURSOR FOR
			SELECT sifKvar, nazivKvar, satiKvar
			FROM kvar;
		OPEN kur;
		SELECT FOUND_ROWS() INTO dohvaceno;
		
		WHILE i<dohvaceno DO
			FETCH kur INTO t_sif, t_naziv, t_sati;
			IF t_sati > 3 THEN
				SELECT t_naziv, 'veliki';
			ELSE
				SELECT t_naziv, 'mali';
			END IF;
			SET i = i+1;
		END WHILE;
		CLOSE kur;
	END //
DELIMITER ;
CALL proc();


/* Napisati proceduru koja će dohvatiti svaki kvar zasebno i uz 
njegovo ime ispisati radi li se o velikom ili malom kvaru.
Kriterij je iznos atributa satiKvar. Kvar se smatra velikim
ako je satiKvar veći od 3. (S POMOCNOM TABLICOM) */

DROP PROCEDURE IF EXISTS proc;
DELIMITER //
CREATE PROCEDURE proc()
	BEGIN
		DECLARE t_sif, t_sati, dohvaceno INT DEFAULT NULL;
		DECLARE t_naziv VARCHAR(255) DEFAULT NULL;
		DECLARE i INT DEFAULT 0;
		
		DECLARE kur CURSOR FOR
			SELECT sifKvar, nazivKvar, satiKvar
			FROM kvar;
		
		DROP TEMPORARY TABLE IF EXISTS temp;
		CREATE TEMPORARY TABLE temp(
			temp_sif INT(11),
			temp_naziv VARCHAR(255),
			temp_velicina VARCHAR(50)
		);
		OPEN kur;
		SELECT FOUND_ROWS() INTO dohvaceno;
			
		WHILE i<dohvaceno DO
			FETCH kur INTO t_sif, t_naziv, t_sati;
			
			IF t_sati>3 THEN
				INSERT INTO temp
				(temp_sif, temp_naziv, temp_velicina)
				VALUES (t_sif, t_naziv, 'veliki');
			ELSE
				INSERT INTO temp
				(temp_sif, temp_naziv, temp_velicina)
				VALUES (t_sif, t_naziv, 'mali');
			
			END IF;
			
			SET i = i+1;
		END WHILE;
		CLOSE kur;
		SELECT * FROM temp;
	END //
DELIMITER ;
CALL proc();


/* Napisati proceduru koja će svim radnicima koji imaju 
koeficijent plaće manji od 1.00 povisiti ga ZA 1.00.
Ostalim radnicima čiji je koeficijent plaće veći od 2.00 
smanjiti ga ZA 0.50. Procedura mora vratiti broj n-torki 
koje je obradila, broj radnika kojima je plaća uvećana te 
broj radnika kojima je plaća smanjena. */

DROP PROCEDURE IF EXISTS proc;
DELIMITER //
CREATE PROCEDURE proc()
	BEGIN
		DECLARE t_sif, dohvaceno, brPovecanih, brSmanjenih INT;
		DECLARE flag BOOL;
		DECLARE t_koef DECIMAL(3,2);
		DECLARE kur CURSOR FOR
			SELECT sifRadnik, KoefPlaca FROM radnik;
		DECLARE CONTINUE HANDLER FOR NOT FOUND SET flag=TRUE;
		SET flag=FALSE;
		SET brPovecanih=0;
		SET brSmanjenih=0;
		
		OPEN kur;
		SELECT FOUND_ROWS() INTO dohvaceno;
		petlja: LOOP
			FETCH kur INTO t_sif, t_koef;
			IF flag=TRUE THEN
				LEAVE petlja;
			END IF;
			
			IF t_koef<1.00 THEN
				UPDATE radnik
				SET KoefPlaca = KoefPlaca+1.00
				WHERE sifRadnik = t_sif;
				SET brPovecanih = brPovecanih+1;
			ELSEIF t_koef>2.00 THEN
				UPDATE radnik
				SET KoefPlaca = KoefPlaca-0.50
				WHERE sifRadnik = t_sif;
				SET brSmanjenih = brSmanjenih+1;
			END IF;
			
		END LOOP;
		CLOSE kur;
		SELECT dohvaceno AS dohvacenoRez, 
			brPovecanih AS povecanih, 
			brSmanjenih AS smanjenih;
	END //
DELIMITER ;
CALL proc();




