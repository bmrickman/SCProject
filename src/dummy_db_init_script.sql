DROP DATABASE IF EXISTS sc;
CREATE DATABASE sc;

USE sc;

CREATE TABLE sc.products(
	product_id INT(11) PRIMARY KEY, # AUTO_INCREMENT PRIMARY KEY,
	product_name VARCHAR(128),
	is_buyable BOOL,
	is_sellable BOOL,
	is_buildable BOOL
);

INSERT INTO sc.products(product_id, product_name, is_buyable, is_sellable, is_buildable)
VALUES
(1, 'The Witcher 3: Wild Hunt - Game', 0,1,1),
(2, 'Pokemon Red Version - Game', 0,1,1),
(3, 'Minecraft - Game', 0,1,1),
(4, 'Grand Theft Auto V - Game', 0,1,1),
(5, 'Red Dead Redemption - Game', 0,1,1),
(6, 'The Legend of Zelda: Breathe Of The Wild - Game', 0,1,1),
(7, 'The Last Of Us - Game', 0,1,1),
(8, 'God Of War - Game', 0,1,1),

(11, 'The Witcher 3: Wild Hunt - Sleeve', 1,0,0),
(12, 'Pokemon Red Version - Sleeve', 1,0,0),
(13, 'Minecraft - Sleeve', 1,0,0),
(14, 'Grand Theft Auto V - Sleeve', 1,0,0),
(15, 'Red Dead Redemption - Sleeve', 1,0,0),
(16, 'The Legend of Zelda: Breathe Of The Wild - Sleeve', 1,0,0),
(17, 'The Last Of Us - Sleeve', 1,0,0),
(18, 'God Of War - Sleeve', 1,0,0),

(21, 'The Witcher 3: Wild Hunt - Disk', 1,0,0),
(22, 'Pokemon Red Version - Disk', 1,0,0),
(23, 'Minecraft - Disk', 1,0,0),
(24, 'Grand Theft Auto V - Disk', 1,0,0),
(25, 'Red Dead Redemption - Disk', 1,0,0),
(26, 'The Legend of Zelda: Breathe Of The Wild - Disk', 1,0,0),
(27, 'The Last Of Us - Disk', 1,0,0),
(28, 'God Of War - Disk', 1,0,0),

(30, 'Disk Case', 1,0,0);

DROP TABLE IF EXISTS sc.product_construction;
CREATE TABLE sc.product_construction(
build_id INT(11),
to_product_id INT(11),
from_product_id INT(11),
amt INT(11)
);

INSERT INTO sc.product_construction(build_id, to_product_id, from_product_id, amt)
SELECT game.product_id AS build_id,
	   game.product_id AS to_product_id,
	   disk.product_id AS from_product_id,
	   1 AS amt
  FROM
	(SELECT *
	  FROM sc.products
	 WHERE product_name LIKE '%- Game%') game,
	 (SELECT *
	   FROM sc.products
	  WHERE product_name LIKE '%- Disk%') disk
 WHERE SUBSTRING(game.product_name, 1,10) = SUBSTRING(disk.product_name,1,10);

INSERT INTO sc.product_construction(build_id, to_product_id, from_product_id, amt)
SELECT game.product_id AS build_id,
	   game.product_id AS to_product_id,
	   sleeve.product_id AS from_product_id,
	   1 AS amt
  FROM
	(SELECT *
	  FROM sc.products
	 WHERE product_name LIKE '%- Game%') game,
	 (SELECT *
	   FROM sc.products
	  WHERE product_name LIKE '%- Sleeve%') sleeve
 WHERE SUBSTRING(game.product_name, 1,10) = SUBSTRING(sleeve.product_name,1,10);



INSERT INTO sc.product_construction(build_id, to_product_id, from_product_id, amt)
SELECT product_id AS build_id,
	   product_id AS to_product_id,
	   30         AS from_product_id, -- disk case
	   1          AS amt
  FROM sc.products
 WHERE product_name LIKE '%- Game%';

# Validation
SELECT * FROM sc.product_construction ORDER BY build_id DESC;


DROP TABLE IF EXISTS sc.locations;
CREATE TABLE sc.locations(
	location_id INT(11) PRIMARY KEY, # AUTO_INCREMENT PRIMARY KEY,
	location_address VARCHAR(256),
	location_type VARCHAR(32)

);


DROP PROCEDURE IF EXISTS sc.generate_storefronts;
CREATE PROCEDURE sc.generate_storefronts()

BEGIN

  DECLARE v1 INT DEFAULT 1;
  DECLARE l_loc_ind INT(11);

  SET l_loc_ind = 0;
  # SELECT MAX(locatin_id) INTO l_loc_ind FROM sc.generate_storefronts;

  WHILE v1 < 10001 DO

    INSERT INTO sc.locations(location_id, location_address, location_type)
    VALUES (l_loc_ind+v1, CONCAT(CONVERT(FLOOR(RAND()*100000), CHAR), ' Fake Addr Drive'), 'S');
    SET v1 = v1 + 1;

  END WHILE;

END;



CALL sc.generate_storefronts();




DROP PROCEDURE IF EXISTS generate_warehouses;
CREATE PROCEDURE generate_warehouses()

BEGIN

  DECLARE v1 INT DEFAULT 1;
  DECLARE l_loc_ind INT(11);

  SELECT MAX(location_id) INTO l_loc_ind FROM sc.locations;

  WHILE v1 < 101 DO

    INSERT INTO sc.locations(location_id, location_address, location_type)
    VALUES (l_loc_ind+v1, CONCAT(CONVERT(FLOOR(RAND()*100000), CHAR), ' Fake Addr Drive'), 'W');
    SET v1 = v1 + 1;

  END WHILE;

END;


CALL sc.generate_warehouses();


DROP PROCEDURE IF EXISTS generate_build_locations;
CREATE PROCEDURE generate_build_locations()

BEGIN

  DECLARE v1 INT DEFAULT 1;
  DECLARE l_loc_ind INT(11);

  SELECT MAX(location_id) INTO l_loc_ind FROM sc.locations;

  WHILE v1 < 11 DO

    INSERT INTO sc.locations(location_id, location_address, location_type)
    VALUES (l_loc_ind+v1, CONCAT(CONVERT(FLOOR(RAND()*100000), CHAR), ' Fake Addr Drive'), 'B');
    SET v1 = v1 + 1;

  END WHILE;

END;

CALL generate_build_locations();



DROP TABLE IF EXISTS sc.product_location;
CREATE TABLE sc.product_location(
id INT(11), # AUTO_INCREMENT PRIMARY KEY,
product_id INT(11),
location_id INT(11),
inventory INT(11),
is_buyable BOOL,
is_sellable BOOL,
is_buildable BOOL,
is_active BOOL,
PRIMARY KEY(id),
UNIQUE KEY (product_id, location_id),
INDEX (is_active)
);

# In the future we will use python to generate random values, as it provides more robust random sampling methods.


INSERT INTO sc.product_location
	SELECT @l_seq := @l_seq + 1,
		   p.product_id,
		   l.location_id,
		   CASE
		   		WHEN location_type = 'S' THEN FLOOR(5+RAND()*(20-5)) # storefront inventory levels
		   		WHEN location_type = 'W' AND p.is_sellable = TRUE THEN FLOOR(50+RAND()*(200-50)) # warehouses housing major products
		   		WHEN location_type = 'B' AND p.is_sellable = TRUE THEN FLOOR(10+RAND()*(20-10)) # unshipped builds
		   		WHEN location_type = 'B' AND p.is_buyable = TRUE THEN FLOOR(50+RAND()*(200-50)) # pre-build values
		   END AS inventory,
		   CASE
		   		WHEN location_type = 'B' AND p.is_buildable = TRUE THEN TRUE
		   		ELSE FALSE
		   END AS is_buyable,
		   CASE
		   		WHEN location_type = 'S' AND p.is_sellable = TRUE THEN TRUE
		   		ELSE FALSE
		   END AS is_sellable,
		   CASE
		   		WHEN location_type = 'B' AND p.is_buildable = TRUE THEN TRUE
		   		ELSE FALSE
		   END AS is_buildable,
		   1
	  FROM sc.products p,
	       sc.locations l,
	       (SELECT @l_seq := 0) l_seq
	 WHERE (
	      	p.is_sellable = TRUE AND location_type = 'S' OR  #storefronts selling finished goods
	      	p.is_sellable = TRUE AND location_type = 'W' OR  # warehouses storing finished goods
	      	p.is_sellable = TRUE AND location_type = 'B' OR  # build locations housing finished builds
	      	p.is_buyable  = TRUE AND location_type = 'B' # Builders buying pre-sale items
	       );




CREATE TABLE sc.shipment(
ship_id       INT(11) PRIMARY KEY, # AUTO_INCREMENT PRIMARY KEY,
ship_ref_num  VARCHAR(256),
from_location INT(11),
to_location   INT(11),
product_id    INT(11),
amt           INT(11),
shipped_at    DATETIME,
arrived_at    DATETIME,
is_shipped    BOOL,
has_arrived   BOOL,
UNIQUE KEY(from_location, to_location, product_id),
INDEX sim_lookup(has_arrived)
)