DROP DATABASE IF EXISTS `phpMyAdmin_test`;
CREATE DATABASE `phpMyAdmin_test` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE phpMyAdmin_test;

DROP TABLE IF EXISTS `Foo`;
CREATE TABLE `Foo` (
  `ID` int(11) NOT NULL auto_increment,
  `Str` char(16) NOT NULL default '',
  `Num` int(11) NOT NULL default '0',
  `Ptc` float(10,2) default NULL,
  `Enm` enum('A','B') NOT NULL default 'F',
  PRIMARY KEY  (`ID`)
) ENGINE=InnoDB;

INSERT INTO `Foo` VALUES (1,'Lorem','1000','0.1','A');
INSERT INTO `Foo` VALUES (2,'Impsum','2000','0.2','B');
INSERT INTO `Foo` VALUES (3,'dolor','3000','0.3','A');

DROP TABLE IF EXISTS `Bar`;
CREATE TABLE `Bar` (
  `ID` int(11) NOT NULL auto_increment,
  `Str` char(16) NOT NULL default '',
  `Num` int(11) NOT NULL default '0',
  `Ptc` float(10,2) default NULL,
  `Enm` enum('A','B') NOT NULL default 'F',
  PRIMARY KEY  (`ID`)
) ENGINE=MyISAM;

INSERT INTO `Foo` VALUES (1,'Lorem','1000','0.1','A');
INSERT INTO `Foo` VALUES (2,'Impsum','2000','0.2','B');
INSERT INTO `Foo` VALUES (3,'dolor','3000','0.3','A');

DROP TABLE IF EXISTS `Csv`;
CREATE TABLE `Csv` (
  `StrA` char(16) NOT NULL,
  `StrB` char(16) NOT NULL,
) ENGINE=CSV;

INSERT INTO `Csv` VALUES ('Lorem','Ipsum');
INSERT INTO `Csv` VALUES ('dolor','sit');
INSERT INTO `Csv` VALUES ('amet','consectetur');
