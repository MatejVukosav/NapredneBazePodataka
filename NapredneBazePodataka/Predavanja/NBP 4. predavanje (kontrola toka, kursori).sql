/*Napisati funkciju koja će dohvatiti trenutni datum s poslužitelja 
i ispisati koji je dan u tjednu.*/

SELECT CURDATE();
SELECT DAYOFWEEK(CURDATE());


DELIMITER //
DROP FUNCTION danUTjednu //
CREATE FUNCTION danUTjednu() RETURNS VARCHAR(50)
DETERMINISTIC
BEGIN
	DECLARE vrati VARCHAR(50);
	CASE DAYOFWEEK(CURDATE())
		WHEN 2 THEN SET vrati='Danas je ponedjeljak';
		WHEN 3 THEN SET vrati='Danas je utorak';
		WHEN 4 THEN SET vrati='Danas je srijeda';
		WHEN 5 THEN SET vrati='Danas je četvrtak';
		WHEN 6 THEN SET vrati='Danas je petak';
		ELSE SET vrati='Danas je vikend';	
	  END CASE;
	RETURN vrati;
END; //
DELIMITER ;

SELECT danUTjednu();







/*Napisati proceduru koja će ispisati prvih n prirodnih brojeva 
u jednoj varijabli. 
Brojevi moraju biti razdvojeni zarezom. 
Zanemarite ako se zarez ispisuje i nakon zadnjeg broja.


*/
DELIMITER $$
DROP PROCEDURE IF EXISTS WhileLoopProc_zarez$$
CREATE PROCEDURE WhileLoopProc_zarez (IN n INT)
      BEGIN
              DECLARE var INT DEFAULT NULL;
              DECLARE str VARCHAR(255) DEFAULT NULL;
              SET var=1;
              SET str='';
              WHILE var<=n DO
                          SET str=CONCAT(str,var,',');
                          SET var=var + 1; 
              END WHILE;
              SELECT str;
      END $$
DELIMITER ;
CALL WhileLoopProc_zarez(8);






/*Nadogradnja na prethodni zadatak.
Obratite pažnju da se zarez NE ispisuje i nakon zadnjeg broja.
*/
DELIMITER $$
DROP PROCEDURE IF EXISTS WhileLoopProc_provjera$$
CREATE PROCEDURE WhileLoopProc_provjera (IN n INT)
      BEGIN
              DECLARE var INT DEFAULT NULL;
              DECLARE str VARCHAR(255) DEFAULT NULL;
              SET var=1;
              SET str='';
              WHILE var<=n DO
			IF var<n THEN
                          SET str=CONCAT(str,var,',');
                        ELSEIF var=n THEN
                          SET str=CONCAT(str,var);
                        END IF;                        
                          SET var=var + 1; 
              END WHILE;
              SELECT str;
      END $$
DELIMITER ;
CALL WhileLoopProc_provjera(8);








/*Nadogradnja na prethodni zadatak.
Korištenje funkcije CONCAT_WS.
*/

DELIMITER $$
DROP PROCEDURE IF EXISTS WhileLoopProc$$
CREATE PROCEDURE WhileLoopProc(IN n INT)
      BEGIN
              DECLARE var INT DEFAULT NULL;
              DECLARE str VARCHAR(255) DEFAULT NULL;
              SET str='1';
              SET var=2;
              WHILE var<=n DO
                          SET str=CONCAT_WS(',',str,var);
                          SET var=var + 1; 
              END WHILE;
              SELECT str;
      END $$
DELIMITER ;
CALL WhileLoopProc(8);



/*Napisati proceduru koja za zadani odjel broji radnike koji 
pripadaju tom odjelu. 
Ako odjel ima više od 10 radnika, procedura mora vratiti -1, 
a ako odjel nema radnika, procedura mora vratiti 0. 
U ostalim slučajevima, procedura vraća stvarni broj radnika. 
Napisati poziv procedure za odjel 100005. 
Napisati poziv procedure za odjel 5.
*/




DELIMITER //
CREATE PROCEDURE odjel_rad(IN zadaniOdjel INT, OUT broj INT)
BEGIN
	SELECT COUNT(*) INTO broj FROM radnik WHERE sifOdjel=zadaniOdjel; 
	IF broj>10 THEN
		SET broj=-1;
	
	END IF;
END;
//
DELIMITER ;

CALL odjel_rad(100005,@a);
SELECT @a;

CALL odjel_rad(5,@a);
SELECT @a;








/*Napisati funkciju za unos novog odjela u tablicu odjel 
(atributi sifra i naziv odjela). 
Funkcija treba provjeriti postoji li već odjel sa zadanim imenom. 
Ako postoji, završiti s radom (vrati 0). 
Ako ne postoji, pridijeliti mu šifru i unijeti u tablicu (vrati 1). 
(Primijetiti da na šifri odjela ne postoji autoincrement.)
*/
DELIMITER //
CREATE FUNCTION unesiOdjel(noviOdjel VARCHAR(50)) RETURNS INT
DETERMINISTIC
BEGIN
	DECLARE broj, vrati, zadnji INT DEFAULT NULL;
	SELECT COUNT(*) INTO broj FROM odjel WHERE nazivOdjel=noviOdjel; 
	IF broj=0 THEN
		SELECT MAX(sifOdjel) INTO zadnji FROM odjel;
		INSERT INTO odjel (sifOdjel, nazivOdjel) 
			VALUES ((zadnji+1),noviOdjel);
		SET vrati=1;
	ELSE 
		SET vrati=0;
	END IF;
	RETURN vrati;
END;
//
DELIMITER ;
SELECT unesiOdjel('Odjel za lakiranje');
SELECT * FROM odjel;








/*Napisati proceduru koja će dohvatiti svaki kvar zasebno 
i uz njegovo ime ispisati radi li se o velikom ili malom kvaru. 
Kriterij je iznos atributa satiKvar. 
Kvar se smatra velikim ako je satiKvar veći od 3.*/

DELIMITER $$
DROP PROCEDURE IF EXISTS etiketiraj$$
CREATE PROCEDURE etiketiraj()
      BEGIN
	      DECLARE trenutni_naziv VARCHAR(255);
	      DECLARE trenutni_sati, trenutni_id INT;
	      DECLARE kur CURSOR FOR SELECT sifKvar, nazivKvar, satiKvar FROM kvar;
	      OPEN kur;
	      petlja:LOOP
		FETCH kur INTO trenutni_id, trenutni_naziv, trenutni_sati;
		IF trenutni_sati>3 
			THEN SELECT trenutni_naziv AS ime, trenutni_id AS sifra,  
				'veliki' AS velicina;
		ELSE 
			SELECT trenutni_naziv AS ime, trenutni_id AS sifra, 'mali' AS velicina;
		END IF;
	      END LOOP petlja;
	      CLOSE kur;
	      SELECT 'kraj'; /*naredba dodana za provjeru izvođenja procedure*/
	END; $$
DELIMITER ;
CALL etiketiraj();






/*Dorada prethodnog zadatka na način da se izbjegne dobivanje pogreške pri zadnjem fetchu. 
Vrtimo petlju točno određeni broj puta.
*/
DELIMITER $$
DROP PROCEDURE IF EXISTS etiketiraj_1$$
CREATE PROCEDURE etiketiraj_1()
      BEGIN
      DECLARE trenutni_naziv VARCHAR(255) DEFAULT NULL;
      DECLARE trenutni_sati, trenutni_id, dohvaceno INT DEFAULT NULL;
      DECLARE i INT DEFAULT 0;
      DECLARE kur CURSOR FOR SELECT sifKvar, nazivKvar, satiKvar FROM kvar;
      OPEN kur;
      SELECT FOUND_ROWS() INTO dohvaceno;
	WHILE i<dohvaceno DO 
		FETCH kur INTO trenutni_id, trenutni_naziv, trenutni_sati;
		IF trenutni_sati>3 
			THEN SELECT trenutni_naziv AS ime, 'veliki' AS velicina;
		ELSE 
			SELECT trenutni_naziv AS ime, trenutni_id AS sifra, 'mali' AS velicina;
		END IF;
		SET i=i+1;
      END WHILE;
      CLOSE kur;
      SELECT 'kraj'; /*naredba dodana za provjeru izvođenja procedure*/
END; $$
DELIMITER ;
CALL etiketiraj_1();







/*Dorada prethodnog zadatka na način da dobijemo samo jedan set rezultata.*/
DELIMITER $$
DROP PROCEDURE IF EXISTS etiketiraj_2$$
CREATE PROCEDURE etiketiraj_2()
      BEGIN
      DECLARE trenutni_naziv VARCHAR(255) DEFAULT NULL;
      DECLARE trenutni_sati, trenutni_id, dohvaceno INT DEFAULT NULL;
      DECLARE i INT DEFAULT 0;
      DECLARE kur CURSOR FOR SELECT sifKvar, nazivKvar, satiKvar FROM kvar;
	DROP TEMPORARY TABLE IF EXISTS tmp;
	CREATE TEMPORARY TABLE tmp(naziv VARCHAR(50), id INT(11), etiketa VARCHAR(10));

      OPEN kur;
      SELECT FOUND_ROWS() INTO dohvaceno;
	WHILE i<dohvaceno DO 
		FETCH kur INTO trenutni_id, trenutni_naziv, trenutni_sati;
		IF trenutni_sati>3 
			/*THEN SELECT trenutni_naziv AS ime, 'veliki' AS velicina;*/
			THEN INSERT INTO tmp (naziv, id, etiketa) 
				VALUES (trenutni_naziv, trenutni_id, 'veliki');
		ELSE 
			/*SELECT trenutni_naziv AS ime, trenutni_id AS sifra, 'mali' AS velicina;*/
			 INSERT INTO tmp (naziv, id, etiketa)  
				VALUES (trenutni_naziv, trenutni_id, 'mali');
		END IF;
		SET i=i+1;
      END WHILE;
      CLOSE kur;
      SELECT 'kraj'; /*naredba dodana za provjeru izvođenja procedure*/
      SELECT * FROM tmp;
END; $$
DELIMITER ;
CALL etiketiraj_2();







/*Napisati proceduru koja će svim radnicima koji imaju koeficijent plaće manji od 1.00 povisiti ga ZA 1.00. 
Ostalim radnicima čiji je koeficijent plaće veći od 2.00 smanjiti ga ZA 0.50. 
Procedura mora vratiti broj n-torki koje je obradila, broj radnika kojima je plaća uvećana te broj radnika kojima je plaća smanjena.
*/
DROP PROCEDURE IF EXISTS korigiraj_koef;
DELIMITER //
CREATE PROCEDURE korigiraj_koef()
BEGIN
	DECLARE koef DECIMAL(3,2);
	DECLARE sif, dohvaceno, smanjena, povecana INT;
	DECLARE i INT DEFAULT 0;
	DECLARE kursor CURSOR FOR SELECT sifRadnik, koefPlaca FROM radnik;
	
	SET smanjena=0;
	SET povecana=0;

	OPEN kursor;
	SELECT FOUND_ROWS() INTO dohvaceno;
	
	WHILE i<dohvaceno DO 
	
		FETCH kursor INTO sif, koef;
		
		IF  koef<1.00 THEN
			SET koef=koef+1;
			UPDATE radnik SET koefPlaca=koef WHERE sifRadnik=sif;
			SET povecana=povecana+1;
		ELSEIF koef>=2.00 THEN
			SET koef=koef-0.5;
			UPDATE radnik SET koefPlaca=koef WHERE sifRadnik=sif;
			SET smanjena=smanjena+1;
			END IF;
		SET i=i+1;
	END WHILE;
	CLOSE kursor;
	SELECT dohvaceno AS dohvaceno_rezultata, 
		smanjena AS smanjena_placa, povecana AS povecana_placa;
END; //
DELIMITER ;


SELECT * FROM radnik WHERE koefPlaca<1;
SELECT * FROM radnik WHERE koefPlaca>=2;
CALL korigiraj_koef();

SELECT * FROM radnik WHERE koefPlaca>=2;



