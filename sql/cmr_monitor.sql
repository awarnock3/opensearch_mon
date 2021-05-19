-- phpMyAdmin SQL Dump
-- version 4.9.5
-- https://www.phpmyadmin.net/
--
-- Host: localhost
-- Generation Time: May 19, 2021 at 10:21 PM
-- Server version: 10.3.28-MariaDB
-- PHP Version: 7.4.19

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
-- Table structure for table `monitor`
--

CREATE TABLE `monitor` (
  `id` int(11) NOT NULL,
  `http_status` int(11) NOT NULL,
  `total_time` int(11) DEFAULT NULL,
  `elapsed_time` int(11) DEFAULT NULL,
  `http_message` varchar(16) DEFAULT NULL,
  `parsed` varchar(16) DEFAULT NULL,
  `error` varchar(128) DEFAULT NULL,
  `timestamp` timestamp NULL DEFAULT NULL ON UPDATE current_timestamp(),
  `sourceid` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `source`
--

CREATE TABLE `source` (
  `sourceid` int(11) NOT NULL,
  `source` enum('CMR','CCMEO','EUMETSAT','GHRSST','ISRO','INPE','MOSDAC','USGS','CGEOSS','NRSCC') NOT NULL,
  `label` varchar(64) NOT NULL,
  `status` enum('ACTIVE','INACTIVE','UNKNOWN','') NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Dumping data for table `source`
--

INSERT INTO `source` (`sourceid`, `source`, `label`, `status`) VALUES
(1, 'CMR', 'NASA/CMR (USA)', 'ACTIVE'),
(2, 'CCMEO', 'CCMEO (Canada)', 'ACTIVE'),
(3, 'EUMETSAT', 'EUMETSAT (ESA)', 'ACTIVE'),
(4, 'GHRSST', 'NOAA-NCEI/GHRSST (USA)', 'ACTIVE'),
(5, 'ISRO', 'ISRO/NRSC (India)', 'ACTIVE'),
(6, 'INPE', 'INPE (Brazil)', 'INACTIVE'),
(7, 'MOSDAC', 'ISRO/MOSDAC (India)', 'ACTIVE'),
(8, 'NRSCC', 'NRSCC (China)', 'UNKNOWN'),
(9, 'CGEOSS', 'GEOSS (China)', 'UNKNOWN');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `monitor`
--
ALTER TABLE `monitor`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_sourceid` (`sourceid`);

--
-- Indexes for table `source`
--
ALTER TABLE `source`
  ADD PRIMARY KEY (`sourceid`),
  ADD KEY `idx_source` (`source`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `monitor`
--
ALTER TABLE `monitor`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `source`
--
ALTER TABLE `source`
  MODIFY `sourceid` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `monitor`
--
ALTER TABLE `monitor`
  ADD CONSTRAINT `fk_sourceid` FOREIGN KEY (`sourceid`) REFERENCES `source` (`sourceid`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
