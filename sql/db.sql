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
    ADD CONSTRAINT prod_prod_code_ukey UNIQUE (prod_code);
ALTER TABLE IF EXISTS prod.prod
    ADD CONSTRAINT prod_prod_name_ukey UNIQUE (prod_name);

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
	IF(SQLERRM ~* 'prod_prod_code_ukey')THEN
		RAISE NOTICE 'Product with this code already exists';
	ELSIF(SQLERRM ~* 'prod_prod_name_ukey')THEN
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
	IF(SQLERRM ~* 'prod_prod_code_ukey')THEN
		RAISE NOTICE 'Product with this code already exists';
	ELSIF(SQLERRM ~* 'prod_prod_name_ukey')THEN
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
    ADD CONSTRAINT prod_vers_prod_vers_num_ukey UNIQUE (prod_vers_num);
ALTER TABLE IF EXISTS prod.prod_vers
    ADD CONSTRAINT prod_vers_num_chk1 CHECK (array_length(string_to_array(prod_vers_num::text, '.'::text)::integer[], 0) > 0);

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
	IF(SQLERRM ~* 'prod.prod_vers_prod_vers_num_ukey')THEN
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
	IF(SQLERRM ~* 'prod.prod_vers_prod_vers_num_ukey')THEN
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

CREATE FUNCTION prod.get_prod_vers_id(IN _prod_code text, IN _prod_vers_num text DEFAULT null)
    RETURNS integer
    LANGUAGE 'sql'
    STABLE
AS $BODY$
select pv.prod_vers_id
from prod.prod_vers pv
join prod.prod p using(prod_id)
where p.prod_code = $1
  and ($2 is null or pv.prod_vers_num = $2)
order by string_to_array(prod_vers_num, '.')::_int4 desc
limit 1;
$BODY$;

ALTER FUNCTION prod.get_prod_vers_id(text, text)
    OWNER TO postgres;

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
    ADD CONSTRAINT doc_prod_vers_id_doc_name_ukey UNIQUE (prod_vers_id, doc_name);

ALTER TABLE IF EXISTS doc.doc
    ADD CONSTRAINT doc_prod_vers_id_doc_code_ukey UNIQUE (prod_vers_id, doc_code);

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
	IF(SQLERRM ~* 'doc_prod_vers_id_doc_code_ukey')THEN
		RAISE NOTICE 'Documentation with this code already exists';
	ELSIF(SQLERRM ~* 'doc_prod_vers_id_doc_name_ukey')THEN
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
	IF(SQLERRM ~* 'doc_prod_vers_id_doc_code_ukey')THEN
		RAISE NOTICE 'Documentation with this code already exists';
	ELSIF(SQLERRM ~* 'doc_prod_vers_id_doc_name_ukey')THEN
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

CREATE or replace FUNCTION doc.tgf_doc_doc_biu()
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

ALTER FUNCTION doc.tgf_doc_doc_biu() OWNER TO postgres;
COMMENT ON FUNCTION doc.tgf_doc_doc_biu() IS 'null';

CREATE OR REPLACE TRIGGER tg_doc_doc_biu
    BEFORE INSERT OR UPDATE
    ON doc.doc
    FOR EACH ROW
    EXECUTE FUNCTION doc.tgf_doc_doc_biu();


--##############################################################
--##                 Версия документации
--##############################################################

CREATE TABLE IF NOT EXISTS doc.doc_vers
(
    doc_vers_id serial NOT NULL,
    doc_id integer NOT NULL,
    doc_vers_num character varying(100) COLLATE pg_catalog."default" NOT NULL,
    doc_vers_desc character varying(1000) COLLATE pg_catalog."default",
    doc_vers_created_at timestamp without time zone DEFAULT now(),
    doc_vers_modified_at timestamp without time zone DEFAULT now()
) TABLESPACE pg_default;

ALTER TABLE IF EXISTS doc.doc_vers
    ADD CONSTRAINT doc_vers_pkey PRIMARY KEY (doc_vers_id);
ALTER TABLE IF EXISTS doc.doc_vers
    ADD CONSTRAINT doc_vers_doc_id_fkey FOREIGN KEY (doc_id)
    REFERENCES doc.doc (doc_id) MATCH SIMPLE;
ALTER TABLE IF EXISTS doc.doc_vers
    ADD CONSTRAINT doc_id_doc_vers_num_ukey UNIQUE (doc_id, doc_vers_num);
ALTER TABLE IF EXISTS doc.doc_vers
    ADD CONSTRAINT doc_vers_num_chk1 CHECK (array_length(string_to_array(doc_vers_num::text, '.'::text)::integer[], 0) > 0);

COMMENT ON TABLE doc.doc_vers IS 'Версия документации.';

--########################################################################################################################################
--Добавить
CREATE OR REPLACE FUNCTION doc.doc_vers_i(IN _doc_id integer, IN _doc_vers_num character varying, IN _doc_vers_desc character varying)
    RETURNS integer AS
$BODY$
DECLARE
	lI_id 	integer := -1;
BEGIN
	insert into doc.doc_vers(doc_id, doc_vers_num, doc_vers_desc) values ($1, $2, $3) returning doc_vers_id into lI_id;
	return lI_id;
EXCEPTION WHEN unique_violation THEN
	IF(SQLERRM ~* 'doc_id_doc_vers_num_ukey')THEN
		RAISE NOTICE 'Version of documentation with this code already exists';
	ELSE
		RAISE NOTICE 'Illegal operation: %', SQLERRM;
	END IF;
	return lI_id;
END;
$BODY$
LANGUAGE 'plpgsql'
SECURITY DEFINER;

ALTER FUNCTION doc.doc_vers_i(integer, character varying, character varying)
    OWNER TO postgres;
COMMENT ON FUNCTION doc.doc_vers_i(integer, character varying, character varying)
    IS 'Добавить версию документации.';

--########################################################################################################################################
--Обновить
CREATE OR REPLACE FUNCTION doc.doc_vers_u(IN _doc_vers_id integer, IN _doc_id integer, IN _doc_vers_num character varying, IN _doc_vers_desc character varying)
    RETURNS integer AS
$BODY$
DECLARE
	lI_id 	integer := -1;
BEGIN
	update doc.doc_vers
	set doc_id = $2
	  , doc_vers_num = $3
	  , doc_vers_desc = $4
	where doc_vers_id = $1;
	return _doc_vers_id;
EXCEPTION WHEN unique_violation THEN
	IF(SQLERRM ~* 'doc_id_doc_vers_num_ukey')THEN
		RAISE NOTICE 'Version of documentation with this code already exists';
	ELSE
		RAISE NOTICE 'Illegal operation: %', SQLERRM;
	END IF;
	return lI_id;
END;
$BODY$
LANGUAGE 'plpgsql'
SECURITY DEFINER;

ALTER FUNCTION doc.doc_vers_u(integer, integer, character varying, character varying)
    OWNER TO postgres;
COMMENT ON FUNCTION doc.doc_vers_u(integer, integer, character varying, character varying)
    IS 'Обновить версию документации.';

--########################################################################################################################################
--Удалить
CREATE OR REPLACE FUNCTION doc.doc_vers_d(IN _doc_vers_id integer)
    RETURNS integer AS
$BODY$
DECLARE
	lI_id 	integer := -1;
BEGIN
	DELETE FROM doc.doc_vers
	where doc_vers_id = $1;
	return _doc_vers_id;
EXCEPTION WHEN OTHERS THEN
	RAISE NOTICE 'Illegal operation: %', SQLERRM;
	return lI_id;
END;
$BODY$
LANGUAGE 'plpgsql'
SECURITY DEFINER;

ALTER FUNCTION doc.doc_vers_d(integer)
    OWNER TO postgres;
COMMENT ON FUNCTION doc.doc_vers_d(integer)
    IS 'Удалить версию документации.';

--##############################################################
--##                 Загружаемые файлы
--##############################################################

CREATE TABLE IF NOT EXISTS doc.doc_file
(
    doc_file_id serial NOT NULL,
    doc_file_name text COLLATE pg_catalog."default" NOT NULL,
    doc_file_abspath text COLLATE pg_catalog."default" NOT NULL,
    doc_file_relpath text COLLATE pg_catalog."default",
    --doc_vers_id integer NOT NULL,
    doc_file_created_at timestamp without time zone DEFAULT now(),
    doc_file_modified_at timestamp without time zone DEFAULT now()
) TABLESPACE pg_default;

COMMENT ON TABLE doc.doc_file IS 'Файлы загрузочные.';

ALTER TABLE IF EXISTS doc.doc_file
    ADD CONSTRAINT doc_file_pkey PRIMARY KEY (doc_file_id);

--ALTER TABLE IF EXISTS doc.doc_file
--    ADD CONSTRAINT doc_file_doc_vers_id_fkey FOREIGN KEY (doc_vers_id)
--    REFERENCES doc.doc_vers (doc_vers_id) MATCH SIMPLE;

--ALTER TABLE IF EXISTS doc.doc_file
--    ADD CONSTRAINT doc_vers_id_doc_file_name_ukey UNIQUE (doc_vers_id, doc_file_name);

--########################################################################################################################################
--Добавить
CREATE OR REPLACE FUNCTION doc.doc_file_i(--IN _doc_vers_id integer,
                                          IN _doc_file_name character varying, IN _doc_file_abspath character varying, _doc_file_relpath character varying)
    RETURNS integer AS
$BODY$
DECLARE
	lI_id 	integer := -1;
BEGIN
	insert into doc.doc_file(--doc_vers_id,
	    doc_file_name, doc_file_abspath, doc_file_relpath) values ($1, $2, $3) returning doc_file_id into lI_id;
	return lI_id;
EXCEPTION WHEN others THEN
	IF(TRUE)THEN --SQLERRM ~* 'doc_vers_id_doc_file_name_ukey')THEN
	--	RAISE NOTICE 'This file were read for this version of documentation.';
	--ELSE
		RAISE NOTICE 'Illegal operation: %', SQLERRM;
	END IF;
	return lI_id;
END;
$BODY$
LANGUAGE 'plpgsql'
SECURITY DEFINER;

ALTER FUNCTION doc.doc_file_i(character varying, character varying, character varying)
    OWNER TO postgres;
COMMENT ON FUNCTION doc.doc_file_i(character varying, character varying, character varying)
    IS 'Добавить файл.';

--########################################################################################################################################
--Обновить
CREATE OR REPLACE FUNCTION doc.doc_file_u(IN _doc_file_id integer --, IN _doc_vers_id integer
                                        , IN _doc_file_name character varying, IN _doc_file_abspath character varying, IN _doc_file_relpath character varying)
    RETURNS integer AS
$BODY$
DECLARE
	lI_id 	integer := -1;
BEGIN
	update doc.doc_file
	set --doc_vers_id = $2,
	    doc_file_name = $3
	  , doc_file_abspath = $4
	  , doc_file_relpath = $5
	where doc_file_id = $1;
	return _doc_file_id;
EXCEPTION WHEN others THEN
	IF(TRUE) THEN --SQLERRM ~* 'doc_vers_id_doc_file_name_ukey')THEN
	--	RAISE NOTICE 'This file were read for this version of documentation.';
	--ELSE
		RAISE NOTICE 'Illegal operation: %', SQLERRM;
	END IF;
	return lI_id;
END;
$BODY$
LANGUAGE 'plpgsql'
SECURITY DEFINER;

ALTER FUNCTION doc.doc_file_u(integer, character varying, character varying, character varying)
    OWNER TO postgres;
COMMENT ON FUNCTION doc.doc_file_u(integer, character varying, character varying, character varying)
    IS 'Обновить файл.';

--########################################################################################################################################
--Удалить
CREATE OR REPLACE FUNCTION doc.doc_file_d(IN _doc_file_id integer)
    RETURNS integer AS
$BODY$
DECLARE
	lI_id 	integer := -1;
BEGIN
	DELETE FROM doc.doc_file
	where doc_file_id = $1;
	return _doc_file_id;
EXCEPTION WHEN OTHERS THEN
	RAISE NOTICE 'Illegal operation: %', SQLERRM;
	return lI_id;
END;
$BODY$
LANGUAGE 'plpgsql'
SECURITY DEFINER;

ALTER FUNCTION doc.doc_file_d(integer)
    OWNER TO postgres;
COMMENT ON FUNCTION doc.doc_file_d(integer)
    IS 'Удалить файл.';

--##############################################################
--##                 Справочник тегов
--##############################################################

create table doc.tag (
  tag_id serial primary key
, tag_name varchar(100) not null unique
);

ALTER TABLE IF EXISTS doc.tag
    ADD CONSTRAINT tag_name_ukey UNIQUE (tag_name);

COMMENT ON TABLE doc.tag IS 'Справочник тегов.';

--########################################################################################################################################
--Добавить
CREATE OR REPLACE FUNCTION doc.tag_i(IN _tag_name character varying)
    RETURNS integer AS
$BODY$
DECLARE
	lI_id 	integer := -1;
BEGIN
	insert into doc.tag(tag_name) values ($1) returning tag_id into lI_id;
	return lI_id;
EXCEPTION WHEN unique_violation THEN
	IF(SQLERRM ~* 'tag_name_ukey')THEN
		RAISE NOTICE 'This tag is already exists.';
	ELSE
		RAISE NOTICE 'Illegal operation: %', SQLERRM;
	END IF;
	return lI_id;
END;
$BODY$
LANGUAGE 'plpgsql'
SECURITY DEFINER;

ALTER FUNCTION doc.tag_i(character varying) OWNER TO postgres;
COMMENT ON FUNCTION doc.tag_i(character varying) IS 'Добавить тег.';

--########################################################################################################################################
--Обновить
CREATE OR REPLACE FUNCTION doc.tag_u(IN _tag_id integer, IN _tag_name character varying)
    RETURNS integer AS
$BODY$
DECLARE
	lI_id 	integer := -1;
BEGIN
	update doc.tag
	set tag_name = $2
	where tag_id = $1;
	return _tag_id;
EXCEPTION WHEN unique_violation THEN
	IF(SQLERRM ~* 'tag_name_ukey')THEN
		RAISE NOTICE 'This tag is already exists.';
	ELSE
		RAISE NOTICE 'Illegal operation: %', SQLERRM;
	END IF;
	return lI_id;
END;
$BODY$
LANGUAGE 'plpgsql'
SECURITY DEFINER;

ALTER FUNCTION doc.tag_u(integer, character varying) OWNER TO postgres;
COMMENT ON FUNCTION doc.tag_u(integer, character varying) IS 'Обновить тег.';

--########################################################################################################################################
--Удалить
CREATE OR REPLACE FUNCTION doc.tag_d(IN _tag_id integer)
    RETURNS integer AS
$BODY$
DECLARE
	lI_id 	integer := -1;
BEGIN
	DELETE FROM doc.tag
	where tag_id = $1;
	return _tag_id;
EXCEPTION WHEN OTHERS THEN
	RAISE NOTICE 'Illegal operation: %', SQLERRM;
	return lI_id;
END;
$BODY$
LANGUAGE 'plpgsql'
SECURITY DEFINER;

ALTER FUNCTION doc.tag_d(integer) OWNER TO postgres;
COMMENT ON FUNCTION doc.tag_d(integer) IS 'Удалить тег.';


--##############################################################
--##                 Результаты парсинга
--##############################################################

CREATE TABLE IF NOT EXISTS doc.cont
(
    cont_id serial NOT NULL,
    cont_idp integer,
    doc_vers_id integer,
    doc_file_id integer,
    tag_id integer,
    content text COLLATE pg_catalog."default",
    cont_lvl integer,
    cont_created_at timestamp without time zone DEFAULT now(),
    cont_modified_at timestamp without time zone DEFAULT now()
) TABLESPACE pg_default;

COMMENT ON TABLE doc.cont IS 'Результат парсинга файлов.';

ALTER TABLE IF EXISTS doc.cont
    ADD CONSTRAINT cont_pkey PRIMARY KEY (cont_id);

ALTER TABLE IF EXISTS doc.cont
    ADD CONSTRAINT cont_doc_vers_id_fkey FOREIGN KEY (doc_vers_id)
    REFERENCES doc.doc_vers (doc_vers_id) MATCH SIMPLE;

ALTER TABLE IF EXISTS doc.cont
    ADD CONSTRAINT cont_tag_id_fkey FOREIGN KEY (tag_id)
    REFERENCES doc.tag (tag_id) MATCH SIMPLE;

--########################################################################################################################################
--Добавить
CREATE OR REPLACE FUNCTION doc.cont_i(IN _cont_idp integer, IN _doc_vers_id integer, IN _doc_file_id integer, IN _tag_id integer, IN _content text, _cont_lvl integer)
    RETURNS integer AS
$BODY$
DECLARE
	lI_id 	integer := -1;
BEGIN
	insert into doc.cont(cont_idp, doc_vers_id, doc_file_id, tag_id, content, cont_lvl) values ($1, $2, $3, $4, $5, $6) returning cont_id into lI_id;
	return lI_id;
EXCEPTION WHEN unique_violation THEN
	IF(TRUE)THEN
		RAISE NOTICE 'Illegal operation: %', SQLERRM;
	END IF;
	return lI_id;
END;
$BODY$
LANGUAGE 'plpgsql'
SECURITY DEFINER;

ALTER FUNCTION doc.cont_i(integer, integer, integer, integer, text, integer)
    OWNER TO postgres;
COMMENT ON FUNCTION doc.cont_i(integer, integer, integer, integer, text, integer)
    IS 'Добавить файл.';

--########################################################################################################################################
--Обновить
CREATE OR REPLACE FUNCTION doc.cont_u(IN _cont_id integer, IN _cont_idp integer, IN _doc_vers_id integer, IN _doc_file_id integer, IN _tag_id integer, IN _content text, IN _cont_lvl integer)
    RETURNS integer AS
$BODY$
DECLARE
	lI_id 	integer := -1;
BEGIN
	update doc.cont
	set cont_idp = $2
	  , doc_vers_id = $3
	  , doc_file_id = $4
	  , tag_id = $5
	  , content = $6
	  , cont_lvl = $7
	where cont_id = $1;
	return _cont_id;
EXCEPTION WHEN unique_violation THEN
	IF(SQLERRM ~* 'doc_vers_id_cont_name_ukey')THEN
		RAISE NOTICE 'This file were read for this version of documentation.';
	ELSE
		RAISE NOTICE 'Illegal operation: %', SQLERRM;
	END IF;
	return lI_id;
END;
$BODY$
LANGUAGE 'plpgsql'
SECURITY DEFINER;

ALTER FUNCTION doc.cont_u(integer, integer, integer, integer, integer, text, integer)
    OWNER TO postgres;
COMMENT ON FUNCTION doc.cont_u(integer, integer, integer, integer, integer, text, integer)
    IS 'Обновить файл.';

--########################################################################################################################################
--Удалить
CREATE OR REPLACE FUNCTION doc.cont_d(IN _cont_id integer)
    RETURNS integer AS
$BODY$
DECLARE
	lI_id 	integer := -1;
BEGIN
	DELETE FROM doc.cont
	where cont_id = $1;
	return _cont_id;
EXCEPTION WHEN OTHERS THEN
	RAISE NOTICE 'Illegal operation: %', SQLERRM;
	return lI_id;
END;
$BODY$
LANGUAGE 'plpgsql'
SECURITY DEFINER;

ALTER FUNCTION doc.cont_d(integer)
    OWNER TO postgres;
COMMENT ON FUNCTION doc.cont_d(integer)
    IS 'Удалить файл.';



CREATE FUNCTION doc.clear_content(_doc_vers_id integer)
    RETURNS boolean
    LANGUAGE 'plpgsql'
    VOLATILE
AS $BODY$
begin
	delete from doc.cont where doc_vers_id = _doc_vers_id;
	return true;
end;
$BODY$;

ALTER FUNCTION doc.clear_content(integer)
    OWNER TO postgres;

