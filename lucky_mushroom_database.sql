SET FOREIGN_KEY_CHECKS=0 
;

/* Drop Tables */

DROP TABLE IF EXISTS `articles` CASCADE
;

DROP TABLE IF EXISTS `articles_gps_tags` CASCADE
;

DROP TABLE IF EXISTS `edible_statuses` CASCADE
;

DROP TABLE IF EXISTS `gps_tags` CASCADE
;

DROP TABLE IF EXISTS `recognition_requests` CASCADE
;

DROP TABLE IF EXISTS `recognition_statuses` CASCADE
;

DROP TABLE IF EXISTS `request_photos` CASCADE
;

DROP TABLE IF EXISTS `roles` CASCADE
;

DROP TABLE IF EXISTS `user_credentials` CASCADE
;

DROP TABLE IF EXISTS `users` CASCADE
;

/* Create Tables */

CREATE TABLE `articles`
(
	`article_id` INT NOT NULL AUTO_INCREMENT,
	`article_text` TEXT NOT NULL,
	CONSTRAINT `PK_articles` PRIMARY KEY (`article_id` ASC)
)

;

CREATE TABLE `articles_gps_tags`
(
	`tag_id` INT NOT NULL,
	`article_id` INT NOT NULL,
	CONSTRAINT `PK_articles_gps_tags` PRIMARY KEY (`article_id` ASC, `tag_id` ASC)
)

;

CREATE TABLE `edible_statuses`
(
	`edible_status_alias` ENUM('edible', 'partial-edible', 'non-edible') NOT NULL,
	`edible_description` VARCHAR(16) NOT NULL,
	`edible_status_id` INT NOT NULL AUTO_INCREMENT,
	CONSTRAINT `PK_edible_statuses` PRIMARY KEY (`edible_status_id` ASC)
)

;

CREATE TABLE `gps_tags`
(
	`tag_id` INT NOT NULL AUTO_INCREMENT,
	`latitude_seconds` INT NOT NULL,
	`longitude_seconds` INT NOT NULL,
	CONSTRAINT `PK_gps_tags` PRIMARY KEY (`tag_id` ASC)
)

;

CREATE TABLE `recognition_requests`
(
	`request_id` INT NOT NULL AUTO_INCREMENT,
	`request_datetime` DATETIME NOT NULL,
	`requester_id` INT NOT NULL,
	`status_id` INT NOT NULL,
	`edible_status_id` INT NULL,
	CONSTRAINT `PK_recognition_request` PRIMARY KEY (`request_id` ASC)
)

;

CREATE TABLE `recognition_statuses`
(
	`status_alias` ENUM('recognized', 'not-recognized') NOT NULL,
	`status_name` VARCHAR(16) NOT NULL,
	`status_id` INT NOT NULL AUTO_INCREMENT,
	CONSTRAINT `PK_request_statuses` PRIMARY KEY (`status_id` ASC)
)

;

CREATE TABLE `request_photos`
(
	`photo_id` INT NOT NULL AUTO_INCREMENT,
	`photo_filename` VARCHAR(128) NOT NULL,
	`request_id` INT NOT NULL,
	CONSTRAINT `PK_request_photo` PRIMARY KEY (`photo_id` ASC)
)

;

CREATE TABLE `roles`
(
	`role_alias` ENUM('user', 'admin') NOT NULL,
	`role_name` VARCHAR(16) NOT NULL,
	`role_id` INT NOT NULL AUTO_INCREMENT,
	CONSTRAINT `PK_roles` PRIMARY KEY (`role_id` ASC)
)

;

CREATE TABLE `user_credentials`
(
	`user_mail` VARCHAR(50) NOT NULL,
	`user_password_hash` VARCHAR(128) NOT NULL,
	`user_id` INT NOT NULL,
	CONSTRAINT `PK_user_credentials` PRIMARY KEY (`user_id` ASC)
)

;

CREATE TABLE `users`
(
	`user_id` INT NOT NULL AUTO_INCREMENT,
	`role_id` INT NOT NULL DEFAULT 0,
	CONSTRAINT `PK_users` PRIMARY KEY (`user_id` ASC)
)

;

/* Create Primary Keys, Indexes, Uniques, Checks */

ALTER TABLE `articles` 
 ADD UNIQUE INDEX `IX_article_id` (`article_id` ASC)
;

ALTER TABLE `articles_gps_tags` 
 ADD INDEX `IXFK_articles_gps_tags_gps_tags` (`tag_id` ASC)
;

ALTER TABLE `edible_statuses` 
 ADD UNIQUE INDEX `IX_edible_status_id` (`edible_status_id` ASC)
;

ALTER TABLE `edible_statuses` 
 ADD UNIQUE INDEX `IX_edible_status_alias` (`edible_status_alias` ASC)
;

ALTER TABLE `gps_tags` 
 ADD UNIQUE INDEX `IX_gps_tags` (`tag_id` ASC)
;

ALTER TABLE `gps_tags` 
 ADD INDEX `IX_latitude_seconds` (`latitude_seconds` ASC)
;

ALTER TABLE `gps_tags` 
 ADD INDEX `IX_longitude_seconds` (`longitude_seconds` ASC)
;

ALTER TABLE `recognition_requests` 
 ADD INDEX `IXFK_recognition_request_users` (`requester_id` ASC)
;

ALTER TABLE `recognition_requests` 
 ADD INDEX `IXFK_recognition_requests_edible_statuses` (`edible_status_id` ASC)
;

ALTER TABLE `recognition_requests` 
 ADD INDEX `IXFK_recognition_requests_recognition_statuses` (`status_id` ASC)
;

ALTER TABLE `recognition_requests` 
 ADD INDEX `IX_request_id` (`request_id` ASC)
;

ALTER TABLE `recognition_requests` 
 ADD UNIQUE INDEX `IX_request_datetime` (`request_datetime` ASC)
;

DROP FUNCTION IF EXISTS `check_datetime`
;

DROP TRIGGER IF EXISTS `TRG_check_insert_datetime`
;

DROP TRIGGER IF EXISTS `TRG_check_update_datetime`
;

DELIMITER //
CREATE FUNCTION check_datetime(new_datetime DATETIME)
	RETURNS BOOLEAN
	NOT DETERMINISTIC
	NO SQL
BEGIN
	RETURN new_datetime <= NOW();
END;

CREATE TRIGGER TRG_check_insert_datetime BEFORE INSERT ON recognition_requests
FOR EACH ROW
BEGIN
	IF NOT check_datetime(NEW.request_datetime) THEN
		SIGNAL SQLSTATE '45000'
			SET MESSAGE_TEXT = 'Datetime is from future',
			MYSQL_ERRNO = 1001;
	END IF;
END;

CREATE TRIGGER TRG_check_update_datetime BEFORE UPDATE ON recognition_requests
FOR EACH ROW
BEGIN
	IF NOT check_datetime(NEW.request_datetime) THEN
		SIGNAL SQLSTATE '45000'
			SET MESSAGE_TEXT = 'New datetime is from future',
			MYSQL_ERRNO = 1001;
	END IF;
END; 
//
DELIMITER ;
;

DROP TRIGGER IF EXISTS `TRG_check_insert_gps_tag`
;

DROP TRIGGER IF EXISTS `TRG_check_update_gps_tag`
;

DELIMITER //

CREATE TRIGGER TRG_check_insert_gps_tag BEFORE INSERT ON gps_tags
FOR EACH ROW
BEGIN
	DECLARE max_latitude INT UNSIGNED;
	DECLARE max_longitude INT UNSIGNED;
	SET max_latitude = 90 * 60 * 60;
	SET max_longitude = 180 * 60 * 60;
	IF NEW.latitude_seconds < -max_latitude OR NEW.latitude_seconds > max_latitude OR NEW.longitude_seconds < -max_longitude OR NEW.longitude_seconds > max_longitude THEN
		SIGNAL SQLSTATE '45000'
			SET MESSAGE_TEXT = 'Not existing place',
			MYSQL_ERRNO = 1001;
	END IF;
END;

CREATE TRIGGER TRG_check_update_gps_tag BEFORE UPDATE ON gps_tags
FOR EACH ROW
BEGIN
	DECLARE max_latitude INT UNSIGNED;
	DECLARE max_longitude INT UNSIGNED;
	SET max_latitude = 90 * 60 * 60;
	SET max_longitude = 180 * 60 * 60;
	IF NEW.latitude_seconds < -max_lattitude OR NEW.latitude_seconds > max_lattitude OR NEW.longitude_seconds < -max_longitude OR NEW.longitude_seconds > max_longitude THEN
		SIGNAL SQLSTATE '45000'
			SET MESSAGE_TEXT = 'Not existing place',
			MYSQL_ERRNO = 1001;
	END IF;
END; 
//
DELIMITER ;
;

ALTER TABLE `recognition_statuses` 
 ADD UNIQUE INDEX `IX_status_id` (`status_id` ASC)
;

ALTER TABLE `recognition_statuses` 
 ADD UNIQUE INDEX `IX_status_alias` (`status_alias` ASC)
;

ALTER TABLE `request_photos` 
 ADD INDEX `IXFK_request_photo_recognition_request` (`request_id` ASC)
;

ALTER TABLE `roles` 
 ADD UNIQUE INDEX `IX_role_alias` (`role_alias` ASC)
;

ALTER TABLE `roles` 
 ADD UNIQUE INDEX `IX_role_id` (`role_id` ASC)
;

ALTER TABLE `user_credentials` 
 ADD UNIQUE INDEX `IXFK_user_credentials_users` (`user_id` ASC)
;

ALTER TABLE `user_credentials` 
 ADD UNIQUE INDEX `IX_user_mail` (`user_mail` ASC)
;

DROP TRIGGER IF EXISTS `TRG_restrict_delete`
;

DELIMITER //
CREATE TRIGGER TRG_restrict_delete BEFORE DELETE ON user_credentials
FOR EACH ROW 
	SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'Credentials delete not allowed',
		MYSQL_ERRNO = 1001; 
//
DELIMITER ;
;

ALTER TABLE `users` 
 ADD INDEX `IXFK_users_roles` (`role_id` ASC)
;

ALTER TABLE `users` 
 ADD UNIQUE INDEX `IX_user_id` (`user_id` ASC)
;

DROP FUNCTION IF EXISTS `get_admin_role_id`
;

DROP FUNCTION IF EXISTS `get_user_role_id`
;

DROP FUNCTION IF EXISTS `is_single_admin_left`
;

DROP TRIGGER IF EXISTS `TRG_restrict_delete_last_admin`
;

DROP TRIGGER IF EXISTS `TRG_restrict_transfer_last_admin_to_users`
;

DELIMITER //
CREATE FUNCTION get_admin_role_id()
	RETURNS INT
	NOT DETERMINISTIC
	READS SQL DATA
BEGIN
	DECLARE admin_id INT;
	SET admin_id = (SELECT role_id FROM roles WHERE role_alias = 'admin');
	RETURN admin_id;
END;

CREATE FUNCTION get_user_role_id()
	RETURNS INT
	NOT DETERMINISTIC
	READS SQL DATA
BEGIN
	DECLARE user_id INT;
	SET user_id = (SELECT role_id FROM roles WHERE role_alias = 'user');
	RETURN user_id;
END;

CREATE FUNCTION is_single_admin_left()
	RETURNS BOOLEAN
	NOT DETERMINISTIC
	READS SQL DATA
BEGIN
	DECLARE admin_id INT;
	SET admin_id = get_admin_role_id();
	RETURN (SELECT COUNT(*) FROM users WHERE role_id = admin_id) = 1;
END;

CREATE TRIGGER TRG_restrict_delete_last_admin BEFORE DELETE ON users
FOR EACH ROW
BEGIN
	IF OLD.role_id = get_admin_role_id() AND is_single_admin_left() THEN
		SIGNAL SQLSTATE '45000'
			SET MESSAGE_TEXT = 'Cannot delete last admin',
			MYSQL_ERRNO = 1001;
	END IF;
END;

CREATE TRIGGER TRG_restrict_transfer_last_admin_to_users BEFORE UPDATE ON users
FOR EACH ROW
BEGIN
	DECLARE admin_id INT;
	SET admin_id = get_admin_role_id();
	IF OLD.role_id = admin_id AND NEW.role_id != admin_id AND is_single_admin_left() THEN
		SIGNAL SQLSTATE '45000'
			SET MESSAGE_TEXT = 'Cannot transfer last admin to users',
			MYSQL_ERRNO = 1001;
	END IF;
END; 
//
DELIMITER ;
;

/* Create Foreign Key Constraints */

ALTER TABLE `articles_gps_tags` 
 ADD CONSTRAINT `FK_articles_gps_tags_articles`
	FOREIGN KEY (`article_id`) REFERENCES `articles` (`article_id`) ON DELETE Cascade ON UPDATE Cascade
;

ALTER TABLE `articles_gps_tags` 
 ADD CONSTRAINT `FK_articles_gps_tags_gps_tags`
	FOREIGN KEY (`tag_id`) REFERENCES `gps_tags` (`tag_id`) ON DELETE Cascade ON UPDATE Cascade
;

ALTER TABLE `recognition_requests` 
 ADD CONSTRAINT `FK_recognition_request_users`
	FOREIGN KEY (`requester_id`) REFERENCES `users` (`user_id`) ON DELETE Cascade ON UPDATE Cascade
;

ALTER TABLE `recognition_requests` 
 ADD CONSTRAINT `FK_recognition_requests_edible_statuses`
	FOREIGN KEY (`edible_status_id`) REFERENCES `edible_statuses` (`edible_status_id`) ON DELETE Restrict ON UPDATE Cascade
;

ALTER TABLE `recognition_requests` 
 ADD CONSTRAINT `FK_recognition_requests_recognition_statuses`
	FOREIGN KEY (`status_id`) REFERENCES `recognition_statuses` (`status_id`) ON DELETE Restrict ON UPDATE Cascade
;

ALTER TABLE `request_photos` 
 ADD CONSTRAINT `FK_request_photo_recognition_request`
	FOREIGN KEY (`request_id`) REFERENCES `recognition_requests` (`request_id`) ON DELETE Cascade ON UPDATE Cascade
;

ALTER TABLE `user_credentials` 
 ADD CONSTRAINT `FK_user_credentials_users`
	FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE Cascade ON UPDATE Cascade
;

ALTER TABLE `users` 
 ADD CONSTRAINT `FK_users_roles`
	FOREIGN KEY (`role_id`) REFERENCES `roles` (`role_id`) ON DELETE Restrict ON UPDATE Cascade
;

SET FOREIGN_KEY_CHECKS=1 
;
