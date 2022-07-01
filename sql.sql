CREATE TABLE IF NOT EXISTS `keep_cooldowns` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `cooldown_hash` varchar(50) NOT NULL,
  `type` INT NOT NULL,
  `metadata` TEXT NOT NULL DEFAULT '',
  PRIMARY KEY (`cooldown_hash`),
  KEY `id` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8mb4;