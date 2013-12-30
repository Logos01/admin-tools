--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET client_encoding = 'SQL_ASCII';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- Name: inventory; Type: DATABASE; Schema: -; Owner: -
--

CREATE DATABASE inventory WITH TEMPLATE = template0 ENCODING = 'SQL_ASCII' LC_COLLATE = 'C' LC_CTYPE = 'C' TABLESPACE = inventory;


\connect inventory

SET statement_timeout = 0;
SET client_encoding = 'SQL_ASCII';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = true;

--
-- Name: group_vars; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE group_vars (
    groupname character varying(30) NOT NULL,
    var_name character varying(50) NOT NULL,
    var_value character varying(50) NOT NULL,
    primary_key integer NOT NULL
);


--
-- Name: group_vars_primary_key_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE group_vars_primary_key_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: group_vars_primary_key_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE group_vars_primary_key_seq OWNED BY group_vars.primary_key;


--
-- Name: groups; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE groups (
    name character varying(20) NOT NULL,
    parent character varying(20),
    has_children boolean DEFAULT false NOT NULL,
    primary_key integer NOT NULL
);


--
-- Name: groups_primary_key_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE groups_primary_key_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: groups_primary_key_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE groups_primary_key_seq OWNED BY groups.primary_key;


SET default_with_oids = false;

--
-- Name: host_groups; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE host_groups (
    hostname character varying(20) NOT NULL,
    groupname character varying(30) NOT NULL,
    primary_key integer NOT NULL
);


--
-- Name: host_groups_primary_key_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE host_groups_primary_key_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: host_groups_primary_key_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE host_groups_primary_key_seq OWNED BY host_groups.primary_key;


SET default_with_oids = true;

--
-- Name: host_inventory; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE host_inventory (
    hostname character varying(20),
    ipaddr cidr,
    access_method character varying(10),
    online boolean DEFAULT true NOT NULL,
    description character varying(90),
    row_is_obsolete boolean NOT NULL,
    primary_key integer NOT NULL,
    in_dns boolean,
    drac_address cidr,
    os character varying(20),
    os_version character varying(20)
);


--
-- Name: host_inventory_primary_key_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE host_inventory_primary_key_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: host_inventory_primary_key_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE host_inventory_primary_key_seq OWNED BY host_inventory.primary_key;


SET default_with_oids = false;

--
-- Name: hostnames; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE hostnames (
    hostname character varying(20),
    primary_key integer NOT NULL
);


--
-- Name: hostnames_primary_key_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE hostnames_primary_key_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hostnames_primary_key_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE hostnames_primary_key_seq OWNED BY hostnames.primary_key;


--
-- Name: ipaddrs; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE ipaddrs (
    ipaddr cidr NOT NULL,
    primary_key integer NOT NULL
);


--
-- Name: ipaddrs_primary_key_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE ipaddrs_primary_key_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ipaddrs_primary_key_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE ipaddrs_primary_key_seq OWNED BY ipaddrs.primary_key;


--
-- Name: primary_key; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY group_vars ALTER COLUMN primary_key SET DEFAULT nextval('group_vars_primary_key_seq'::regclass);


--
-- Name: primary_key; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY groups ALTER COLUMN primary_key SET DEFAULT nextval('groups_primary_key_seq'::regclass);


--
-- Name: primary_key; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY host_groups ALTER COLUMN primary_key SET DEFAULT nextval('host_groups_primary_key_seq'::regclass);


--
-- Name: primary_key; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY host_inventory ALTER COLUMN primary_key SET DEFAULT nextval('host_inventory_primary_key_seq'::regclass);


--
-- Name: primary_key; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY hostnames ALTER COLUMN primary_key SET DEFAULT nextval('hostnames_primary_key_seq'::regclass);


--
-- Name: primary_key; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY ipaddrs ALTER COLUMN primary_key SET DEFAULT nextval('ipaddrs_primary_key_seq'::regclass);


--
-- Name: PrimaryKey_hostname; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY hostnames
    ADD CONSTRAINT "PrimaryKey_hostname" PRIMARY KEY (primary_key);


--
-- Name: PrimaryKey_ipaddrs; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY ipaddrs
    ADD CONSTRAINT "PrimaryKey_ipaddrs" PRIMARY KEY (primary_key);


--
-- Name: host_groups_primary_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY host_groups
    ADD CONSTRAINT host_groups_primary_key PRIMARY KEY (primary_key);


--
-- Name: host_groups_unique_matching; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY host_groups
    ADD CONSTRAINT host_groups_unique_matching UNIQUE (hostname, groupname);


--
-- Name: host_inventory_primary_key; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY host_inventory
    ADD CONSTRAINT host_inventory_primary_key PRIMARY KEY (primary_key);


--
-- Name: primary_key_group_vars; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY group_vars
    ADD CONSTRAINT primary_key_group_vars PRIMARY KEY (primary_key);


--
-- Name: primary_key_groups; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY groups
    ADD CONSTRAINT primary_key_groups PRIMARY KEY (primary_key);


--
-- Name: unique_group_names; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY groups
    ADD CONSTRAINT unique_group_names UNIQUE (name);


--
-- Name: unique_hostname; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY hostnames
    ADD CONSTRAINT unique_hostname UNIQUE (hostname);


--
-- Name: unique_ipaddrs; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY ipaddrs
    ADD CONSTRAINT unique_ipaddrs UNIQUE (ipaddr);


--
-- Name: fki_Unique_ipaddrs; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX "fki_Unique_ipaddrs" ON host_inventory USING btree (ipaddr);


--
-- Name: fki_group_vars_groupname_foreign; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX fki_group_vars_groupname_foreign ON group_vars USING btree (groupname);


--
-- Name: fki_host_groups_foreign_groupnames; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX fki_host_groups_foreign_groupnames ON host_groups USING btree (groupname);


--
-- Name: fki_host_groups_foreign_hostnames; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX fki_host_groups_foreign_hostnames ON host_groups USING btree (hostname);


--
-- Name: fki_host_groups_inventory_foreign; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX fki_host_groups_inventory_foreign ON host_groups USING btree (hostname);


--
-- Name: fki_host_inventory_foreign_hostnames; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX fki_host_inventory_foreign_hostnames ON host_inventory USING btree (hostname);


--
-- Name: fki_host_inventory_foreign_ipaddrs; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX fki_host_inventory_foreign_ipaddrs ON host_inventory USING btree (ipaddr);


--
-- Name: group_vars_groupname_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY group_vars
    ADD CONSTRAINT group_vars_groupname_foreign FOREIGN KEY (groupname) REFERENCES groups(name);


--
-- Name: host_groups_foreign_groupnames; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY host_groups
    ADD CONSTRAINT host_groups_foreign_groupnames FOREIGN KEY (groupname) REFERENCES groups(name) MATCH FULL;


--
-- Name: host_groups_foreign_hostnames; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY host_groups
    ADD CONSTRAINT host_groups_foreign_hostnames FOREIGN KEY (hostname) REFERENCES hostnames(hostname) MATCH FULL;


--
-- Name: host_inventory_foreign_hostnames; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY host_inventory
    ADD CONSTRAINT host_inventory_foreign_hostnames FOREIGN KEY (hostname) REFERENCES hostnames(hostname);


--
-- Name: host_inventory_foreign_ipaddrs; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY host_inventory
    ADD CONSTRAINT host_inventory_foreign_ipaddrs FOREIGN KEY (ipaddr) REFERENCES ipaddrs(ipaddr);


--
-- Name: public; Type: ACL; Schema: -; Owner: -
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- PostgreSQL database dump complete
--

