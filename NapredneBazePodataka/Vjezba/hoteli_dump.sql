/*
SQLyog Community v8.3 
MySQL - 5.2.3-falcon-alpha-community-nt : Database - hoteli
*********************************************************************
*/

/*!40101 SET NAMES utf8 */;

/*!40101 SET SQL_MODE=''*/;

/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;
CREATE DATABASE /*!32312 IF NOT EXISTS*/`hoteli` /*!40100 DEFAULT CHARACTER SET latin1 */;

USE `hoteli`;

/*Table structure for table `drzava` */

DROP TABLE IF EXISTS `drzava`;

CREATE TABLE `drzava` (
  `ID` int(10) NOT NULL,
  `naziv` varchar(50) DEFAULT NULL,
  `pozivniBroj` varchar(3) DEFAULT NULL,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

/*Data for the table `drzava` */

insert  into `drzava`(`ID`,`naziv`,`pozivniBroj`) values (1,'Hrvatska','385'),(2,'Srbija','386'),(3,'Bosna i Hercegovina','387'),(4,'Slovenija','384'),(5,'Austrija','389'),(6,'Njemacka','360'),(7,'Nizozemska','342'),(8,'Rumunjska','353'),(9,'Bugarska','352'),(10,'Grcka','300'),(11,'Madarska','381'),(12,'Crna Gora','375'),(13,'Švicarska','322'),(14,'Francuska','120'),(15,'Engleska','111');

/*Table structure for table `gost` */

DROP TABLE IF EXISTS `gost`;

CREATE TABLE `gost` (
  `ID` int(10) NOT NULL,
  `ime` varchar(100) DEFAULT NULL,
  `prezime` varchar(150) DEFAULT NULL,
  `brojPutovnice` varchar(20) DEFAULT NULL,
  `pbrMjesto` int(10) DEFAULT NULL,
  PRIMARY KEY (`ID`),
  KEY `gost_mjesto` (`pbrMjesto`),
  CONSTRAINT `gost_mjesto` FOREIGN KEY (`pbrMjesto`) REFERENCES `mjesto` (`pbrMjesto`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

/*Data for the table `gost` */

insert  into `gost`(`ID`,`ime`,`prezime`,`brojPutovnice`,`pbrMjesto`) values (1,'Mario','Leskovic','0243758492',10000),(2,'Ivana','Mirkovic','0243751323',10000),(3,'Morana','Petric','27476342',10000),(4,'Mirna','Hadziefesic','34234238',71000),(5,'Halid','Hadziefesic','35435435',71000),(6,'Safet','Bajramovic','35435435',69000),(7,'Janez','Dugancic','123454964',1000),(8,'Brant','Zoltent','549166415',1200),(9,'Gareth','Lesterson','484613148',1200),(10,'Hans','Friedrich','649484513',1390),(11,'Joanna','Friedrich','645451913',1390),(12,'Brokta','Hussein','484848464',2400),(13,'John','Ferdinand','879878463',6320),(14,'Monica','Brett','754515216',6320),(15,'Theo','Walcott','323331585',6320),(16,'Mark','Freiburg','23315512',8000),(17,'Anne','Freiburg','23315512',8000),(18,'Ivanusz','Kosmicki','5456441813',8800),(19,'Aki','Zaltamovski','545613212',12000),(20,'Leonard','Matremounet','132357453',13000),(21,'Miriam','Matremounet','132357453',13000),(22,'Lodos','Salpdingidis','546461125',16541),(23,'Marta','Salpdingidis','546461125',16541),(24,'Monika','Fumic','464684521',21000),(25,'Franjo','Stipetic','84554361',21000),(26,'Blazenka','Kordic','776664221',74000),(27,'Radojka','Veselinovic','474111121',82000),(28,'Radovan','Veselinovic','74564654',82000);

/*Table structure for table `hotel` */

DROP TABLE IF EXISTS `hotel`;

CREATE TABLE `hotel` (
  `ID` int(10) NOT NULL,
  `naziv` varchar(80) DEFAULT NULL,
  `opis` text,
  `brojZvjezdica` int(10) DEFAULT NULL,
  `adresa` varchar(200) DEFAULT NULL,
  `pbrMjesto` int(10) DEFAULT NULL,
  PRIMARY KEY (`ID`),
  KEY `hotel_mjesto` (`pbrMjesto`),
  CONSTRAINT `hotel_mjesto` FOREIGN KEY (`pbrMjesto`) REFERENCES `mjesto` (`pbrMjesto`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

/*Data for the table `hotel` */

insert  into `hotel`(`ID`,`naziv`,`opis`,`brojZvjezdica`,`adresa`,`pbrMjesto`) values (1,'Esplanade','Hotel u centru hrvatske metropole sa pogledom na zeljeznicki kolodvor',5,'Trg Kralja Tomislava 10',10000),(2,'International','Omiljeno sportsko odmaraliste te GoldenSun CASINO',4,'Trg Mladosti 8',10000),(3,'Hilton','Hotel u neposrednoj blizini mora',5,'Budvanski odsjecak 4',1231),(4,'Hilton','Glasoviti londonski luksuzni hotel',5,'Westminster road 12A',6320),(5,'Zeljeznicar','Jeftin hotel sa domacom atmosferom i vrhunskim delicijama',3,'Kobiljak 14',71000),(6,'Golden City Hotel','Uzivajte u atmosferi drevne grcke te luksuzu hotela Akropolis',4,'N. Nikodimuo str.18',16541),(7,'Hotel Kerum','Uzivajte u najlipsem gradu na svitu! To vam zeli Zeljko!',4,'Ulica brace Radica 46',21000);

/*Table structure for table `mjesto` */

DROP TABLE IF EXISTS `mjesto`;

CREATE TABLE `mjesto` (
  `pbrMjesto` int(10) NOT NULL,
  `naziv` varchar(70) DEFAULT NULL,
  `IDDrzava` int(10) DEFAULT NULL,
  PRIMARY KEY (`pbrMjesto`),
  KEY `mjesto_drz` (`IDDrzava`),
  CONSTRAINT `mjesto_drz` FOREIGN KEY (`IDDrzava`) REFERENCES `drzava` (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

/*Data for the table `mjesto` */

insert  into `mjesto`(`pbrMjesto`,`naziv`,`IDDrzava`) values (1000,'Ljubljana',4),(1200,'Amsterdam',7),(1231,'Budva',12),(1390,'Salzburg',5),(1450,'Be?',5),(2400,'Sofija',9),(6320,'London',15),(8000,'Zurich',13),(8800,'Budimpesta',11),(10000,'Zagreb',1),(12000,'Bukurest',8),(13000,'Marseille',14),(16541,'Atena',10),(21000,'Split',1),(69000,'Bihac',3),(70600,'Novi Sad',2),(71000,'Sarajevo',3),(74000,'Mostar',3),(82000,'Beograd',2),(90001,'Nurnberg',6);

/*Table structure for table `rezervacija` */

DROP TABLE IF EXISTS `rezervacija`;

CREATE TABLE `rezervacija` (
  `ID` int(10) NOT NULL,
  `datDolazak` date DEFAULT NULL,
  `vrijemeDolazak` time DEFAULT NULL,
  `danaOstanak` int(50) DEFAULT NULL,
  `IDGost` int(10) DEFAULT NULL,
  `IDSoba` int(10) DEFAULT NULL,
  PRIMARY KEY (`ID`),
  KEY `rez_gost` (`IDGost`),
  KEY `rez_soba` (`IDSoba`),
  CONSTRAINT `rez_gost` FOREIGN KEY (`IDGost`) REFERENCES `gost` (`ID`),
  CONSTRAINT `rez_soba` FOREIGN KEY (`IDSoba`) REFERENCES `soba` (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

/*Data for the table `rezervacija` */

insert  into `rezervacija`(`ID`,`datDolazak`,`vrijemeDolazak`,`danaOstanak`,`IDGost`,`IDSoba`) values (1,'2011-07-10','14:00:00',12,1,84),(2,'2011-07-10','14:00:00',12,2,84),(3,'2011-07-10','14:00:00',12,3,84),(4,'2011-07-23','08:00:00',7,4,88),(5,'2011-07-23','08:00:00',7,5,88),(6,'2011-08-01','10:00:00',10,6,110),(7,'2011-08-10','16:00:00',14,7,112),(8,'2011-07-05','12:00:00',7,8,102),(9,'2011-07-05','12:00:00',7,9,102),(10,'2011-07-05','12:00:00',10,10,212),(11,'2011-07-05','12:00:00',10,11,212),(12,'2011-07-12','06:00:00',14,11,307),(13,'2011-07-14','10:00:00',14,13,244),(14,'2011-07-14','10:00:00',14,14,244),(15,'2011-08-15','07:00:00',8,15,464),(16,'2011-08-01','09:00:00',7,16,330),(17,'2011-08-01','09:00:00',7,17,330),(18,'2011-08-04','05:00:00',10,18,200),(19,'2011-08-06','23:00:00',12,19,202),(20,'2011-08-15','19:00:00',14,20,248),(21,'2011-08-15','19:00:00',14,21,248),(22,'2011-07-10','16:00:00',4,22,813),(23,'2011-07-10','16:00:00',4,23,813),(24,'2011-07-12','10:00:00',1,24,500),(25,'2011-07-30','08:00:00',7,25,124),(26,'2011-07-30','08:00:00',7,26,124),(27,'2011-07-30','08:00:00',7,27,124),(28,'2011-07-30','08:00:00',7,28,124);

/*Table structure for table `soba` */

DROP TABLE IF EXISTS `soba`;

CREATE TABLE `soba` (
  `ID` int(10) NOT NULL,
  `naziv` varchar(20) DEFAULT NULL,
  `kat` int(10) DEFAULT NULL,
  `cijenaNocenja` decimal(8,2) DEFAULT NULL,
  `IDHotel` int(10) DEFAULT NULL,
  PRIMARY KEY (`ID`),
  KEY `soba_hotel` (`IDHotel`),
  CONSTRAINT `soba_hotel` FOREIGN KEY (`IDHotel`) REFERENCES `hotel` (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

/*Data for the table `soba` */

insert  into `soba`(`ID`,`naziv`,`kat`,`cijenaNocenja`,`IDHotel`) values (84,'Trokrevetna',7,'40.00',7),(88,'Dvokrevetna',2,'120.00',4),(102,'Dvokrevetna',1,'12.40',5),(110,'Jednokrevetna',1,'80.00',7),(112,'Jednokrevetna',8,'50.00',2),(124,'Cetverokrevetna',12,'36.00',7),(200,'Jednokrevetna',10,'50.00',2),(202,'Jednokrevetna',2,'36.00',1),(212,'Dvokrevetna',21,'80.00',6),(244,'Dvokrevetna',2,'36.90',3),(248,'Dvokrevetna',2,'36.90',3),(307,'Jednokrevetna',3,'40.00',1),(330,'Dvokrevetna',8,'120.00',3),(464,'Jednokrevetna',24,'100.00',6),(500,'Predsjednicki apartm',5,'400.00',1),(813,'Dvokrevetna',42,'80.00',6);

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;
