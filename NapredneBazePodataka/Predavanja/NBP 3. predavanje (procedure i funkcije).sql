/*Napisati proceduru koja će ispisati sve podatke o svim radnicima. 
Gdje se nalazi upravo izrađena procedura?*/
DELIMITER //
CREATE PROCEDURE ispisiRadnike()
BEGIN
	SELECT * FROM radnik;
END; //      /* oznaka ";" prije oznake "//" u ovom retku, može se i ne mora navoditi.*/
DELIMITER ;
/*Pozvati / izvršiti proceduru iz prethodnog zadatka.*/
CALL ispisiRadnike();







/*Simulacija greške u proceduri: Napisati proceduru koja će ispisati sve podatke o svim klijentima. U tijelu procedure je krivo ime tablice.*/
DELIMITER //
CREATE PROCEDURE ispisiKlijente()
BEGIN
	SELECT * FROM klijenti;
END; //
DELIMITER ;


CALL ispisiKlijente();







/*Pregled i dohvat postojećih procedura: */
SHOW PROCEDURE STATUS LIKE 'ispisiRadnike';

SHOW CREATE PROCEDURE ispisiRadnike;

SELECT * FROM INFORMATION_SCHEMA.ROUTINES;

SELECT * FROM MYSQL.PROC;




/*Dohvatiti podatak o trenutnom danu u mjesecu i pohraniti ga u globalnu varijablu @dan.*/
SELECT @dan; /*provjerili smo je li varijabla prazna*/
SELECT DATE_FORMAT(CURDATE(), '%d') INTO @dan;
SELECT @dan;






/*Napisati proceduru koja će ispisati podatke o svim radnicima u zadanom odjelu. 
Odjel je potrebno zadati prema nazivu. */
DELIMITER //
CREATE PROCEDURE dohvatiRadnikePremaOdjelu (IN naziv VARCHAR(50))
	BEGIN
		SELECT * FROM radnik NATURAL JOIN odjel WHERE nazivOdjel=naziv;
	END //
DELIMITER ;


CALL dohvatiRadnikePremaOdjelu('Balansiranje guma');






/*Napisati proceduru koja će vratiti broj radnika u zadanom odjelu.*/
DELIMITER //
CREATE PROCEDURE prebrojiRadnikeUOdjelu(IN naziv VARCHAR(50), OUT broj INT)
BEGIN
SELECT COUNT(*) INTO broj FROM radnik NATURAL JOIN odjel WHERE nazivOdjel=naziv;
END //
DELIMITER ;

CALL prebrojiRadnikeUOdjelu ('Balansiranje guma',@n);
SELECT (@n);







/*Riješiti prethodni zadatak sa istom funkcionalnošću ali bez IN, OUT ni INOUT parametara.*/
DELIMITER //
CREATE PROCEDURE prebrojiRadnikeUOdjeluBezParametara()
BEGIN
SELECT COUNT(*) INTO @izlaz FROM radnik NATURAL JOIN odjel WHERE nazivOdjel=@ulaz;
END //
DELIMITER ;

SET @ulaz='Balansiranje guma';
CALL prebrojiRadnikeUOdjelu (@ulaz,@izlaz);
SELECT @izlaz;







/*Napisati proceduru koja prima naziv mjesta i vraća naziv županije u kojoj se to mjesto nalazi.*/
DELIMITER //
CREATE PROCEDURE dohvatiZupaniju (INOUT naziv VARCHAR(255))
		BEGIN
		SELECT nazivZupanija INTO naziv FROM mjesto 
			NATURAL JOIN zupanija WHERE nazivMjesto=naziv;
		END; //
DELIMITER ;

SET @k='Bjelovar';
CALL dohvatiZupaniju(@k);
SELECT @k;








/*Napisati proceduru za izračun površine kruga. Napisati poziv procedure.*/
DELIMITER //
CREATE PROCEDURE povrsina (IN r DOUBLE, OUT a DOUBLE)
BEGIN
SET a = r * r * PI();
END //
DELIMITER ;

CALL povrsina(22, @a);
SELECT @a;






/*Napisati proceduru koja vraća JMBG klijenta koji je posljednji unesen u bazu. (Pretpostaviti da je posljednji onaj s najvećom vrijednosti atributa sifKlijent.)*/
DROP PROCEDURE IF EXISTS zadnjiKlijent;
DELIMITER //
CREATE PROCEDURE zadnjiKlijent(OUT j1 VARCHAR(13))
BEGIN
DECLARE sif INT;
SELECT MAX(sifklijent) INTO sif FROM klijent;
SELECT klijent.jmbgKlijent INTO j1 FROM klijent 
		WHERE klijent.sifklijent=sif;
END; //
DELIMITER ;


/*poziv procedure*/
CALL zadnjiKlijent(@l);
SELECT @l;








/*Napisati  funkciju za izračun površine kruga.*/

DELIMITER //
DROP FUNCTION IF EXISTS povrsina //
CREATE FUNCTION povrsina(r DOUBLE) 
	RETURNS DOUBLE
	NO SQL
	BEGIN
			DECLARE a DOUBLE;
			SET a = r * r * PI();
			RETURN a;
	END;
//
DELIMITER ;



/*Poziv funkcije iz prethodnog zadatka: */
SELECT povrsina(2);








/*Provjera funkcije */
SHOW FUNCTION STATUS LIKE 'povrsina';
SHOW CREATE FUNCTION povrsina;
SELECT * FROM INFORMATION_SCHEMA.ROUTINES;
SELECT * FROM MYSQL.PROC;







/*Funkcija može osim u lokalne, također čitati iz i pisati u varijable definirane u sesiji (globalne) - isti primjer sa povrsinom kruga */

DELIMITER //
CREATE FUNCTION povrsinaVar() RETURNS INT
	  DETERMINISTIC
BEGIN
SET @pov= PI() * @radius * @radius;
RETURN NULL;
END//
DELIMITER ;




/*Poziv funkcije:*/
SET @radius=2;
SELECT povrsinaVar();
SELECT @pov;




/*Napisati funkciju koja će sve radnike iz zadanog odjela ‘promaknuti’ u viši odjel. 
Funkcija neka nakon uspješnog završetka vraća vrijednost 1.(Pretpostavka je da je viši odjel onaj koji ima za jedan veću vrijednost atributa sifOdjel.)*/
DROP FUNCTION promakni;
DELIMITER //
CREATE FUNCTION promakni(odj INT) RETURNS INT
DETERMINISTIC
BEGIN
UPDATE radnik SET sifodjel=sifodjel+1 
		WHERE sifodjel=odj;
RETURN 1;
END//
DELIMITER ;
SELECT promakni(2);









/*Napisati funkciju koja će za zadanog radnika ispisati koliko klijenata (kojem se vozilo popravljao taj radnik) 
živi u mjestu u kojem živi i taj radnik.*/
DROP FUNCTION IF EXISTS brojiKlijente;
DELIMITER //
CREATE FUNCTION brojiKlijente(zadaniRadnik INT) RETURNS INT
DETERMINISTIC
BEGIN
DECLARE br INT DEFAULT NULL;
SELECT COUNT(sifKlijent) INTO br 
	FROM mjesto JOIN klijent ON pbrKlijent=pbrMjesto
	NATURAL JOIN nalog
	NATURAL JOIN radnik 
	WHERE pbrklijent=pbrstan 
		AND radnik.sifradnik=zadaniRadnik;
RETURN br;
END//
DELIMITER ;

SELECT brojiKlijente(277);








/*Modificirati tablicu radnik tako da dodate novi atribut najvecaPlaca odgovarajuceg tipa. 
Napisati proceduru koja će:  
-> primiti šifru radnika 
-> za tog radnika pronaći županiju stanovanja 
-> u novostvoreni atribut najvecaPlaca unijeti koliki je najveći iznos plaće koju ima bilo koji radnik iz dohvaćene županije (županije stanovanja unesenog radnika). 
Iznos plaće potrebno je računati kao umnožak vrijednosti atributa koefPlace i iznosOsnovice*/
ALTER TABLE radnik ADD najvecaPlaca INT(11);
DELIMITER %%
DROP PROCEDURE IF EXISTS upisiMaksPlacu %%
CREATE PROCEDURE upisiMaksPlacu (IN rad INT)
BEGIN
	DECLARE z INT DEFAULT NULL;
	DECLARE p DECIMAL(6,2) DEFAULT NULL;
	SELECT sifZupanija INTO z FROM radnik JOIN mjesto ON pbrStan=pbrMjesto WHERE sifRadnik=rad;
	SELECT MAX(`KoefPlaca`*`IznosOsnovice`) INTO p FROM radnik JOIN mjesto ON pbrStan=pbrMjesto WHERE sifZupanija=z;
	UPDATE radnik SET najvecaPlaca=p  WHERE sifRadnik=rad; 
END;
%%
DELIMITER ;



/*Poziv PROCEDURE:*/
CALL upisiMaksPlacu(297);
Provjera rezultata:
SELECT * FROM radnik WHERE sifRadnik=297;




