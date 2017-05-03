-- Adminer 4.2.5 MySQL dump

SET NAMES utf8;
SET time_zone = '+00:00';
SET foreign_key_checks = 0;
SET sql_mode = 'NO_AUTO_VALUE_ON_ZERO';

DROP TABLE IF EXISTS `donations`;
CREATE TABLE `donations` (
  `ID` int(11) NOT NULL,
  `username` longtext NOT NULL,
  `donation` int(11) NOT NULL,
  `donate_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS `epf`;
CREATE TABLE `epf` (
  `ID` int(11) NOT NULL,
  `isagent` tinyint(1) NOT NULL DEFAULT '1',
  `status` mediumtext NOT NULL,
  `currentpoints` int(10) NOT NULL DEFAULT '20',
  `totalpoints` int(10) NOT NULL DEFAULT '100',
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

INSERT INTO `epf` (`ID`, `isagent`, `status`, `currentpoints`, `totalpoints`) VALUES
(1,	1,	'1',	3,	100),
(2,	1,	'1',	20,	100);

DROP TABLE IF EXISTS `igloos`;
CREATE TABLE `igloos` (
  `ID` int(11) NOT NULL,
  `igloo` int(10) NOT NULL DEFAULT '1',
  `floor` int(10) NOT NULL DEFAULT '0',
  `music` int(10) NOT NULL DEFAULT '0',
  `furniture` longtext NOT NULL,
  `ownedFurns` longtext NOT NULL,
  `ownedIgloos` longtext NOT NULL,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

INSERT INTO `igloos` (`ID`, `igloo`, `floor`, `music`, `furniture`, `ownedFurns`, `ownedIgloos`) VALUES
(1,	1,	0,	0,	'',	'',	''),
(2,	1,	0,	0,	'',	'',	'');

DROP TABLE IF EXISTS `igloo_contest`;
CREATE TABLE `igloo_contest` (
  `ID` int(11) NOT NULL,
  `username` longtext NOT NULL,
  `signup_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


DROP TABLE IF EXISTS `kittens`;
CREATE TABLE `kittens` (
  `ID` int(11) NOT NULL AUTO_INCREMENT COMMENT 'Penguin ID',
  `username` varchar(15) NOT NULL COMMENT 'Penguin Username',
  `nickname` varchar(15) NOT NULL COMMENT 'Penguin Nickname',
  `password` char(255) NOT NULL COMMENT 'Penguin Password',
  `uuid` varchar(50) NOT NULL COMMENT 'Penguin Universal Unique Identification Key',
  `lkey` char(255) NOT NULL COMMENT 'Penguin Login Key',
  `joindate` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Penguin Age',
  `wallet` int(11) NOT NULL DEFAULT '5000',
  `inventory` longtext NOT NULL COMMENT 'Penguin Inventory',
  `clothing` longtext NOT NULL COMMENT 'Penguin Clothing',
  `ranking` longtext NOT NULL COMMENT 'Staff ranking',
  `buddies` longtext NOT NULL COMMENT 'Penguin Buddies',
  `ignored` longtext NOT NULL COMMENT 'Penguin Ignored Clients',
  `moderation` longtext NOT NULL COMMENT 'Muting and Banning',
  `invalid_logins` int(3) NOT NULL DEFAULT '0' COMMENT 'Account Hijacking Lock',
  `llg` mediumtext NOT NULL COMMENT 'Latest Login Time',
  PRIMARY KEY (`ID`),
  UNIQUE KEY `username` (`username`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

INSERT INTO `kittens` (`ID`, `username`, `nickname`, `password`, `uuid`, `lkey`, `joindate`, `wallet`, `inventory`, `clothing`, `ranking`, `buddies`, `ignored`, `moderation`, `invalid_logins`, `llg`, `estatus`) VALUES
(1,	'Lynx',	'Lynx',	'{X-PBKDF2}HMACSHA2+256:AAAnEA:mFlHdIdWZ8KgZQXl:34fO6Wv58vqhoHT/dPkmqBhcEqgjykf6Ku4TZBis/pY=',	'fc0e6084-08e8-11e6-b512-3e1d05defe78',	'',	'2016-04-23 00:19:25',	7770,	'',	'{\"clothing\":{\"face\":\"0\",\"neck\":\"0\",\"hand\":\"0\",\"color\":\"8\",\"head\":\"0\",\"flag\":\"0\",\"feet\":0,\"body\":\"0\",\"photo\":\"0\"}}',	'{\"ranking\": {\"isStaff\": \"1\", \"isMed\": \"0\", \"isMod\": \"0\", \"isAdmin\": \"1\", \"rank\": \"6\"}}',	'',	'',	'{\"moderation\": {\"isBanned\": \"\", \"isMuted\": \"0\"}}',	0,	'1489912187',	1),
(2,	'Test',	'Test',	'{X-PBKDF2}HMACSHA2+256:AAAnEA:PS+hXxs1zUyPq8NM:LoFv4WIq2s3FoLcfn9qCtMRu9fdAzUcIA32uZ/G+bm8=',	'36e9fbb6-0fb3-11e6-a148-3e1d05defe78',	'',	'2016-05-01 15:42:05',	5765,	'',	'{\"clothing\":{\"color\":0,\"head\":\"429\",\"neck\":0,\"face\":0,\"flag\":\"0\",\"hand\":\"0\",\"photo\":\"0\",\"feet\":0,\"body\":\"0\"}}',	'{\"ranking\": {\"isStaff\": \"0\", \"isMed\": \"0\", \"isMod\": \"0\", \"isAdmin\": \"0\", \"rank\": \"1\"}}',	'',	'',	'{\"moderation\":{\"isBanned\":\"0\",\"isMuted\":0}}',	1,	'1489903585',	1);

DROP TABLE IF EXISTS `postcards`;
CREATE TABLE `postcards` (
  `postcardID` int(10) NOT NULL AUTO_INCREMENT,
  `recepient` int(10) NOT NULL,
  `mailerName` char(12) NOT NULL,
  `mailerID` int(10) NOT NULL,
  `notes` char(12) NOT NULL,
  `timestamp` int(8) NOT NULL,
  `postcardType` int(5) NOT NULL,
  `isRead` int(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`postcardID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


DROP TABLE IF EXISTS `puffles`;
CREATE TABLE `puffles` (
  `puffleID` int(11) NOT NULL AUTO_INCREMENT,
  `ownerID` int(2) NOT NULL,
  `puffleName` char(10) NOT NULL,
  `puffleType` int(2) NOT NULL,
  `puffleEnergy` int(3) NOT NULL DEFAULT '100',
  `puffleHealth` int(3) NOT NULL DEFAULT '100',
  `puffleRest` int(3) NOT NULL DEFAULT '100',
  `puffleWalking` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`puffleID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


DROP TABLE IF EXISTS `stamps`;
CREATE TABLE `stamps` (
  `ID` int(11) NOT NULL,
  `stamps` longtext NOT NULL,
  `cover` longtext NOT NULL,
  `restamps` longtext NOT NULL,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

INSERT INTO `stamps` (`ID`, `stamps`, `cover`, `restamps`) VALUES
(1,	'201|200|199|198|197|14',	'',	''),
(2,	'201|200|199|198|197',	'',	'');

-- 2017-03-19 08:31:17
