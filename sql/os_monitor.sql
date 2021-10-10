-- phpMyAdmin SQL Dump
-- version 4.9.5
-- https://www.phpmyadmin.net/
--
-- Host: localhost
-- Generation Time: Aug 01, 2021 at 06:06 PM
-- Server version: 10.3.28-MariaDB
-- PHP Version: 7.4.21

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET AUTOCOMMIT = 0;
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: cmr_monitor
--
CREATE DATABASE IF NOT EXISTS cmr_monitor DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;
USE cmr_monitor;

-- --------------------------------------------------------

--
-- Table structure for table config
--

DROP TABLE IF EXISTS config;
CREATE TABLE config (
  param varchar(64) NOT NULL,
  value varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table links
--

DROP TABLE IF EXISTS links;
CREATE TABLE links (
  linkid int(11) NOT NULL,
  base_url varchar(128) NOT NULL,
  osdd text DEFAULT NULL,
  granule text DEFAULT NULL,
  fk_source varchar(10) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table monitor
--

DROP TABLE IF EXISTS monitor;
CREATE TABLE monitor (
  id int(11) NOT NULL,
  request_type enum('osdd','granule') NOT NULL,
  http_status int(11) NOT NULL,
  total_time float DEFAULT NULL,
  elapsed_time float DEFAULT NULL,
  http_message text DEFAULT NULL,
  parsed varchar(16) DEFAULT NULL,
  error text DEFAULT NULL,
  timestamp timestamp NOT NULL DEFAULT current_timestamp(),
  fk_source varchar(10) NOT NULL,
  url text NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `source`
--

DROP TABLE IF EXISTS source;
CREATE TABLE `source` (
  sourceid int(11) NOT NULL,
  source varchar(10) NOT NULL,
  label varchar(64) NOT NULL,
  status enum('ACTIVE','INACTIVE','UNKNOWN','') NOT NULL DEFAULT 'ACTIVE',
  ping enum('up','down')
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Indexes for dumped tables
--

--
-- Indexes for table config
--
ALTER TABLE config
  ADD UNIQUE KEY param (param);

--
-- Indexes for table links
--
ALTER TABLE links
  ADD PRIMARY KEY (linkid),
  ADD KEY fk_linksource (fk_source);

--
-- Indexes for table monitor
--
ALTER TABLE monitor
  ADD PRIMARY KEY (id),
  ADD KEY fk_sourcename (fk_source);

--
-- Indexes for table `source`
--
ALTER TABLE `source`
  ADD PRIMARY KEY (sourceid),
  ADD KEY source (source);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table links
--
ALTER TABLE links
  MODIFY linkid int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table monitor
--
ALTER TABLE monitor
  MODIFY id int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `source`
--
ALTER TABLE `source`
  MODIFY sourceid int(11) NOT NULL AUTO_INCREMENT;

--
-- Constraints for dumped tables
--

--
-- Constraints for table links
--
ALTER TABLE links
  ADD CONSTRAINT fk_linksource FOREIGN KEY (fk_source) REFERENCES source (source);

--
-- Constraints for table monitor
--
ALTER TABLE monitor
  ADD CONSTRAINT fk_sourcename FOREIGN KEY (fk_source) REFERENCES source (source);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
