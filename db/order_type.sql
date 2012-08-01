-- MySQL dump 10.13  Distrib 5.5.24, for debian-linux-gnu (x86_64)
--
-- Host: localhost    Database: bart2_development
-- ------------------------------------------------------
-- Server version	5.5.24-0ubuntu0.12.04.1

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `order_type`
--

DROP TABLE IF EXISTS `order_type`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `order_type` (
  `order_type_id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL DEFAULT '',
  `description` varchar(255) NOT NULL DEFAULT '',
  `creator` int(11) NOT NULL DEFAULT '0',
  `date_created` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  `retired` smallint(6) NOT NULL DEFAULT '0',
  `retired_by` int(11) DEFAULT NULL,
  `date_retired` datetime DEFAULT NULL,
  `retire_reason` varchar(255) DEFAULT NULL,
  `uuid` char(38) NOT NULL,
  PRIMARY KEY (`order_type_id`),
  UNIQUE KEY `order_type_uuid_index` (`uuid`),
  KEY `type_created_by` (`creator`),
  KEY `user_who_retired_order_type` (`retired_by`),
  KEY `retired_status` (`retired`),
  CONSTRAINT `type_created_by` FOREIGN KEY (`creator`) REFERENCES `users` (`user_id`),
  CONSTRAINT `user_who_retired_order_type` FOREIGN KEY (`retired_by`) REFERENCES `users` (`user_id`)
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `order_type`
--

LOCK TABLES `order_type` WRITE;
/*!40000 ALTER TABLE `order_type` DISABLE KEYS */;
INSERT INTO `order_type` VALUES (1,'Drug Order','Drug information captured from patient historically',1,'2005-08-08 07:06:12',0,NULL,NULL,NULL,'e595616e-8abf-11e1-b88f-544249e32ba2'),(2,'Drug','New drug order',1,'2005-08-08 07:07:20',0,NULL,NULL,NULL,'e5957924-8abf-11e1-b88f-544249e32ba2'),(3,'Test','New test order',1,'2005-08-08 07:07:53',0,NULL,NULL,NULL,'e5957b90-8abf-11e1-b88f-544249e32ba2'),(4,'Lab ','Lab order',1,'2009-06-29 06:52:44',0,NULL,NULL,NULL,'e5957da2-8abf-11e1-b88f-544249e32ba2'),(5,'Drug Given','This is a drug given to an admitted patient while in hospital',1,'2010-01-08 11:06:57',0,NULL,NULL,NULL,'e5957faa-8abf-11e1-b88f-544249e32ba2'),(6,'Drug Prescribed','This is a drug given to a patient when leaving the hospital',1,'2010-01-08 11:07:57',0,NULL,NULL,NULL,'e59581c6-8abf-11e1-b88f-544249e32ba2'),(7,'Common drug orders','These are drug orders preloaded in the system as given by the Doctors to ease prescriptions',1,'2010-07-02 10:02:02',0,NULL,NULL,NULL,'e59583ce-8abf-11e1-b88f-544249e32ba2'),(8,'Xray','This is an xray investigation request',1,'2012-07-25 14:16:55',0,NULL,NULL,NULL,'16e7ab1e-d66b-11e1-974d-544249e32ba2'),(9,'Ultrasound','This is an ultrasound investigation request',1,'2012-07-25 17:05:50',0,NULL,NULL,NULL,'a4baf37c-d66b-11e1-974d-544249e32ba2');
/*!40000 ALTER TABLE `order_type` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2012-08-01  9:33:46
