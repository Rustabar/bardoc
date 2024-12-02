-- DROP DATABASE IF EXISTS zedoc;
--su - postgres
--dropdb bardoc
-- createdb bardoc

CREATE DATABASE bardoc
    WITH
    OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'en_US.UTF-8'
    LC_CTYPE = 'en_US.UTF-8'
    LOCALE_PROVIDER = 'libc'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1
    IS_TEMPLATE = False;

--\c bardoc

drop table if exists prod.product_vers;
drop table if exists prod.product;

drop table if exists doc.content;
drop table if exists doc.doc_file;
drop table if exists doc.doc_vers;
drop table if exists doc.doc;
drop table if exists doc.tag;

drop schema if exists prod;
drop schema if exists doc;

--####################################################################################################################
--####################################################################################################################
--###########################                     Схема продукта                        ##############################
--####################################################################################################################
--####################################################################################################################

create schema prod;

--##############################################################
--##                       Продукт
--##############################################################

CREATE TABLE IF NOT EXISTS prod.product
(
    prod_id integer NOT NULL DEFAULT nextval('prod.product_prod_id_seq'::regclass),
    prod_name character varying(256) COLLATE pg_catalog."default" NOT NULL,
    prod_code character varying(100) COLLATE pg_catalog."default" NOT NULL,
    prod_created_at timestamp without time zone DEFAULT now(),
    prod_modified_at timestamp without time zone DEFAULT now()
) TABLESPACE pg_default;

COMMENT ON TABLE prod.product IS 'Продукт.';

ALTER TABLE IF EXISTS prod.product
    ADD CONSTRAINT product_pkey PRIMARY KEY (prod_id);

ALTER TABLE IF EXISTS prod.product
    ADD CONSTRAINT product_prod_code_key UNIQUE (prod_code);

ALTER TABLE IF EXISTS prod.product
    ADD CONSTRAINT product_prod_name_key UNIQUE (prod_name);

--##############################################################
--##                    Версия продукта
--##############################################################

CREATE TABLE IF NOT EXISTS prod.product_vers
(
    prod_vers_id integer NOT NULL DEFAULT nextval('prod.product_vers_prod_vers_id_seq'::regclass),
    prod_id integer NOT NULL,
    prod_vers_name character varying(256) COLLATE pg_catalog."default" NOT NULL,
    prod_vers_num character varying(100) COLLATE pg_catalog."default" NOT NULL,
    prod_vers_created_at timestamp without time zone DEFAULT now(),
    prod_vers_modified_at timestamp without time zone DEFAULT now()
) TABLESPACE pg_default;

COMMENT ON TABLE prod.product_vers IS 'Версия продукта.';

ALTER TABLE IF EXISTS prod.product_vers
    ADD CONSTRAINT product_vers_pkey PRIMARY KEY (prod_vers_id);

ALTER TABLE IF EXISTS prod.product_vers
    ADD CONSTRAINT product_vers_prod_id_fkey FOREIGN KEY (prod_id)
    REFERENCES prod.product (prod_id) MATCH SIMPLE;

ALTER TABLE IF EXISTS prod.product_vers
    ADD CONSTRAINT product_vers_prod_vers_name_key UNIQUE (prod_vers_name);

ALTER TABLE IF EXISTS prod.product_vers
    ADD CONSTRAINT product_vers_prod_vers_num_key UNIQUE (prod_vers_num);

--####################################################################################################################
--####################################################################################################################
--###########################                     Схема документации                    ##############################
--####################################################################################################################
--####################################################################################################################

create schema doc;

--##############################################################
--##                 Документация
--##############################################################

CREATE TABLE IF NOT EXISTS doc.doc
(
    doc_id integer NOT NULL DEFAULT nextval('doc.doc_doc_id_seq'::regclass),
    prod_id integer NOT NULL,
    doc_name character varying(256) COLLATE pg_catalog."default" NOT NULL,
    doc_descr character varying(1000) COLLATE pg_catalog."default",
    doc_created_at timestamp without time zone DEFAULT now(),
    doc_modified_at timestamp without time zone DEFAULT now()
) TABLESPACE pg_default;

ALTER TABLE IF EXISTS doc.doc
    ADD CONSTRAINT doc_pkey PRIMARY KEY (doc_id);

ALTER TABLE IF EXISTS doc.doc
    ADD CONSTRAINT doc_prod_id_fkey FOREIGN KEY (prod_id)
    REFERENCES prod.product (prod_id) MATCH SIMPLE;

COMMENT ON TABLE doc.doc IS 'Документация.';

--##############################################################
--##                 Версия документации
--##############################################################

CREATE TABLE IF NOT EXISTS doc.doc_vers
(
    doc_vers_id integer NOT NULL DEFAULT nextval('doc.doc_vers_doc_vers_id_seq'::regclass),
    doc_id integer NOT NULL,
    prod_vers_id integer NOT NULL,
    doc_vers_num character varying(100) COLLATE pg_catalog."default" NOT NULL,
    doc_vers_descr character varying(1000) COLLATE pg_catalog."default",
    doc_vers_created_at timestamp without time zone DEFAULT now(),
    doc_vers_modified_at timestamp without time zone DEFAULT now()
) TABLESPACE pg_default;

ALTER TABLE IF EXISTS doc.doc_vers
    ADD CONSTRAINT doc_vers_pkey PRIMARY KEY (doc_vers_id);

ALTER TABLE IF EXISTS doc.doc_vers
    ADD CONSTRAINT doc_vers_prod_vers_id_fkey FOREIGN KEY (prod_vers_id)
    REFERENCES prod.product_vers (prod_vers_id) MATCH SIMPLE;

ALTER TABLE IF EXISTS doc.doc_vers
    ADD CONSTRAINT doc_vers_doc_id_fkey FOREIGN KEY (doc_id)
    REFERENCES doc.doc (doc_id) MATCH SIMPLE;
	
COMMENT ON TABLE doc.doc_vers IS 'Версия документации.';

--##############################################################
--##                 Загружаемые файлы
--##############################################################

CREATE TABLE IF NOT EXISTS doc.doc_file
(
    doc_file_id integer NOT NULL DEFAULT nextval('doc.file_file_id_seq'::regclass),
    doc_file_name text COLLATE pg_catalog."default" NOT NULL,
    doc_file_abspath text COLLATE pg_catalog."default" NOT NULL,
    doc_file_relpath text COLLATE pg_catalog."default",
    doc_vers_id integer NOT NULL,
    doc_file_created_at timestamp without time zone DEFAULT now(),
    doc_file_modified_at timestamp without time zone DEFAULT now()
) TABLESPACE pg_default;

COMMENT ON TABLE doc.doc_file IS 'Файлы загрузочные.';

ALTER TABLE IF EXISTS doc.doc_file
    ADD CONSTRAINT doc_file_pkey PRIMARY KEY (doc_file_id);

ALTER TABLE IF EXISTS doc.doc_file
    ADD CONSTRAINT doc_file_doc_vers_id_fkey FOREIGN KEY (doc_vers_id)
    REFERENCES doc.doc_vers (doc_vers_id) MATCH SIMPLE;
	
--##############################################################
--##                 Справочник тегов
--##############################################################

create table doc.tag (
  tag_id serial primary key
, tag_name varchar(100) not null unique
);
COMMENT ON TABLE doc.tag IS 'Справочник тегов.';

--##############################################################
--##                 Результаты парсинга
--##############################################################

CREATE TABLE IF NOT EXISTS doc.content
(
    cont_id integer NOT NULL DEFAULT nextval('doc.content_cont_id_seq'::regclass),
    cont_idp integer,
    doc_file_id integer,
    tag_id integer,
    content text COLLATE pg_catalog."default",
    cont_lvl integer,
    cont_created_at timestamp without time zone DEFAULT now(),
    cont_modified_at timestamp without time zone DEFAULT now()
) TABLESPACE pg_default;

COMMENT ON TABLE doc.content IS 'Результат парсинга файлов.';

ALTER TABLE IF EXISTS doc.content
    ADD CONSTRAINT content_pkey PRIMARY KEY (cont_id);

ALTER TABLE IF EXISTS doc.content
    ADD CONSTRAINT content_doc_file_id_fkey FOREIGN KEY (doc_file_id)
    REFERENCES doc.doc_file (doc_file_id) MATCH SIMPLE;

ALTER TABLE IF EXISTS doc.content
    ADD CONSTRAINT content_tag_id_fkey FOREIGN KEY (tag_id)
    REFERENCES doc.tag (tag_id) MATCH SIMPLE;



