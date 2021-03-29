DROP DATABASE IF EXISTS sql_test;

CREATE DATABASE sql_test;

USE sql_test;

CREATE TABLE test_table(
        id INT PRIMARY KEY AUTO_INCREMENT,
        test_field VARCHAR(250) NOT NULL DEFAULT ''
);


INSERT INTO test_table(test_field) VALUES('test1');
INSERT INTO test_table(test_field) VALUES('test2');
INSERT INTO test_table(test_field) VALUES('test3');