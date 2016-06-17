-- 1.  U bazi autoradionica:
-- Potrebno je stvoriti tablicu klijent_test sa atributima i definiranim 
-- tipovima podataka koje sadrži i tablica klijent.

CREATE TABLE klijent_test (
	sifKlijent INT(11),
	imeKlijent VARCHAR(255),
	prezimeKlijent VARCHAR(255),
	pbrKlijent INT(11),
	pbrReg INT(11),
	datUnosKlijent DATE,
	jmbgKlijent VARCHAR(50)
);

-- 2.  U bazi autoradionica:
-- Unijeti u tablicu klijenta sa imenom='Ivan' i prezimenom='Horvat.
-- Vrijednosti podataka za ostale atribute ne smiju biti uneseni.

INSERT INTO klijent_test (imeKlijent, prezimeKlijent)
VALUES('Ivan', 'Horvat');

-- 3.  U bazi autoradionica:
-- Potrebno je obrisati tablicu klijent_test (i sav njen sadržaj).

DROP TABLE klijent_test;

-- 4.  U bazi autoradionica:
-- Potrebno je promijeniti radnici s imenom="Sunčica" i 
-- prezimenom="Pleško" koeficijent plaće u vrijednost 2.0.

UPDATE radnik
SET KoefPlaca = 2.0
WHERE imeRadnik = "Sunčica"
AND prezimeRadnik = "Pleško";

-- 5.  U bazi autoradionica:
-- Potrebno je ispisati sva mjesta koja se nalaze u županiji 
-- sa šifrom 5, 8 ili 11.

SELECT * FROM mjesto
WHERE mjesto.sifZupanija IN (5, 8, 11);

-- 6.  U bazi autoradionica:
-- Ispisati sve klijente koji su rođeni u 
-- prvom tromjesečju 1986. godine.

SELECT * FROM klijent
WHERE (SUBSTR(jmbgKlijent, 3, 2) IN ("01","02","03"))
AND (SUBSTR(jmbgKlijent, 5, 3) = "986");

-- 7.  U bazi autoradionica:
-- Potrebno je ispisati sve klijente koji su 
-- rođeni na današnji datum.

SELECT * FROM klijent
WHERE MONTH(STR_TO_DATE(jmbgKlijent, "%d%m9%y")) = MONTH(CURDATE())
AND DAY(STR_TO_DATE(jmbgKlijent, "%d%m9%y")) = DAY(CURDATE());

-- 8.  U bazi studenti:
-- Potrebno je ispisati prosjek ocjena koje su dobivene 
-- polaganjem prošle godine.

SELECT AVG(ocjena) FROM ocjene
WHERE YEAR(datumPolaganja) = YEAR(CURDATE())-1;

-- 9.  U bazi studenti:
-- Potrebno je napisati SQL upit koji će svim smjerovima 
-- promijenit naziv u "informatika". 

UPDATE smjerovi
SET naziv = "informatika";

-- 10. U bazi studenti:
-- Potrebno je ispisati sve nastavnike čije je prvo slovo 
-- imena i zadnje slovo prezimena jednako.

SELECT * FROM nastavnici
WHERE LEFT(ime, 1) = RIGHT(prezime, 1);

-- 11. U bazi studenti:
-- Ispisati koliko ima studenata sa određenim prezimenom 
-- (za sva prezimena prebrojati studente).

SELECT prezime, COUNT(jmbag) FROM studenti
GROUP BY prezime;

-- 12. U bazi autoradionica:
-- Ispisati broj kvarova po odjelima. 
-- Uz broj naloga ispisati i nazivOdjela.

SELECT odjel.nazivOdjel, COUNT(kvar.sifKvar) FROM odjel
JOIN kvar ON odjel.sifOdjel = kvar.sifOdjel
GROUP BY odjel.nazivOdjel;

-- 13. U bazi autoradionica:
-- Ispisati sve radnike čiji koeficijent plaće jednak 
-- najvećem koeficijentu plaće svih radnika.

SELECT * FROM radnik
WHERE KoefPlaca =
(SELECT MAX(KoefPlaca) FROM radnik);

-- 14. U bazi autoradionica:
-- Ispisati sve radionice kojima je kapacitet radnika veći od 
-- minimalnog kapaciteta radnika uvećanog za 1.

SELECT * FROM radionica
WHERE kapacitetRadnika >
(SELECT MIN(kapacitetRadnika) FROM radionica) + 1;

-- 15. U bazi autoradionica:
-- Ispisati radionice na kojima se popravljao kvar klijenta iz 
-- Dubrovačkoneretvanske županije, a popravak je vršio radnik 
-- s prezimenom koje završava na „ić"

SELECT * FROM radionica
JOIN rezervacija ON radionica.oznRadionica = rezervacija.oznRadionica
JOIN kvar ON rezervacija.sifKvar = kvar.sifKvar
JOIN nalog ON kvar.sifKvar = nalog.sifKvar
JOIN klijent ON nalog.sifKlijent = klijent.sifKlijent
JOIN mjesto ON klijent.pbrKlijent = mjesto.pbrMjesto
JOIN zupanija ON mjesto.sifZupanija = zupanija.sifZupanija
JOIN radnik ON nalog.sifRadnik = radnik.sifRadnik
WHERE zupanija.nazivZupanija = "Dubrovačko-neretvanska"
AND RIGHT(radnik.prezimeRadnik, 2) = "ić";

-- 16. U bazi studenti:
-- Koristeći JOIN naredbu potrebno je ispisati sve studente koji 
-- stanuju i prebivaju u Šibensko-kninskoj županiji. 

SELECT * FROM studenti
JOIN mjesta ON studenti.postBrPrebivanje = mjesta.postbr
JOIN zupanije ON mjesta.idZupanija = zupanije.id
JOIN mjesta AS mjStan ON studenti.postBrStanovanja = mjStan.postbr
JOIN zupanije AS zupStan ON mjStan.idZupanija = zupStan.id
WHERE zupanije.nazivZupanija = "Šibensko-kninska županija"
AND zupStan.nazivZupanija = "Šibensko-kninska županija";

-- 17. U bazi autoradionica:
-- Potrebno je ispisati sve naloge na kojima su radili radnici
-- koji stanuju u županiji "Grad Zagreb", vezani su uz vozila 
-- klijenata koji žive u Splitsko-dalmatinskoj županiji, 
-- a automobil su registrirali u županiji "Grad Zagreb".

SELECT * FROM nalog
JOIN radnik ON nalog.sifRadnik = radnik.sifRadnik
JOIN klijent ON nalog.sifKlijent = klijent.sifKlijent
JOIN mjesto ON radnik.pbrStan = mjesto.pbrMjesto
JOIN zupanija ON mjesto.sifZupanija = zupanija.sifZupanija
JOIN mjesto AS mjKl ON klijent.pbrKlijent = mjKl.pbrMjesto
JOIN zupanija AS zupKl ON mjKl.sifZupanija = zupKl.sifZupanija
JOIN mjesto AS mjReg ON klijent.pbrReg = mjReg.pbrMjesto
JOIN zupanija AS zupReg ON mjReg.sifZupanija = zupanija.sifZupanija
WHERE zupanija.nazivZupanija = "Grad Zagreb"
AND zupReg.nazivZupanija = "Grad Zagreb"
AND zupKl.nazivZupanija = "Splitsko-dalmatinska";

-- 18. U bazi studenti: 
-- Potrebno je ispisati sva mjesta unutar Zadarske županije zajedno 
-- sa imenima i prezimenima studenata koji stanuju u istima.
-- Ako ne postoji student u određenom mjestu u županiji, 
-- potrebno je svejedno ispisati mjesto, a unutar kolona student 
-- ispisati NULL vrijednost.

SELECT * FROM zupanije
JOIN mjesta ON zupanije.id = mjesta.idZupanija
LEFT JOIN studenti ON mjesta.postbr = studenti.postBrStanovanja
WHERE zupanije.nazivZupanija = "Zadarska županija";

-- 19. U bazi autoradionica:
-- Ispisati sve odjele i kvarove koji su bili popravljani na istima, 
-- a ukoliko ne postoji ni jedan kvar koji je odjel popravljao 
-- potrebno je ispisati „null“ vrijednosti. 

SELECT * FROM odjel
LEFT JOIN kvar ON odjel.sifOdjel = kvar.sifOdjel;

-- 20. U bazi autoradionica:
-- Ispisati sva mjesta koja se nalaze unutar Varaždinske županije kao i 
-- klijente koji u njima žive. Ukoliko ne postoji klijent 
-- u određenom mjestu unutar županije, potrebno je svejedno ispisati 
-- mjesto, a unutar kolona klijenta „null“ vrijednosti. 

SELECT * FROM mjesto
JOIN zupanija ON mjesto.sifZupanija = zupanija.sifZupanija
LEFT JOIN klijent ON mjesto.pbrMjesto = klijent.pbrKlijent
WHERE zupanija.nazivZupanija = "Varaždinska";

-- 21. U bazi autoradionica:
-- Ispisati koliki je prosječni koeficijent plaće u svakom odjelu.
-- Potrebno je ispisati samo one odjele u kojima je taj prosjek veći 
-- od minimalnog koeficijenta plaće po svim radnicima uvećanog za 1.

SELECT AVG(KoefPlaca), odjel.nazivOdjel FROM odjel
JOIN radnik ON odjel.sifOdjel = radnik.sifOdjel
GROUP BY odjel.nazivOdjel
HAVING AVG(KoefPlaca) > MIN(radnik.KoefPlaca)+1;

-- 22. U bazi autoradionica:
-- Potrebno je ispisati sumu plaća radnika po mjestu.
-- Rezultate je potrebno ograničiti na prvih 5 n-torki.

SELECT SUM(KoefPlaca * IznosOsnovice), mjesto.nazivMjesto FROM radnik
JOIN mjesto ON radnik.pbrStan = mjesto.pbrMjesto
GROUP BY mjesto.nazivMjesto
LIMIT 0, 5;

-- 23. U bazi autoradionica:
-- Ispisati sumu sati kvara i broja radnika grupiranu po nazivu odjela. 
-- Potrebno je ispisati samo one n-torke koje čiji je broj sati kvara
-- veći od 1. Rezultate je potrebno sortirati po sumi broja radnika 
-- uzlazno. Rezultate je potrebno ograničiti na prvih 5 n-torki.

SELECT SUM(satiKvar), SUM(brojRadnika), nazivOdjel FROM odjel
JOIN kvar ON odjel.sifOdjel = kvar.sifOdjel
GROUP BY nazivOdjel
HAVING SUM(satiKvar) > 1
ORDER BY SUM(brojradnika) ASC
LIMIT 0, 5;

-- 24. U bazi studenti:
-- Potrebno je ispisati prosječne ocjene studenata po županiji 
-- stanovanja. Rezultate je potrebno sortirati po prosjeku 
-- silazno i ograničiti na prvih 10 n-torki. 

SELECT AVG(ocjena), nazivZupanija FROM ocjene
JOIN studenti ON ocjene.jmbagStudent = studenti.jmbag
JOIN mjesta ON studenti.postBrStanovanja = mjesta.postbr
JOIN zupanije ON mjesta.idZupanija = zupanije.id
GROUP BY nazivZupanija
ORDER BY AVG(ocjena) DESC
LIMIT 0, 10;

-- 25. U bazi autoradionica:
-- Ispisati sve radnike koji nisu radili ni na jednom nalogu.

SELECT * FROM radnik
WHERE radnik.sifRadnik NOT IN
(SELECT nalog.sifRadnik FROM nalog);

-- 26. U bazi autoradionica:
-- Ispisati podatke svih klijenata za koje je izvršen barem jedan 
-- nalog s prioritetom većim od prosječnog prioriteta

SELECT * FROM klijent
WHERE klijent.sifKlijent IN
(SELECT nalog.sifKlijent FROM nalog
WHERE prioritetNalog >
(SELECT AVG(prioritetNalog) FROM nalog));

-- 27. U bazi autoradionica:
-- Potrebno je svim radnicima iz županije “Grad Zagreb” promijeniti
-- ime u “Petar”.

UPDATE radnik
SET imeRadnik = "Petar"
WHERE radnik.pbrStan IN
(SELECT mjesto.pbrMjesto FROM mjesto
WHERE mjesto.sifZupanija IN
(SELECT zupanija.sifZupanija FROM zupanija
WHERE nazivZupanija = "Grad Zagreb"));

UPDATE radnik
SET imeRadnik = "Petar"
WHERE pbrStan IN 
(SELECT pbrMjesto FROM mjesto
JOIN zupanija ON mjesto.sifZupanija = zupanija.sifZupanija
WHERE nazivZupanija = "Grad Zagreb");


-- neki zadatak

SELECT * FROM nalog
JOIN radnik ON nalog.sifRadnik = radnik.sifRadnik
JOIN klijent ON nalog.sifKlijent = klijent.sifKlijent
JOIN mjesto ON radnik.pbrStan = mjesto.pbrMjesto
JOIN zupanija ON mjesto.sifZupanija = zupanija.sifZupanija
JOIN mjesto AS mjKlijent ON klijent.pbrKlijent = mjKlijent.pbrMjesto
JOIN zupanija AS zupKlijent ON mjKlijent.sifZupanija = zupKlijent.sifZupanija
JOIN mjesto AS mjReg ON klijent.pbrReg = mjReg.pbrMjesto
JOIN zupanija AS zupReg ON mjReg.sifZupanija = zupReg.sifZupanija
JOIN kvar ON nalog.sifKvar = kvar.sifKvar
JOIN odjel ON kvar.sifOdjel = odjel.sifOdjel
JOIN odjel AS odjelRadnik ON radnik.sifOdjel = odjelRadnik.sifOdjel
WHERE zupanija.nazivZupanija = "Grad Zagreb"
AND zupKlijent.nazivZupanija = "Splitsko-dalmatinska"
AND zupReg.nazivZupanija = "Grad Zagreb"
AND odjel.nazivOdjel = "Ravnanje"
AND odjelRadnik.nazivOdjel = "Alarmi";