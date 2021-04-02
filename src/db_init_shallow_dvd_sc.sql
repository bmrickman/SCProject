DROP DATABASE IF EXISTS sc;
CREATE DATABASE sc;
USE sc;

CREATE PROCEDURE sc.log(
	IN status   VARCHAR(32),
	IN activity VARCHAR(128)
)
BEGIN

	CREATE TABLE IF NOT EXISTS sc.activity_log(
		status   VARCHAR(32),
		activity VARCHAR(128),
		log_time TIMESTAMP
	);

	INSERT INTO sc.activity_log VALUES(status, activity, NOW());
END;


CREATE PROCEDURE sc.build_shallow_vg_sc(
	IN nproducts        		 INT(11),
	IN nsales_locations 		 INT(11),
	IN n_build_and_buy_locations INT(11)
)
BEGIN

	DECLARE loopInd INT(11);
	DECLARE fin_prod_id INT(11);
	DECLARE build_id_1 INT(11);
	DECLARE build_id_2 INT(11);
	DECLARE build_id_3  INT(11);
	DECLARE curmax     INT(11);

	CALL sc.log('BEGIN', 'build_shallow_vg_sc');

	DROP TABLE IF EXISTS sc.products;
	CREATE TABLE sc.products(
		product_id INT(11) PRIMARY KEY,
		product_name VARCHAR(128),
		is_buyable BOOL,
		is_sellable BOOL,
		is_buildable BOOL
	);

	DROP TABLE IF EXISTS sc.product_construction;
	CREATE TABLE sc.product_construction(
		build_id INT(11),
		to_product_id INT(11),
		from_product_id INT(11),
		amt INT(11)
	);

	DROP TABLE IF EXISTS sc.locations;
	CREATE TABLE sc.locations(
		location_id INT(11) PRIMARY KEY, # AUTO_INCREMENT PRIMARY KEY,
		location_address VARCHAR(256),
		location_type VARCHAR(32)

	);


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

	DROP TABLE IF EXISTS sc.ship_routes;
	CREATE TABLE sc.ship_routes(
	    ship_route_id INT(11),
	    from_id       INT(11),
	    to_id         INT(11)
	);

	DROP TABLE IF EXISTS sc.sales;
	CREATE TABLE sc.sales(
	    product_id  INT(11),
	    location_id INT(11),
	    sale_date   DATE,
	    sale_amt    INT(11)
	);



	## BUILD ALL SALES LOCATIONS
	CALL sc.log('BEGIN', 'BUILD SALES LOCATIONS');
	SET loopInd  = 1;
	WHILE loopInd < nsales_locations DO

		INSERT INTO sc.locations(location_id, location_address, location_type)
	    VALUES (loopInd, CONCAT(CONVERT(FLOOR(RAND()*100000), CHAR), ' Fake Addr Drive'), 'S');
	    SET loopInd = loopInd + 1;

	END WHILE;
	CALL sc.log('END', 'BUILD SALES LOCATIONS');


	## BUILD ALL BUILD AND BUY LOCATIONS
	CALL sc.log('BEGIN', 'BUILD BB LOCATIONS');
	SET loopInd  = 1;
	WHILE loopInd < n_build_and_buy_locations DO

	    INSERT INTO sc.locations(location_id, location_address, location_type)
	    VALUES (loopInd+nsales_locations, CONCAT(CONVERT(FLOOR(RAND()*100000), CHAR), ' Fake Addr Drive'), 'BB');
	    SET loopInd = loopInd + 1;

	END WHILE;
	CALL sc.log('END', 'BUILD BB LOCATIONS');


    ## BUILD ALL SHIPMENT PATHS
    CALL sc.log('BEGIN', 'BUILD SHIP ROUTES');

    INSERT INTO sc.ship_routes(ship_route_id, from_id, to_id)
    SELECT sloc.location_id*bbloc.location_id, bbloc.location_id, sloc.location_id
      FROM sc.locations sloc,
      	   sc.locations bbloc
     WHERE sloc.location_type = 'S'
       AND bbloc.location_type = 'BB';

    CALL sc.log('END', 'BUILD SHIP ROUTES');



	## BUILD ALL PRODUCTS
	CALL sc.log('BEGIN', 'BUILD PRODUCTS');

	SET loopInd  = 1;
	WHILE loopInd <= nproducts DO

		SET fin_prod_id = 4*loopInd-3;
		SET build_id_1  = 4*loopInd-2;
		SET build_id_2  = 4*loopInd-1;
		SET build_id_3  = 4*loopInd;

		INSERT INTO sc.products(product_id, product_name, is_buyable, is_sellable, is_buildable)
		VALUES (fin_prod_id, CONCAT('Game ',              fin_prod_id), 0, 1, 1),
		       (build_id_1,  CONCAT('Sleeve for Product ',fin_prod_id),  1, 0, 0),
		       (build_id_2,  CONCAT('Disk for Product ',fin_prod_id),    1, 0, 0),
		       (build_id_3,  CONCAT('Game for Product ',fin_prod_id),    1, 0, 0);

		INSERT INTO sc.product_construction(build_id,to_product_id,from_product_id, amt)
		VALUES (loopInd, fin_prod_id, build_id_1, 1),
		       (loopInd, fin_prod_id, build_id_2, 1),
		       (loopInd, fin_prod_id, build_id_3, 1);


	    SET loopInd = loopInd + 1;

	END WHILE;
	CALL sc.log('END', 'BUILD PRODUCTS');



	## BUILD PRODUCT LOCATIONS
	CALL sc.log('BEGIN','BUILD PROD LOC');
    ## Initialize inventory to 0.  Let the sales generation logic pick current inventory
	INSERT INTO sc.product_location
	(id, product_id, location_id, inventory, is_buyable, is_sellable, is_buildable, is_active)
	SELECT @l_seq := @l_seq + 1, product_id, location_id, 0, 0,1,0,1
	  FROM sc.locations,
	  	   sc.products,
	  	   (SELECT @l_seq := 0) l_seq
	 WHERE location_type        = 'S'
	   AND products.is_sellable = TRUE
	 ORDER BY product_id ASC, location_id ASC;

	SELECT MAX(id)
      INTO curmax
      FROM sc.product_location;

	INSERT INTO sc.product_location
	(id, product_id, location_id, inventory, is_buyable, is_sellable, is_buildable, is_active)
	SELECT @l_seq := @l_seq + 1, product_id, location_id, 0, 0,1,0,1
	  FROM sc.locations,
	  	   sc.products,
	  	   (SELECT @l_seq := curmax) l_seq
	 WHERE location_type        = 'BB'
	   AND products.is_buildable = TRUE
	  ORDER BY product_id ASC, location_id ASC;

	CALL sc.log('END','BUILD PROD LOC');
    CALL sc.log('END', 'build_shallow_vg_sc');

END;


