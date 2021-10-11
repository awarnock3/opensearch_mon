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
-- Table structure for table `source`
--

CREATE TABLE IF NOT EXISTS `source` (
  `sourceid` int(11) NOT NULL AUTO_INCREMENT,
  `source` varchar(10) NOT NULL,
  `label` varchar(64) NOT NULL,
  `status` enum('ACTIVE','INACTIVE','UNKNOWN','') NOT NULL DEFAULT 'ACTIVE',
  `ping` enum('up','down') DEFAULT NULL,
  PRIMARY KEY (sourceid),
  INDEX (source)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Sample for table `source`
--

INSERT INTO `source` (`source`, `label`, `status`, `ping`) VALUES
('CMR', 'NASA/CMR (USA)', 'ACTIVE', 'up');

COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
