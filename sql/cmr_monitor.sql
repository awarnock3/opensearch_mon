-- MySQL dump 10.19  Distrib 10.3.28-MariaDB, for Linux (x86_64)
--
-- Host: localhost    Database: cmr_monitor
-- ------------------------------------------------------
-- Server version	10.3.28-MariaDB

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `monitor`
--

DROP TABLE IF EXISTS `monitor`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `monitor` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `request_type` enum('osdd','granule') NOT NULL,
  `http_status` int(11) NOT NULL,
  `total_time` float DEFAULT NULL,
  `elapsed_time` float DEFAULT NULL,
  `http_message` varchar(16) DEFAULT NULL,
  `parsed` varchar(16) DEFAULT NULL,
  `error` varchar(128) DEFAULT NULL,
  `timestamp` timestamp NOT NULL DEFAULT current_timestamp(),
  `fk_source` varchar(10) NOT NULL,
  `url` text NOT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_sourcename` (`fk_source`),
  CONSTRAINT `fk_sourcename` FOREIGN KEY (`fk_source`) REFERENCES `source` (`source`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `monitor`
--

LOCK TABLES `monitor` WRITE;
/*!40000 ALTER TABLE `monitor` DISABLE KEYS */;
/*!40000 ALTER TABLE `monitor` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `source`
--

DROP TABLE IF EXISTS `source`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `source` (
  `sourceid` int(11) NOT NULL AUTO_INCREMENT,
  `source` varchar(10) NOT NULL,
  `label` varchar(64) NOT NULL,
  `status` enum('ACTIVE','INACTIVE','UNKNOWN','') NOT NULL DEFAULT 'ACTIVE',
  PRIMARY KEY (`sourceid`),
  KEY `source` (`source`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `source`
--

LOCK TABLES `source` WRITE;
/*!40000 ALTER TABLE `source` DISABLE KEYS */;
INSERT INTO `source` VALUES (1,'CMR','NASA/CMR (USA)','ACTIVE'),(2,'CCMEO','CCMEO (Canada)','ACTIVE'),(3,'EUMETSAT','EUMETSAT (ESA)','ACTIVE'),(4,'GHRSST','NOAA-NCEI/GHRSST (USA)','ACTIVE'),(5,'ISRO','ISRO/NRSC (India)','ACTIVE'),(6,'INPE','INPE (Brazil)','INACTIVE'),(7,'MOSDAC','ISRO/MOSDAC (India)','ACTIVE'),(8,'NRSCC','NRSCC (China)','UNKNOWN'),(9,'CGEOSS','GEOSS (China)','UNKNOWN'),(10,'USGS','USGS/LSI','ACTIVE');
/*!40000 ALTER TABLE `source` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2021-05-24 14:36:08
