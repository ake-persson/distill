SET storage_engine=InnoDB;
SET foreign_key_checks = 0;
SET character_set_client = utf8;

DROP DATABASE IF EXISTS distill;
CREATE DATABASE distill DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;

use distill

CREATE TABLE class (
    id                  SMALLINT UNSIGNED AUTO_INCREMENT NOT NULL,
    class               VARCHAR(25) NOT NULL,
    PRIMARY KEY (id)
);

CREATE TABLE parameter (
    id                  SMALLINT UNSIGNED AUTO_INCREMENT NOT NULL,
    parameter           VARCHAR(25) NOT NULL,
    PRIMARY KEY (id)
);

CREATE TABLE field (
    id                  INT UNSIGNED AUTO_INCREMENT NOT NULL,
    field               VARCHAR(50) NOT NULL,
    class_id            SMALLINT UNSIGNED NOT NULL,
    parameter_id        SMALLINT UNSIGNED NOT NULL,
    KEY idx_fk_class_id (class_id),
    KEY idx_fk_parameter_id (parameter_id),
    PRIMARY KEY (id),
    CONSTRAINT fk_field_class FOREIGN KEY (class_id) REFERENCES class (id),
    CONSTRAINT fk_field_parameter FOREIGN KEY (parameter_id) REFERENCES parameter (id)
);

CREATE TABLE category (
    id                  SMALLINT UNSIGNED AUTO_INCREMENT NOT NULL,
    category            VARCHAR(25) NOT NULL,
    sequence            TINYINT UNSIGNED NOT NULL,
    active              BOOLEAN,
    KEY idx_sequence (sequence),
    PRIMARY KEY (id)
);

CREATE TABLE value (
    id                  INT UNSIGNED AUTO_INCREMENT NOT NULL,
    value               VARCHAR(500) NOT NULL,
    field_id            INT UNSIGNED NOT NULL,
    category_id         SMALLINT UNSIGNED NOT NULL,
    last_update         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    KEY idx_fk_field_id (field_id),
    KEY idx_fk_category_id (category_id),
    PRIMARY KEY (id),
    CONSTRAINT fk_value_field FOREIGN KEY (field_id) REFERENCES field (id),
    CONSTRAINT fk_value_category FOREIGN KEY (category_id) REFERENCES category (id)
);

CREATE TABLE json_schema (
    id                  SMALLINT UNSIGNED AUTO_INCREMENT NOT NULL,
    json_schema         VARCHAR(500) NOT NULL,
    field_id            INT UNSIGNED NOT NULL,
    last_update         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    KEY idx_fk_field_id (field_id),
    PRIMARY KEY (id),
    CONSTRAINT fk_json_schema_field FOREIGN KEY (field_id) REFERENCES field (id)
);

CREATE TABLE host (
    id                  SMALLINT UNSIGNED AUTO_INCREMENT NOT NULL,
    host                VARCHAR(50) NOT NULL,
    active              BOOLEAN,
    PRIMARY KEY (id)
);

CREATE TABLE cache_field (
    cache_id            INT UNSIGNED NOT NULL,
    field_id            INT UNSIGNED NOT NULL,
    PRIMARY KEY (cache_id, field_id),
    CONSTRAINT fk_cache_field_cache FOREIGN KEY (cache_id) REFERENCES cache (id),
    CONSTRAINT fk_cache_field_field FOREIGN KEY (field_id) REFERENCES field (id)
);

CREATE TABLE cache (
    id                  INT UNSIGNED AUTO_INCREMENT NOT NULL,
    created             DATETIME NOT NULL,
    host_id             SMALLINT UNSIGNED NOT NULL,
    md5                 VARCHAR(32) NOT NULL,
    current             BOOLEAN,
    KEY idx_fk_host_id (host_id),
    PRIMARY KEY (id),
    CONSTRAINT fk_cache_host FOREIGN KEY (host_id) REFERENCES host (id)
);
