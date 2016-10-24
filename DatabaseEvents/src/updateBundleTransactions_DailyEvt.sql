CREATE TABLE `bundle_transactions` (
  `id` BIGINT(20) NOT NULL AUTO_INCREMENT,
  `transactionType` VARCHAR(30) DEFAULT NULL,
  `bundleAmount` INT(11) DEFAULT NULL,
  `bundleBalance` INT(11) DEFAULT NULL,
  `transactionDate` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `lastReferenceDate` TIMESTAMP NOT NULL DEFAULT '0000-00-00 00:00:00',
  PRIMARY KEY (`id`)
) ENGINE=INNODB DEFAULT CHARSET=latin1;


DELIMITER $$

-- SET GLOBAL event_scheduler = ON$$     -- required for event to execute but not create    

CREATE	/*[DEFINER = { user | CURRENT_USER }]*/	EVENT `updateBundleTransactions_DailyEvt`

ON SCHEDULE
	 /* uncomment the example below you want to use */

	-- scheduleexample 1: run once

	   --  AT 'YYYY-MM-DD HH:MM.SS'/CURRENT_TIMESTAMP { + INTERVAL 1 [HOUR|MONTH|WEEK|DAY|MINUTE|...] }

	-- scheduleexample 2: run at intervals forever after creation

	   -- EVERY 1 [HOUR|MONTH|WEEK|DAY|MINUTE|...]

	-- scheduleexample 3: specified start time, end time and interval for execution
	EVERY 1  DAY

	STARTS '2016-10-25 00:00.10'


/*[ON COMPLETION [NOT] PRESERVE]
[ENABLE | DISABLE]
[COMMENT 'comment']*/

DO
	BEGIN
		DECLARE maxId INT UNSIGNED;
		DECLARE lastRefDate TIMESTAMP;
		DECLARE transType VARCHAR(30);
		DECLARE lastBundleBalance INT SIGNED;
		DECLARE transactionCount INT SIGNED;
		DECLARE secondLastBundleBalance INT SIGNED;

		SELECT MAX(id) INTO maxId FROM bundle_transactions;
		SELECT `lastReferenceDate`,`transactionType`,`bundleBalance` INTO lastRefDate,transType,lastBundleBalance
	    FROM bundle_transactions WHERE id = maxId;

	    IF DAY(NOW())=02 THEN
	    	SELECT COUNT(*) INTO transactionCount FROM transactionsTable
			WHERE DAY(transactionTimestamp)=1 AND MONTH(transactionTimestamp) = MONTH(NOW()) AND YEAR(transactionTimestamp) = YEAR(NOW());

			INSERT INTO `bundle_transactions` (`transactionType`,`bundleAmount`,`bundleBalance`,`lastReferenceDate`)
			VALUES (CONCAT ('1st ',MONTHNAME(NOW()),' Usage'),transactionCount*-1,lastBundleBalance-transactionCount,
			CONCAT(YEAR(NOW()),'-',MONTH(NOW()),'-','01',' 00:00:00'));
	    ELSE
	    	SELECT COUNT(*) INTO transactionCount FROM transactionsTable WHERE transactionTimestamp > lastRefDate;
	    	#assuming no ids in bundle_transactions are deleted or skipped
	    	SELECT `bundleBalance` INTO secondLastBundleBalance FROM `bundle_transactions` WHERE id = maxId-1;
	    	IF DAY(NOW())=01 THEN
				UPDATE `bundle_transactions` SET `transactionType`=CONCAT(DAY(lastRefDate),'-',DAY(SUBDATE(CURRENT_DATE, 1)),' ',MONTHNAME(SUBDATE(CURRENT_DATE, 1)),' Usage'),
				`bundleAmount`=transactionCount*-1,`bundleBalance`=secondLastBundleBalance-transactionCount,`transactionDate`=NOW()
				WHERE id=maxId;
			ELSE
				UPDATE `bundle_transactions` SET `transactionType`=CONCAT(DAY(lastRefDate),'-',DAY(NOW())-1,' ',MONTHNAME(NOW()),' Usage'),
				`bundleAmount`=transactionCount*-1,`bundleBalance`=secondLastBundleBalance-transactionCount,`transactionDate`=NOW()
				WHERE id=maxId;
			END IF;
	    END IF;
	END$$

DELIMITER ;