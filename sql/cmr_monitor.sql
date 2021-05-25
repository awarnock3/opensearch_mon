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
-- Table structure for table `links`
--

DROP TABLE IF EXISTS `links`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `links` (
  `linkid` int(11) NOT NULL AUTO_INCREMENT,
  `osdd` text DEFAULT NULL,
  `granule` text DEFAULT NULL,
  `fk_source` varchar(10) NOT NULL,
  PRIMARY KEY (`linkid`),
  KEY `fk_linksource` (`fk_source`),
  CONSTRAINT `fk_linksource` FOREIGN KEY (`fk_source`) REFERENCES `source` (`source`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `links`
--

LOCK TABLES `links` WRITE;
/*!40000 ALTER TABLE `links` DISABLE KEYS */;
INSERT INTO `links` VALUES (1,'https://cmr.earthdata.nasa.gov/opensearch/granules/descriptor_document.xml?collectionConceptId',NULL,'CMR'),(2,'https://eodms-sgdot.nrcan-rncan.gc.ca/apps/opensearch/opensearch_descriptor_document_Radarsat-2.xml','http://eodms-sgdot.nrcan-rncan.gc.ca/apps/cgi/opensearch/eodms_opensearch_r1.sh?datasetId=Radarsat-2&bbox=-100,55,-95,80&dtstart=2020-07-01T00:00:00Z&dtend=2020-07-09T23:59:59Z&startIndex=1&count=10&format=atom','CCMEO'),(3,'https://navigator.eumetsat.int/os-description?pi=urn:ogc:def:EOP:EUM:acronym:OASW025:fileid:EO:EUM:DAT:METOP:ASCAT25','https://navigator.eumetsat.int/eopos?pi=acronym:OSSTNAR:satellite:M01,M02,NPP:id:EO:EUM:DAT:MULT:OSSTNAR:fileid:EO:EUM:DAT:MULT:OSSTNAR&si=1&c=10&dtstart=2016-12-25T00:00:00Z&dtend=2016-12-31T23:59:59Z','EUMETSAT'),(4,'https://cmr.earthdata.nasa.gov/opensearch/granules/descriptor_document.xml?collectionConceptId=C1597928917-NOAA_NCEI',NULL,'GHRSST'),(5,'https://bhoonidhi.nrsc.gov.in/MetaSearch/irsOSDD?&datasetId=P6_AWIF_STUC00GTD','https://bhoonidhi.nrsc.gov.in/MetaSearch/irsSearch?datasetId=P6_AWIF_STUC00GTD&startIndex=1&count=10','ISRO'),(6,NULL,NULL,'INPE'),(7,'https://mosdac.gov.in/opensearch/dataset/3DIMG_L2P_VSW/osdd.xml','https://mosdac.gov.in/opensearch/datasets.atom?datasetId=3DIMG_L2P_VSW&startIndex=1&count=10','MOSDAC'),(8,NULL,NULL,'NRSCC'),(9,NULL,NULL,'CGEOSS'),(10,'https://m2m.cr.usgs.gov/api/open-search/granule.osdd?datasetName=landsat_8_c1','https://m2m.cr.usgs.gov/api/open-search/datasets.atom?datasetName=LANDSAT_8_C1&startIndex=1&count=10','USGS');
/*!40000 ALTER TABLE `links` ENABLE KEYS */;
UNLOCK TABLES;

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
  `http_message` text DEFAULT NULL,
  `parsed` varchar(16) DEFAULT NULL,
  `error` text DEFAULT NULL,
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

-- Dump completed on 2021-05-25 16:34:04
