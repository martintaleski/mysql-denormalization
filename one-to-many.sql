# drop tables if exist
drop table if exists article_image;
drop table if exists article;
drop procedure if exists denormalize_article_images;


# blog article table
CREATE TABLE `article` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `title` varchar(45) NOT NULL,
  `images` text null,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB;

# article image table, linked to article by article_id
 CREATE TABLE `article_image` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `article_id` int(11) NOT NULL,
  `title` varchar(45) NOT NULL,
  `local_image_path` varchar(255) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_article_image_1` (`article_id`),
  CONSTRAINT `fk_article_image_1` FOREIGN KEY (`article_id`) REFERENCES `article` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

# procedure for denormalization
# it takes the article id as a parameter, 
# fetches all the images for that article
# and stores them in a json format on the article table record
DELIMITER $$

CREATE PROCEDURE `denormalize_article_images`(IN in_article_id int(11))
BEGIN
	DECLARE json_images TEXT DEFAULT '[';
	DECLARE v_image_id int(11);
	DECLARE v_local_image_path varchar(255);

	DECLARE v_finished INTEGER DEFAULT 0;

	DECLARE images_cursor CURSOR FOR
	select `id`,`local_image_path` from `article_image` where `article_id`=in_article_id;

	-- declare NOT FOUND handler
	DECLARE CONTINUE HANDLER 
		FOR NOT FOUND SET v_finished = 1;
	
	OPEN images_cursor;
	get_images: LOOP
		FETCH images_cursor INTO v_image_id, v_local_image_path;

		IF v_finished = 1 THEN 
			LEAVE get_images;
		END IF;

		set json_images = CONCAT(json_images,'{','"id":',v_image_id,',"local_image_path":"',v_local_image_path,'"},');

	END LOOP get_images;
	
	CLOSE images_cursor;
	set json_images = CONCAT(TRIM(BOTH ',' FROM json_images),']');
	update `article` set `images` = json_images where `id` = in_article_id;

END
$$
DELIMITER ;

# trigger after delete on article image to call denormalize procedure
DELIMITER $$
CREATE TRIGGER `denormalize_images_delete` AFTER DELETE ON `article_image`
 FOR EACH ROW BEGIN
    call denormalize_article_images(OLD.article_id);

  END
$$
DELIMITER ;

# trigger after insert on article image to call denormalize procedure
DELIMITER $$
CREATE TRIGGER `denormalize_images_insert` AFTER INSERT ON `article_image`
 FOR EACH ROW BEGIN
    call denormalize_article_images(NEW.article_id);

  END
$$
DELIMITER ;

# trigger after update on article image to call denormalize procedure
DELIMITER $$
CREATE TRIGGER `denormalize_images_update` AFTER UPDATE ON `article_image`
 FOR EACH ROW BEGIN
    call denormalize_article_images(NEW.article_id);

  END
$$
DELIMITER ;


# insert statements for testing
insert into article (id, title) values (1,'first article'),(2,'third article'),(3,'second article');
insert into article_image (article_id, title, local_image_path) values 
(1,'first article image 1','article_1_image_1.jpg'),
(1,'first article image 2','article_1_image_2.jpg'),
(1,'first article image 3','article_1_image_3.jpg'),
(2,'first article image 1','article_2_image_1.jpg'),
(2,'first article image 2','article_2_image_2.jpg');



