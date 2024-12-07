-- DROP DATABASE IF EXISTS zedoc;
--su - postgres
--dropdb bardoc
-- createdb bardoc
/*
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
*/
--\c bardoc

drop schema if exists doc cascade;
drop schema if exists prod cascade;

--####################################################################################################################
--####################################################################################################################
--###########################                     Схема продукта                        ##############################
--####################################################################################################################
--####################################################################################################################

create schema prod;

--##############################################################
--##                       Продукт
--##############################################################

CREATE TABLE IF NOT EXISTS prod.prod
(
    prod_id serial NOT NULL,
    prod_name character varying(256) COLLATE pg_catalog."default" NOT NULL,
    prod_code character varying(50) COLLATE pg_catalog."default" NOT NULL,
    prod_created_at timestamp without time zone DEFAULT now(),
    prod_modified_at timestamp without time zone DEFAULT now()
) TABLESPACE pg_default;

COMMENT ON TABLE prod.prod IS 'Продукт.';

ALTER TABLE IF EXISTS prod.prod
    ADD CONSTRAINT prod_pkey PRIMARY KEY (prod_id);
ALTER TABLE IF EXISTS prod.prod
    ADD CONSTRAINT prod_prod_code_key UNIQUE (prod_code);
ALTER TABLE IF EXISTS prod.prod
    ADD CONSTRAINT prod_prod_name_key UNIQUE (prod_name);

--########################################################################################################################################
--Добавить
CREATE OR REPLACE FUNCTION prod.prod_i(IN _prod_name character varying, IN _prod_code character varying)
    RETURNS integer AS
$BODY$
DECLARE
	lI_id 	integer := -1;
BEGIN
	insert into prod.prod(prod_name, prod_code) values ($1, $2) returning prod_id into lI_id;
	return lI_id;
EXCEPTION WHEN unique_violation THEN
	IF(SQLERRM ~* 'prod_prod_code_key')THEN
		RAISE NOTICE 'Product with this code already exists';
	ELSIF(SQLERRM ~* 'prod_prod_name_key')THEN
		RAISE NOTICE 'Product with this name already exists';
	ELSE
		RAISE NOTICE 'Illegal operation: %', SQLERRM;
	END IF;
	return lI_id;
END;
$BODY$
LANGUAGE 'plpgsql'
SECURITY DEFINER;

ALTER FUNCTION prod.prod_i(character varying, character varying)
    OWNER TO postgres;
COMMENT ON FUNCTION prod.prod_i(character varying, character varying)
    IS 'Добавить продукт';

--########################################################################################################################################
--Обновить
CREATE OR REPLACE FUNCTION prod.prod_u(IN _prod_id integer, IN _prod_name character varying, IN _prod_code character varying)
    RETURNS integer AS
$BODY$
DECLARE
	lI_id 	integer := -1;
BEGIN
	update prod.prod
	set prod_name = $2
	  , prod_code = $3
	where prod_id = $1;
	return _prod_id;
EXCEPTION WHEN unique_violation THEN
	IF(SQLERRM ~* 'prod_prod_code_key')THEN
		RAISE NOTICE 'Product with this code already exists';
	ELSIF(SQLERRM ~* 'prod_prod_name_key')THEN
		RAISE NOTICE 'Product with this name already exists';
	ELSE
		RAISE NOTICE 'Illegal operation: %', SQLERRM;
	END IF;
	return lI_id;
END;
$BODY$
LANGUAGE 'plpgsql'
SECURITY DEFINER;

ALTER FUNCTION prod.prod_u(integer, character varying, character varying)
    OWNER TO postgres;
COMMENT ON FUNCTION prod.prod_u(integer, character varying, character varying)
    IS 'Обновить продукт';

--########################################################################################################################################
--Удалить
CREATE OR REPLACE FUNCTION prod.prod_d(IN _prod_id integer)
    RETURNS integer AS
$BODY$
DECLARE
	lI_id 	integer := -1;
BEGIN
	DELETE FROM prod.prod
	where prod_id = $1;
	return _prod_id;
EXCEPTION WHEN OTHERS THEN
	RAISE NOTICE 'Illegal operation: %', SQLERRM;
	return lI_id;
END;
$BODY$
LANGUAGE 'plpgsql'
SECURITY DEFINER;

ALTER FUNCTION prod.prod_d(integer)
    OWNER TO postgres;
COMMENT ON FUNCTION prod.prod_d(integer)
    IS 'Удалить продукт';

CREATE FUNCTION prod.prod_id_by_code(IN _prod_code character varying)
    RETURNS integer
    LANGUAGE 'sql'
    STABLE
AS $BODY$
select prod_id from prod.prod where prod_code = $1;
$BODY$;

ALTER FUNCTION prod.prod_id_by_code(character varying)
    OWNER TO postgres;
COMMENT ON FUNCTION prod.prod_id_by_code(character varying)
    IS 'ID продукта по его коду.';

--##############################################################
--##                    Версия продукта
--##############################################################

CREATE TABLE IF NOT EXISTS prod.prod_vers
(
    prod_vers_id serial NOT NULL,
    prod_id integer NOT NULL,
    prod_vers_num character varying(50) COLLATE pg_catalog."default" NOT NULL,
    prod_vers_desc character varying(250) COLLATE pg_catalog."default" NOT NULL,
    prod_vers_created_at timestamp without time zone DEFAULT now(),
    prod_vers_modified_at timestamp without time zone DEFAULT now()
) TABLESPACE pg_default;

COMMENT ON TABLE prod.prod_vers IS 'Версия продукта.';

ALTER TABLE IF EXISTS prod.prod_vers
    ADD CONSTRAINT prod_vers_pkey PRIMARY KEY (prod_vers_id);
ALTER TABLE IF EXISTS prod.prod_vers
    ADD CONSTRAINT prod_vers_prod_id_fkey FOREIGN KEY (prod_id)
    REFERENCES prod.prod (prod_id) MATCH SIMPLE;
ALTER TABLE IF EXISTS prod.prod_vers
    ADD CONSTRAINT prod_vers_prod_vers_num_key UNIQUE (prod_vers_num);


--########################################################################################################################################
--Добавить
CREATE OR REPLACE FUNCTION prod.prod_vers_i(IN _prod_id integer, IN _prod_vers_num character varying, IN _prod_vers_desc character varying)
    RETURNS integer AS
$BODY$
DECLARE
	lI_id 	integer := -1;
BEGIN
	insert into prod.prod_vers(prod_id, prod_vers_num, prod_vers_desc) values ($1, $2, $3) returning prod_vers_id into lI_id;
	return lI_id;
EXCEPTION WHEN unique_violation THEN
	IF(SQLERRM ~* 'prod.prod_vers_prod_vers_num_key')THEN
		RAISE NOTICE 'Version for this product already exists.';
	ELSE
		RAISE NOTICE 'Illegal operation: %', SQLERRM;
	END IF;
	return lI_id;
END;
$BODY$
LANGUAGE 'plpgsql'
SECURITY DEFINER;

ALTER FUNCTION prod.prod_vers_i(integer, character varying, character varying)
    OWNER TO postgres;
COMMENT ON FUNCTION prod.prod_vers_i(integer, character varying, character varying)
    IS 'Добавить версию продукта';

--########################################################################################################################################
--Обновить
CREATE OR REPLACE FUNCTION prod.prod_vers_u(IN _prod_vers_id integer, IN _prod_id integer, IN _prod_vers_num character varying, IN _prod_vers_desc character varying)
    RETURNS integer AS
$BODY$
DECLARE
	lI_id 	integer := -1;
BEGIN
	update prod.prod_vers
	set prod_id = $2
	  , prod_vers_num = $3
	  , prod_vers_desc = $4
	where prod_vers_id = $1;
	return _prod_vers_id;
EXCEPTION WHEN unique_violation THEN
	IF(SQLERRM ~* 'prod.prod_vers_prod_vers_num_key')THEN
		RAISE NOTICE 'Version for this product already exists.';
	ELSE
		RAISE NOTICE 'Illegal operation: %', SQLERRM;
	END IF;
	return lI_id;
END;
$BODY$
LANGUAGE 'plpgsql'
SECURITY DEFINER;

ALTER FUNCTION prod.prod_vers_u(integer, integer, character varying, character varying)
    OWNER TO postgres;
COMMENT ON FUNCTION prod.prod_vers_u(integer, integer, character varying, character varying)
    IS 'Обновить версию продукта';

--########################################################################################################################################
--Удалить
CREATE OR REPLACE FUNCTION prod.prod_vers_d(IN _prod_vers_id integer)
    RETURNS integer AS
$BODY$
DECLARE
	lI_id 	integer := -1;
BEGIN
	DELETE FROM prod.prod_vers
	where prod_vers_id = $1;
	return _prod_vers_id;
EXCEPTION WHEN OTHERS THEN
	RAISE NOTICE 'Illegal operation: %', SQLERRM;
	return lI_id;
END;
$BODY$
LANGUAGE 'plpgsql'
SECURITY DEFINER;

ALTER FUNCTION prod.prod_vers_d(integer)
    OWNER TO postgres;
COMMENT ON FUNCTION prod.prod_vers_d(integer)
    IS 'Удалить версию продукта';

CREATE VIEW prod.v_prod_vers
 AS
select prod_vers_id
	 , prod_id
	 , prod_name
     , prod_code
	 , prod_vers_num
	 , prod_vers_desc
from prod.prod_vers pv
join prod.prod p using(prod_id);

ALTER TABLE prod.v_prod_vers OWNER TO postgres;
COMMENT ON VIEW prod.v_prod_vers IS 'Версии продукта.';


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
    doc_id serial NOT NULL,
    prod_vers_id integer NOT NULL,
    doc_name character varying(256) COLLATE pg_catalog."default" NOT NULL,
    doc_code character varying(50) COLLATE pg_catalog."default" NOT NULL,
    doc_full_code character varying(100) COLLATE pg_catalog."default" NOT NULL,
    doc_desc character varying(250) COLLATE pg_catalog."default",
    doc_created_at timestamp without time zone DEFAULT now(),
    doc_modified_at timestamp without time zone DEFAULT now()
) TABLESPACE pg_default;

ALTER TABLE IF EXISTS doc.doc
    ADD CONSTRAINT doc_pkey PRIMARY KEY (doc_id);

ALTER TABLE IF EXISTS doc.doc
    ADD CONSTRAINT doc_prod_vers_id_fkey FOREIGN KEY (prod_vers_id)
    REFERENCES prod.prod_vers (prod_vers_id) MATCH SIMPLE;

ALTER TABLE IF EXISTS doc.doc
    ADD CONSTRAINT doc_prod_vers_id_doc_name_key UNIQUE (prod_vers_id, doc_name);

ALTER TABLE IF EXISTS doc.doc
    ADD CONSTRAINT doc_prod_vers_id_doc_code_key UNIQUE (prod_vers_id, doc_code);

COMMENT ON TABLE doc.doc IS 'Документация.';

--########################################################################################################################################
--Добавить
CREATE OR REPLACE FUNCTION doc.doc_i(IN _prod_vers_id integer, IN _doc_name character varying, IN _doc_code character varying, IN _doc_desc character varying)
    RETURNS integer AS
$BODY$
DECLARE
	lI_id 	integer := -1;
BEGIN
	insert into doc.doc(prod_vers_id, doc_name, doc_code, doc_desc) values ($1, $2, $3, $4) returning doc_id into lI_id;
	return lI_id;
EXCEPTION WHEN unique_violation THEN
	IF(SQLERRM ~* 'doc_prod_vers_id_doc_code_key')THEN
		RAISE NOTICE 'Documentation with this code already exists';
	ELSIF(SQLERRM ~* 'doc_prod_vers_id_doc_name_key')THEN
		RAISE NOTICE 'Documentation with this name already exists';
	ELSE
		RAISE NOTICE 'Illegal operation: %', SQLERRM;
	END IF;
	return lI_id;
END;
$BODY$
LANGUAGE 'plpgsql'
SECURITY DEFINER;

ALTER FUNCTION doc.doc_i(integer, character varying, character varying, character varying)
    OWNER TO postgres;
COMMENT ON FUNCTION doc.doc_i(integer, character varying, character varying, character varying)
    IS 'Добавить документацию';

--########################################################################################################################################
--Обновить
CREATE OR REPLACE FUNCTION doc.doc_u(IN _doc_id integer, IN _prod_vers_id integer, IN _doc_name character varying, IN _doc_code character varying, IN _doc_desc character varying)
    RETURNS integer AS
$BODY$
DECLARE
	lI_id 	integer := -1;
BEGIN
	update doc.doc
	set prod_vers_id = $2
	  , doc_name = $3
	  , doc_code = $4
	  , doc_desc = $5
	where doc_id = $1;
	return _doc_id;
EXCEPTION WHEN unique_violation THEN
	IF(SQLERRM ~* 'doc_prod_vers_id_doc_code_key')THEN
		RAISE NOTICE 'Documentation with this code already exists';
	ELSIF(SQLERRM ~* 'doc_prod_vers_id_doc_name_key')THEN
		RAISE NOTICE 'Documentation with this name already exists';
	ELSE
		RAISE NOTICE 'Illegal operation: %', SQLERRM;
	END IF;
	return lI_id;
END;
$BODY$
LANGUAGE 'plpgsql'
SECURITY DEFINER;

ALTER FUNCTION doc.doc_u(integer, integer, character varying, character varying, character varying)
    OWNER TO postgres;
COMMENT ON FUNCTION doc.doc_u(integer, integer, character varying, character varying, character varying)
    IS 'Обновить документацию';

--########################################################################################################################################
--Удалить
CREATE OR REPLACE FUNCTION doc.doc_d(IN _doc_id integer)
    RETURNS integer AS
$BODY$
DECLARE
	lI_id 	integer := -1;
BEGIN
	DELETE FROM doc.doc
	where doc_id = $1;
	return _doc_id;
EXCEPTION WHEN OTHERS THEN
	RAISE NOTICE 'Illegal operation: %', SQLERRM;
	return lI_id;
END;
$BODY$
LANGUAGE 'plpgsql'
SECURITY DEFINER;

ALTER FUNCTION doc.doc_d(integer)
    OWNER TO postgres;
COMMENT ON FUNCTION doc.doc_d(integer)
    IS 'Удалить документацию';

CREATE FUNCTION doc.doc_id_by_code(IN _doc_full_code character varying)
    RETURNS integer
    LANGUAGE 'sql'
    STABLE
AS $BODY$
select doc_id from doc.doc where doc_full_code = $1;
$BODY$;

ALTER FUNCTION doc.doc_id_by_code(character varying)
    OWNER TO postgres;
COMMENT ON FUNCTION doc.doc_id_by_code(character varying)
    IS 'ID документации по ее коду.';

CREATE or replace FUNCTION doc.tgx_doc_doc_bi()
    RETURNS trigger
    LANGUAGE 'plpgsql'
AS $BODY$
BEGIN
	SELECT p.prod_code||'_'||pv.prod_vers_num||'_'||NEW.doc_code
	INTO NEW.doc_full_code
	FROM prod.prod_vers pv
	JOIN prod.prod p using(prod_id)
	WHERE prod_vers_id = NEW.prod_vers_id;

	RAISE INFO 'doc_full_code=%', NEW.doc_full_code;

	return NEW;
END;
$BODY$;

ALTER FUNCTION doc.tgx_doc_doc_bi() OWNER TO postgres;
COMMENT ON FUNCTION doc.tgx_doc_doc_bi() IS 'null';

CREATE OR REPLACE TRIGGER tg_doc_doc_biu
    BEFORE INSERT OR UPDATE
    ON doc.doc
    FOR EACH ROW
    EXECUTE FUNCTION doc.tgx_doc_doc_bi();


--##############################################################
--##                 Версия документации
--##############################################################

CREATE TABLE IF NOT EXISTS doc.doc_vers
(
    doc_vers_id serial NOT NULL,
    doc_id integer NOT NULL,
    doc_vers_num character varying(100) COLLATE pg_catalog."default" NOT NULL,
    doc_vers_descr character varying(1000) COLLATE pg_catalog."default",
    doc_vers_created_at timestamp without time zone DEFAULT now(),
    doc_vers_modified_at timestamp without time zone DEFAULT now()
) TABLESPACE pg_default;

ALTER TABLE IF EXISTS doc.doc_vers
    ADD CONSTRAINT doc_vers_pkey PRIMARY KEY (doc_vers_id);

ALTER TABLE IF EXISTS doc.doc_vers
    ADD CONSTRAINT doc_vers_doc_id_fkey FOREIGN KEY (doc_id)
    REFERENCES doc.doc (doc_id) MATCH SIMPLE;
	
COMMENT ON TABLE doc.doc_vers IS 'Версия документации.';

--##############################################################
--##                 Загружаемые файлы
--##############################################################

CREATE TABLE IF NOT EXISTS doc.doc_file
(
    doc_file_id serial NOT NULL,
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
    cont_id serial NOT NULL,
    cont_idp integer,
    doc_vers_id integer,
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
    ADD CONSTRAINT content_doc_vers_id_fkey FOREIGN KEY (doc_vers_id)
    REFERENCES doc.doc_vers (doc_vers_id) MATCH SIMPLE;

ALTER TABLE IF EXISTS doc.content
    ADD CONSTRAINT content_tag_id_fkey FOREIGN KEY (tag_id)
    REFERENCES doc.tag (tag_id) MATCH SIMPLE;




