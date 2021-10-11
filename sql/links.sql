-- phpMyAdmin SQL Dump
-- version 4.9.5
-- https://www.phpmyadmin.net/
--
-- Host: localhost
-- Generation Time: Oct 11, 2021 at 02:58 PM
-- Server version: 10.3.28-MariaDB
-- PHP Version: 7.4.23

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET AUTOCOMMIT = 0;
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `cmr_monitor`
--

-- --------------------------------------------------------

--
-- Table structure for table `links`
--

CREATE TABLE IF NOT EXISTS `links` (
  `linkid` int(11) NOT NULL AUTO_INCREMENT,
  `base_url` varchar(128) NOT NULL,
  `osdd` text DEFAULT NULL,
  `granule` text DEFAULT NULL,
  `fk_source` varchar(10) NOT NULL,
  PRIMARY KEY (linkid),
  INDEX (fk_source),
  CONSTRAINT `fk_linksource` FOREIGN KEY (`fk_source`) REFERENCES `source` (`source`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Dumping data for table `links`
--

INSERT INTO `links` (`base_url`, `osdd`, `granule`, `fk_source`) VALUES
('https://cmr.earthdata.nasa.gov', 'https://cmr.earthdata.nasa.gov/opensearch/granules/descriptor_document.xml?collectionConceptId', NULL, 'CMR');

COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
