--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'SQL_ASCII';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

DROP DATABASE inventory;
--
-- Name: inventory; Type: DATABASE; Schema: -; Owner: logos
--

CREATE DATABASE inventory WITH TEMPLATE = template0 ENCODING = 'SQL_ASCII' LC_COLLATE = 'C' LC_CTYPE = 'C' TABLESPACE = inventory;


ALTER DATABASE inventory OWNER TO logos;

\connect inventory

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'SQL_ASCII';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- Name: public; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA public;


ALTER SCHEMA public OWNER TO postgres;

--
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: postgres
--

COMMENT ON SCHEMA public IS 'standard public schema';


--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET search_path = public, pg_catalog;

--
-- Name: last_modified(); Type: FUNCTION; Schema: public; Owner: logos
--

CREATE FUNCTION last_modified() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    BEGIN
        NEW.last_modified = now();
        RETURN NEW;
    END;
$$;


ALTER FUNCTION public.last_modified() OWNER TO logos;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: architectures; Type: TABLE; Schema: public; Owner: logos; Tablespace: 
--

CREATE TABLE architectures (
    primary_key integer NOT NULL,
    arch character varying(10),
    bits integer
);


ALTER TABLE public.architectures OWNER TO logos;

--
-- Name: architectures_primary_key_seq; Type: SEQUENCE; Schema: public; Owner: logos
--

CREATE SEQUENCE architectures_primary_key_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.architectures_primary_key_seq OWNER TO logos;

--
-- Name: architectures_primary_key_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: logos
--

ALTER SEQUENCE architectures_primary_key_seq OWNED BY architectures.primary_key;


--
-- Name: auth_keys; Type: TABLE; Schema: public; Owner: logos; Tablespace: 
--

CREATE TABLE auth_keys (
    primary_key integer NOT NULL,
    hint text,
    encrypted_hash text
);


ALTER TABLE public.auth_keys OWNER TO logos;

--
-- Name: auth_keys_primary_key_seq; Type: SEQUENCE; Schema: public; Owner: logos
--

CREATE SEQUENCE auth_keys_primary_key_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.auth_keys_primary_key_seq OWNER TO logos;

--
-- Name: auth_keys_primary_key_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: logos
--

ALTER SEQUENCE auth_keys_primary_key_seq OWNED BY auth_keys.primary_key;


SET default_with_oids = true;

--
-- Name: group_vars; Type: TABLE; Schema: public; Owner: logos; Tablespace: 
--

CREATE TABLE group_vars (
    groupname character varying(30) NOT NULL,
    var_name character varying(50) NOT NULL,
    var_value character varying(50) NOT NULL,
    primary_key integer NOT NULL
);


ALTER TABLE public.group_vars OWNER TO logos;

--
-- Name: group_vars_primary_key_seq; Type: SEQUENCE; Schema: public; Owner: logos
--

CREATE SEQUENCE group_vars_primary_key_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.group_vars_primary_key_seq OWNER TO logos;

--
-- Name: group_vars_primary_key_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: logos
--

ALTER SEQUENCE group_vars_primary_key_seq OWNED BY group_vars.primary_key;


--
-- Name: groups; Type: TABLE; Schema: public; Owner: logos; Tablespace: 
--

CREATE TABLE groups (
    name character varying(20) NOT NULL,
    parent character varying(20),
    has_children boolean DEFAULT false NOT NULL,
    primary_key integer NOT NULL
);


ALTER TABLE public.groups OWNER TO logos;

--
-- Name: groups_primary_key_seq; Type: SEQUENCE; Schema: public; Owner: logos
--

CREATE SEQUENCE groups_primary_key_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.groups_primary_key_seq OWNER TO logos;

--
-- Name: groups_primary_key_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: logos
--

ALTER SEQUENCE groups_primary_key_seq OWNED BY groups.primary_key;


SET default_with_oids = false;

--
-- Name: host_groups; Type: TABLE; Schema: public; Owner: logos; Tablespace: 
--

CREATE TABLE host_groups (
    hostname character varying(20) NOT NULL,
    groupname character varying(30) NOT NULL,
    primary_key integer NOT NULL
);


ALTER TABLE public.host_groups OWNER TO logos;

SET default_with_oids = true;

--
-- Name: host_inventory; Type: TABLE; Schema: public; Owner: logos; Tablespace: 
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
    os character varying(40),
    os_version character varying(20),
    oob_access_method character varying,
    oob_access_address character varying(50),
    arch character varying(10),
    last_modified timestamp with time zone
);


ALTER TABLE public.host_inventory OWNER TO logos;

--
-- Name: network_segments; Type: TABLE; Schema: public; Owner: logos; Tablespace: 
--

CREATE TABLE network_segments (
    primary_key integer NOT NULL,
    inet_segment cidr,
    segment_description character varying(50)
);


ALTER TABLE public.network_segments OWNER TO logos;

SET default_with_oids = false;

--
-- Name: server_serials; Type: TABLE; Schema: public; Owner: logos; Tablespace: 
--

CREATE TABLE server_serials (
    hostname character varying(20),
    serial_tag character varying,
    primary_key integer NOT NULL
);


ALTER TABLE public.server_serials OWNER TO logos;

--
-- Name: host_details; Type: VIEW; Schema: public; Owner: logos
--

CREATE VIEW host_details AS
 SELECT host_inventory.hostname,
    host_inventory.ipaddr,
    network_segments.segment_description,
    string_agg((host_groups.groupname)::text, ','::text) AS groupname,
    host_inventory.access_method,
    host_inventory.online,
    host_inventory.description,
    host_inventory.row_is_obsolete,
    host_inventory.in_dns,
    host_inventory.os,
    host_inventory.os_version,
    host_inventory.arch,
    server_serials.serial_tag,
    host_inventory.oob_access_method,
    host_inventory.oob_access_address
   FROM (((host_inventory
     LEFT JOIN network_segments ON (((network_segments.inet_segment)::inet >> (host_inventory.ipaddr)::inet)))
     LEFT JOIN host_groups ON (((host_groups.hostname)::text = (host_inventory.hostname)::text)))
     LEFT JOIN server_serials ON (((host_inventory.hostname)::text = (server_serials.hostname)::text)))
  GROUP BY host_inventory.hostname, host_inventory.ipaddr, network_segments.segment_description, host_inventory.access_method, host_inventory.online, host_inventory.description, host_inventory.row_is_obsolete, host_inventory.in_dns, host_inventory.os, host_inventory.os_version, host_inventory.arch, server_serials.serial_tag, host_inventory.oob_access_method, host_inventory.oob_access_address;


ALTER TABLE public.host_details OWNER TO logos;

--
-- Name: host_groups_primary_key_seq; Type: SEQUENCE; Schema: public; Owner: logos
--

CREATE SEQUENCE host_groups_primary_key_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.host_groups_primary_key_seq OWNER TO logos;

--
-- Name: host_groups_primary_key_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: logos
--

ALTER SEQUENCE host_groups_primary_key_seq OWNED BY host_groups.primary_key;


--
-- Name: host_inventory_primary_key_seq; Type: SEQUENCE; Schema: public; Owner: logos
--

CREATE SEQUENCE host_inventory_primary_key_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.host_inventory_primary_key_seq OWNER TO logos;

--
-- Name: host_inventory_primary_key_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: logos
--

ALTER SEQUENCE host_inventory_primary_key_seq OWNED BY host_inventory.primary_key;


--
-- Name: hostnames; Type: TABLE; Schema: public; Owner: logos; Tablespace: 
--

CREATE TABLE hostnames (
    hostname character varying(20),
    primary_key integer NOT NULL
);


ALTER TABLE public.hostnames OWNER TO logos;

--
-- Name: hostnames_primary_key_seq; Type: SEQUENCE; Schema: public; Owner: logos
--

CREATE SEQUENCE hostnames_primary_key_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.hostnames_primary_key_seq OWNER TO logos;

--
-- Name: hostnames_primary_key_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: logos
--

ALTER SEQUENCE hostnames_primary_key_seq OWNED BY hostnames.primary_key;


--
-- Name: ipaddrs; Type: TABLE; Schema: public; Owner: logos; Tablespace: 
--

CREATE TABLE ipaddrs (
    ipaddr cidr NOT NULL,
    primary_key integer NOT NULL
);


ALTER TABLE public.ipaddrs OWNER TO logos;

--
-- Name: ipaddrs_primary_key_seq; Type: SEQUENCE; Schema: public; Owner: logos
--

CREATE SEQUENCE ipaddrs_primary_key_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.ipaddrs_primary_key_seq OWNER TO logos;

--
-- Name: ipaddrs_primary_key_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: logos
--

ALTER SEQUENCE ipaddrs_primary_key_seq OWNED BY ipaddrs.primary_key;


--
-- Name: network_segments_primary_key_seq; Type: SEQUENCE; Schema: public; Owner: logos
--

CREATE SEQUENCE network_segments_primary_key_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.network_segments_primary_key_seq OWNER TO logos;

--
-- Name: network_segments_primary_key_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: logos
--

ALTER SEQUENCE network_segments_primary_key_seq OWNED BY network_segments.primary_key;


--
-- Name: oob_access_methods; Type: TABLE; Schema: public; Owner: logos; Tablespace: 
--

CREATE TABLE oob_access_methods (
    primary_key integer NOT NULL,
    oob_access_method character varying(50) NOT NULL
);


ALTER TABLE public.oob_access_methods OWNER TO logos;

--
-- Name: oob_access_methods_primary_key_seq; Type: SEQUENCE; Schema: public; Owner: logos
--

CREATE SEQUENCE oob_access_methods_primary_key_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.oob_access_methods_primary_key_seq OWNER TO logos;

--
-- Name: oob_access_methods_primary_key_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: logos
--

ALTER SEQUENCE oob_access_methods_primary_key_seq OWNED BY oob_access_methods.primary_key;


--
-- Name: remediation_state; Type: TABLE; Schema: public; Owner: logos; Tablespace: 
--

CREATE TABLE remediation_state (
    primary_key integer NOT NULL,
    hostname character varying(20),
    is_remediated boolean DEFAULT false NOT NULL,
    workaround_implemented boolean
);


ALTER TABLE public.remediation_state OWNER TO logos;

--
-- Name: remediation_state_primary_key_seq; Type: SEQUENCE; Schema: public; Owner: logos
--

CREATE SEQUENCE remediation_state_primary_key_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.remediation_state_primary_key_seq OWNER TO logos;

--
-- Name: remediation_state_primary_key_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: logos
--

ALTER SEQUENCE remediation_state_primary_key_seq OWNED BY remediation_state.primary_key;


--
-- Name: server_cpu_info; Type: TABLE; Schema: public; Owner: logos; Tablespace: 
--

CREATE TABLE server_cpu_info (
    primary_key integer NOT NULL,
    hostname character varying(20),
    cpu_type character varying(50),
    cpu_count integer,
    cpu_cores integer,
    cpu_threads_per_core integer,
    cpu_vcpus integer
);


ALTER TABLE public.server_cpu_info OWNER TO logos;

--
-- Name: server_cpu_info_primary_key_seq; Type: SEQUENCE; Schema: public; Owner: logos
--

CREATE SEQUENCE server_cpu_info_primary_key_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.server_cpu_info_primary_key_seq OWNER TO logos;

--
-- Name: server_cpu_info_primary_key_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: logos
--

ALTER SEQUENCE server_cpu_info_primary_key_seq OWNED BY server_cpu_info.primary_key;


--
-- Name: server_disk_allocations; Type: TABLE; Schema: public; Owner: logos; Tablespace: 
--

CREATE TABLE server_disk_allocations (
    primary_key integer NOT NULL,
    hostname character varying(20),
    disk_name character varying(10),
    disk_size character varying(20)
);


ALTER TABLE public.server_disk_allocations OWNER TO logos;

--
-- Name: server_disk_allocations_primary_key_seq; Type: SEQUENCE; Schema: public; Owner: logos
--

CREATE SEQUENCE server_disk_allocations_primary_key_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.server_disk_allocations_primary_key_seq OWNER TO logos;

--
-- Name: server_disk_allocations_primary_key_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: logos
--

ALTER SEQUENCE server_disk_allocations_primary_key_seq OWNED BY server_disk_allocations.primary_key;


--
-- Name: server_serials_primary_key_seq; Type: SEQUENCE; Schema: public; Owner: logos
--

CREATE SEQUENCE server_serials_primary_key_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.server_serials_primary_key_seq OWNER TO logos;

--
-- Name: server_serials_primary_key_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: logos
--

ALTER SEQUENCE server_serials_primary_key_seq OWNED BY server_serials.primary_key;


--
-- Name: primary_key; Type: DEFAULT; Schema: public; Owner: logos
--

ALTER TABLE ONLY architectures ALTER COLUMN primary_key SET DEFAULT nextval('architectures_primary_key_seq'::regclass);


--
-- Name: primary_key; Type: DEFAULT; Schema: public; Owner: logos
--

ALTER TABLE ONLY auth_keys ALTER COLUMN primary_key SET DEFAULT nextval('auth_keys_primary_key_seq'::regclass);


--
-- Name: primary_key; Type: DEFAULT; Schema: public; Owner: logos
--

ALTER TABLE ONLY group_vars ALTER COLUMN primary_key SET DEFAULT nextval('group_vars_primary_key_seq'::regclass);


--
-- Name: primary_key; Type: DEFAULT; Schema: public; Owner: logos
--

ALTER TABLE ONLY groups ALTER COLUMN primary_key SET DEFAULT nextval('groups_primary_key_seq'::regclass);


--
-- Name: primary_key; Type: DEFAULT; Schema: public; Owner: logos
--

ALTER TABLE ONLY host_groups ALTER COLUMN primary_key SET DEFAULT nextval('host_groups_primary_key_seq'::regclass);


--
-- Name: primary_key; Type: DEFAULT; Schema: public; Owner: logos
--

ALTER TABLE ONLY host_inventory ALTER COLUMN primary_key SET DEFAULT nextval('host_inventory_primary_key_seq'::regclass);


--
-- Name: primary_key; Type: DEFAULT; Schema: public; Owner: logos
--

ALTER TABLE ONLY hostnames ALTER COLUMN primary_key SET DEFAULT nextval('hostnames_primary_key_seq'::regclass);


--
-- Name: primary_key; Type: DEFAULT; Schema: public; Owner: logos
--

ALTER TABLE ONLY ipaddrs ALTER COLUMN primary_key SET DEFAULT nextval('ipaddrs_primary_key_seq'::regclass);


--
-- Name: primary_key; Type: DEFAULT; Schema: public; Owner: logos
--

ALTER TABLE ONLY network_segments ALTER COLUMN primary_key SET DEFAULT nextval('network_segments_primary_key_seq'::regclass);


--
-- Name: primary_key; Type: DEFAULT; Schema: public; Owner: logos
--

ALTER TABLE ONLY oob_access_methods ALTER COLUMN primary_key SET DEFAULT nextval('oob_access_methods_primary_key_seq'::regclass);


--
-- Name: primary_key; Type: DEFAULT; Schema: public; Owner: logos
--

ALTER TABLE ONLY remediation_state ALTER COLUMN primary_key SET DEFAULT nextval('remediation_state_primary_key_seq'::regclass);


--
-- Name: primary_key; Type: DEFAULT; Schema: public; Owner: logos
--

ALTER TABLE ONLY server_cpu_info ALTER COLUMN primary_key SET DEFAULT nextval('server_cpu_info_primary_key_seq'::regclass);


--
-- Name: primary_key; Type: DEFAULT; Schema: public; Owner: logos
--

ALTER TABLE ONLY server_disk_allocations ALTER COLUMN primary_key SET DEFAULT nextval('server_disk_allocations_primary_key_seq'::regclass);


--
-- Name: primary_key; Type: DEFAULT; Schema: public; Owner: logos
--

ALTER TABLE ONLY server_serials ALTER COLUMN primary_key SET DEFAULT nextval('server_serials_primary_key_seq'::regclass);


--
-- Name: PrimaryKey_hostname; Type: CONSTRAINT; Schema: public; Owner: logos; Tablespace: 
--

ALTER TABLE ONLY hostnames
    ADD CONSTRAINT "PrimaryKey_hostname" PRIMARY KEY (primary_key);


--
-- Name: PrimaryKey_ipaddrs; Type: CONSTRAINT; Schema: public; Owner: logos; Tablespace: 
--

ALTER TABLE ONLY ipaddrs
    ADD CONSTRAINT "PrimaryKey_ipaddrs" PRIMARY KEY (primary_key);


--
-- Name: architectures_arch_key; Type: CONSTRAINT; Schema: public; Owner: logos; Tablespace: 
--

ALTER TABLE ONLY architectures
    ADD CONSTRAINT architectures_arch_key UNIQUE (arch);


--
-- Name: architectures_pkey; Type: CONSTRAINT; Schema: public; Owner: logos; Tablespace: 
--

ALTER TABLE ONLY architectures
    ADD CONSTRAINT architectures_pkey PRIMARY KEY (primary_key);


--
-- Name: auth_keys_hint_key; Type: CONSTRAINT; Schema: public; Owner: logos; Tablespace: 
--

ALTER TABLE ONLY auth_keys
    ADD CONSTRAINT auth_keys_hint_key UNIQUE (hint);


--
-- Name: auth_keys_pkey; Type: CONSTRAINT; Schema: public; Owner: logos; Tablespace: 
--

ALTER TABLE ONLY auth_keys
    ADD CONSTRAINT auth_keys_pkey PRIMARY KEY (primary_key);


--
-- Name: host_groups_primary_key; Type: CONSTRAINT; Schema: public; Owner: logos; Tablespace: 
--

ALTER TABLE ONLY host_groups
    ADD CONSTRAINT host_groups_primary_key PRIMARY KEY (primary_key);


--
-- Name: host_groups_unique_matching; Type: CONSTRAINT; Schema: public; Owner: logos; Tablespace: 
--

ALTER TABLE ONLY host_groups
    ADD CONSTRAINT host_groups_unique_matching UNIQUE (hostname, groupname);


--
-- Name: host_inventory_primary_key; Type: CONSTRAINT; Schema: public; Owner: logos; Tablespace: 
--

ALTER TABLE ONLY host_inventory
    ADD CONSTRAINT host_inventory_primary_key PRIMARY KEY (primary_key);


--
-- Name: oob_access_method_primary_key; Type: CONSTRAINT; Schema: public; Owner: logos; Tablespace: 
--

ALTER TABLE ONLY oob_access_methods
    ADD CONSTRAINT oob_access_method_primary_key PRIMARY KEY (primary_key);


--
-- Name: oob_access_method_uniqueness; Type: CONSTRAINT; Schema: public; Owner: logos; Tablespace: 
--

ALTER TABLE ONLY oob_access_methods
    ADD CONSTRAINT oob_access_method_uniqueness UNIQUE (oob_access_method);


--
-- Name: primary_key_group_vars; Type: CONSTRAINT; Schema: public; Owner: logos; Tablespace: 
--

ALTER TABLE ONLY group_vars
    ADD CONSTRAINT primary_key_group_vars PRIMARY KEY (primary_key);


--
-- Name: primary_key_groups; Type: CONSTRAINT; Schema: public; Owner: logos; Tablespace: 
--

ALTER TABLE ONLY groups
    ADD CONSTRAINT primary_key_groups PRIMARY KEY (primary_key);


--
-- Name: remediation_state_primary_key; Type: CONSTRAINT; Schema: public; Owner: logos; Tablespace: 
--

ALTER TABLE ONLY remediation_state
    ADD CONSTRAINT remediation_state_primary_key PRIMARY KEY (primary_key);


--
-- Name: remediation_state_unique_hostname; Type: CONSTRAINT; Schema: public; Owner: logos; Tablespace: 
--

ALTER TABLE ONLY remediation_state
    ADD CONSTRAINT remediation_state_unique_hostname UNIQUE (hostname);


--
-- Name: segment_list_primary_key; Type: CONSTRAINT; Schema: public; Owner: logos; Tablespace: 
--

ALTER TABLE ONLY network_segments
    ADD CONSTRAINT segment_list_primary_key PRIMARY KEY (primary_key);


--
-- Name: segment_list_unique_subnets; Type: CONSTRAINT; Schema: public; Owner: logos; Tablespace: 
--

ALTER TABLE ONLY network_segments
    ADD CONSTRAINT segment_list_unique_subnets UNIQUE (inet_segment);


--
-- Name: server_cpu_info_primary_key; Type: CONSTRAINT; Schema: public; Owner: logos; Tablespace: 
--

ALTER TABLE ONLY server_cpu_info
    ADD CONSTRAINT server_cpu_info_primary_key PRIMARY KEY (primary_key);


--
-- Name: server_disk_allocations_primary_key; Type: CONSTRAINT; Schema: public; Owner: logos; Tablespace: 
--

ALTER TABLE ONLY server_disk_allocations
    ADD CONSTRAINT server_disk_allocations_primary_key PRIMARY KEY (primary_key);


--
-- Name: server_disk_allocations_unique_disks_per_hostname; Type: CONSTRAINT; Schema: public; Owner: logos; Tablespace: 
--

ALTER TABLE ONLY server_disk_allocations
    ADD CONSTRAINT server_disk_allocations_unique_disks_per_hostname UNIQUE (hostname, disk_name);


--
-- Name: server_serials_primary_key; Type: CONSTRAINT; Schema: public; Owner: logos; Tablespace: 
--

ALTER TABLE ONLY server_serials
    ADD CONSTRAINT server_serials_primary_key PRIMARY KEY (primary_key);


--
-- Name: unique_group_names; Type: CONSTRAINT; Schema: public; Owner: logos; Tablespace: 
--

ALTER TABLE ONLY groups
    ADD CONSTRAINT unique_group_names UNIQUE (name);


--
-- Name: unique_hostname; Type: CONSTRAINT; Schema: public; Owner: logos; Tablespace: 
--

ALTER TABLE ONLY hostnames
    ADD CONSTRAINT unique_hostname UNIQUE (hostname);


--
-- Name: unique_ipaddrs; Type: CONSTRAINT; Schema: public; Owner: logos; Tablespace: 
--

ALTER TABLE ONLY ipaddrs
    ADD CONSTRAINT unique_ipaddrs UNIQUE (ipaddr);


--
-- Name: fki_Unique_ipaddrs; Type: INDEX; Schema: public; Owner: logos; Tablespace: 
--

CREATE INDEX "fki_Unique_ipaddrs" ON host_inventory USING btree (ipaddr);


--
-- Name: fki_arch_foreign_key; Type: INDEX; Schema: public; Owner: logos; Tablespace: 
--

CREATE INDEX fki_arch_foreign_key ON host_inventory USING btree (arch);


--
-- Name: fki_group_vars_groupname_foreign; Type: INDEX; Schema: public; Owner: logos; Tablespace: 
--

CREATE INDEX fki_group_vars_groupname_foreign ON group_vars USING btree (groupname);


--
-- Name: fki_host_groups_foreign_groupnames; Type: INDEX; Schema: public; Owner: logos; Tablespace: 
--

CREATE INDEX fki_host_groups_foreign_groupnames ON host_groups USING btree (groupname);


--
-- Name: fki_host_groups_foreign_hostnames; Type: INDEX; Schema: public; Owner: logos; Tablespace: 
--

CREATE INDEX fki_host_groups_foreign_hostnames ON host_groups USING btree (hostname);


--
-- Name: fki_host_groups_inventory_foreign; Type: INDEX; Schema: public; Owner: logos; Tablespace: 
--

CREATE INDEX fki_host_groups_inventory_foreign ON host_groups USING btree (hostname);


--
-- Name: fki_host_inventory_foreign_hostnames; Type: INDEX; Schema: public; Owner: logos; Tablespace: 
--

CREATE INDEX fki_host_inventory_foreign_hostnames ON host_inventory USING btree (hostname);


--
-- Name: fki_host_inventory_foreign_ipaddrs; Type: INDEX; Schema: public; Owner: logos; Tablespace: 
--

CREATE INDEX fki_host_inventory_foreign_ipaddrs ON host_inventory USING btree (ipaddr);


--
-- Name: fki_host_inventory_oob_access_method_foreign_key; Type: INDEX; Schema: public; Owner: logos; Tablespace: 
--

CREATE INDEX fki_host_inventory_oob_access_method_foreign_key ON host_inventory USING btree (oob_access_method);


--
-- Name: host_inventory_last_modified; Type: TRIGGER; Schema: public; Owner: logos
--

CREATE TRIGGER host_inventory_last_modified BEFORE UPDATE ON host_inventory FOR EACH ROW EXECUTE PROCEDURE last_modified();


--
-- Name: arch_foreign_key; Type: FK CONSTRAINT; Schema: public; Owner: logos
--

ALTER TABLE ONLY host_inventory
    ADD CONSTRAINT arch_foreign_key FOREIGN KEY (arch) REFERENCES architectures(arch);


--
-- Name: group_vars_groupname_foreign; Type: FK CONSTRAINT; Schema: public; Owner: logos
--

ALTER TABLE ONLY group_vars
    ADD CONSTRAINT group_vars_groupname_foreign FOREIGN KEY (groupname) REFERENCES groups(name);


--
-- Name: host_groups_foreign_groupnames; Type: FK CONSTRAINT; Schema: public; Owner: logos
--

ALTER TABLE ONLY host_groups
    ADD CONSTRAINT host_groups_foreign_groupnames FOREIGN KEY (groupname) REFERENCES groups(name) MATCH FULL;


--
-- Name: host_groups_foreign_hostnames; Type: FK CONSTRAINT; Schema: public; Owner: logos
--

ALTER TABLE ONLY host_groups
    ADD CONSTRAINT host_groups_foreign_hostnames FOREIGN KEY (hostname) REFERENCES hostnames(hostname) MATCH FULL;


--
-- Name: host_inventory_foreign_hostnames; Type: FK CONSTRAINT; Schema: public; Owner: logos
--

ALTER TABLE ONLY host_inventory
    ADD CONSTRAINT host_inventory_foreign_hostnames FOREIGN KEY (hostname) REFERENCES hostnames(hostname);


--
-- Name: host_inventory_foreign_ipaddrs; Type: FK CONSTRAINT; Schema: public; Owner: logos
--

ALTER TABLE ONLY host_inventory
    ADD CONSTRAINT host_inventory_foreign_ipaddrs FOREIGN KEY (ipaddr) REFERENCES ipaddrs(ipaddr);


--
-- Name: host_inventory_oob_access_method_foreign_key; Type: FK CONSTRAINT; Schema: public; Owner: logos
--

ALTER TABLE ONLY host_inventory
    ADD CONSTRAINT host_inventory_oob_access_method_foreign_key FOREIGN KEY (oob_access_method) REFERENCES oob_access_methods(oob_access_method);


--
-- Name: remediation_state_foreign_key_hostname; Type: FK CONSTRAINT; Schema: public; Owner: logos
--

ALTER TABLE ONLY remediation_state
    ADD CONSTRAINT remediation_state_foreign_key_hostname FOREIGN KEY (hostname) REFERENCES hostnames(hostname);


--
-- Name: server_cpu_info_hostname_foreign_key; Type: FK CONSTRAINT; Schema: public; Owner: logos
--

ALTER TABLE ONLY server_cpu_info
    ADD CONSTRAINT server_cpu_info_hostname_foreign_key FOREIGN KEY (hostname) REFERENCES hostnames(hostname);


--
-- Name: server_disk_allocations_foreign_key_hostnames; Type: FK CONSTRAINT; Schema: public; Owner: logos
--

ALTER TABLE ONLY server_disk_allocations
    ADD CONSTRAINT server_disk_allocations_foreign_key_hostnames FOREIGN KEY (hostname) REFERENCES hostnames(hostname);


--
-- Name: server_serials_hostname_foreign_key; Type: FK CONSTRAINT; Schema: public; Owner: logos
--

ALTER TABLE ONLY server_serials
    ADD CONSTRAINT server_serials_hostname_foreign_key FOREIGN KEY (hostname) REFERENCES hostnames(hostname);


--
-- Name: public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;
GRANT USAGE ON SCHEMA public TO oracle;


--
-- Name: architectures; Type: ACL; Schema: public; Owner: logos
--

REVOKE ALL ON TABLE architectures FROM PUBLIC;
REVOKE ALL ON TABLE architectures FROM logos;
GRANT ALL ON TABLE architectures TO logos;
GRANT SELECT ON TABLE architectures TO oracle;
GRANT SELECT ON TABLE architectures TO darwin;


--
-- Name: auth_keys; Type: ACL; Schema: public; Owner: logos
--

REVOKE ALL ON TABLE auth_keys FROM PUBLIC;
REVOKE ALL ON TABLE auth_keys FROM logos;
GRANT ALL ON TABLE auth_keys TO logos;
GRANT SELECT ON TABLE auth_keys TO oracle;
GRANT SELECT ON TABLE auth_keys TO darwin;


--
-- Name: group_vars; Type: ACL; Schema: public; Owner: logos
--

REVOKE ALL ON TABLE group_vars FROM PUBLIC;
REVOKE ALL ON TABLE group_vars FROM logos;
GRANT ALL ON TABLE group_vars TO logos;
GRANT SELECT ON TABLE group_vars TO oracle;
GRANT SELECT ON TABLE group_vars TO darwin;


--
-- Name: groups; Type: ACL; Schema: public; Owner: logos
--

REVOKE ALL ON TABLE groups FROM PUBLIC;
REVOKE ALL ON TABLE groups FROM logos;
GRANT ALL ON TABLE groups TO logos;
GRANT SELECT ON TABLE groups TO oracle;
GRANT SELECT ON TABLE groups TO darwin;


--
-- Name: host_groups; Type: ACL; Schema: public; Owner: logos
--

REVOKE ALL ON TABLE host_groups FROM PUBLIC;
REVOKE ALL ON TABLE host_groups FROM logos;
GRANT ALL ON TABLE host_groups TO logos;
GRANT SELECT ON TABLE host_groups TO oracle;
GRANT SELECT ON TABLE host_groups TO darwin;


--
-- Name: host_inventory; Type: ACL; Schema: public; Owner: logos
--

REVOKE ALL ON TABLE host_inventory FROM PUBLIC;
REVOKE ALL ON TABLE host_inventory FROM logos;
GRANT ALL ON TABLE host_inventory TO logos;
GRANT SELECT ON TABLE host_inventory TO oracle;
GRANT SELECT ON TABLE host_inventory TO darwin;


--
-- Name: network_segments; Type: ACL; Schema: public; Owner: logos
--

REVOKE ALL ON TABLE network_segments FROM PUBLIC;
REVOKE ALL ON TABLE network_segments FROM logos;
GRANT ALL ON TABLE network_segments TO logos;
GRANT SELECT ON TABLE network_segments TO oracle;
GRANT SELECT ON TABLE network_segments TO darwin;


--
-- Name: server_serials; Type: ACL; Schema: public; Owner: logos
--

REVOKE ALL ON TABLE server_serials FROM PUBLIC;
REVOKE ALL ON TABLE server_serials FROM logos;
GRANT ALL ON TABLE server_serials TO logos;
GRANT SELECT ON TABLE server_serials TO oracle;
GRANT SELECT ON TABLE server_serials TO darwin;


--
-- Name: host_details; Type: ACL; Schema: public; Owner: logos
--

REVOKE ALL ON TABLE host_details FROM PUBLIC;
REVOKE ALL ON TABLE host_details FROM logos;
GRANT ALL ON TABLE host_details TO logos;
GRANT SELECT ON TABLE host_details TO oracle;
GRANT SELECT ON TABLE host_details TO darwin;


--
-- Name: hostnames; Type: ACL; Schema: public; Owner: logos
--

REVOKE ALL ON TABLE hostnames FROM PUBLIC;
REVOKE ALL ON TABLE hostnames FROM logos;
GRANT ALL ON TABLE hostnames TO logos;
GRANT SELECT ON TABLE hostnames TO oracle;
GRANT SELECT ON TABLE hostnames TO darwin;


--
-- Name: ipaddrs; Type: ACL; Schema: public; Owner: logos
--

REVOKE ALL ON TABLE ipaddrs FROM PUBLIC;
REVOKE ALL ON TABLE ipaddrs FROM logos;
GRANT ALL ON TABLE ipaddrs TO logos;
GRANT SELECT ON TABLE ipaddrs TO oracle;
GRANT SELECT ON TABLE ipaddrs TO darwin;


--
-- Name: oob_access_methods; Type: ACL; Schema: public; Owner: logos
--

REVOKE ALL ON TABLE oob_access_methods FROM PUBLIC;
REVOKE ALL ON TABLE oob_access_methods FROM logos;
GRANT ALL ON TABLE oob_access_methods TO logos;
GRANT SELECT ON TABLE oob_access_methods TO oracle;
GRANT SELECT ON TABLE oob_access_methods TO darwin;


--
-- Name: remediation_state; Type: ACL; Schema: public; Owner: logos
--

REVOKE ALL ON TABLE remediation_state FROM PUBLIC;
REVOKE ALL ON TABLE remediation_state FROM logos;
GRANT ALL ON TABLE remediation_state TO logos;
GRANT SELECT ON TABLE remediation_state TO oracle;
GRANT SELECT ON TABLE remediation_state TO darwin;


--
-- Name: server_cpu_info; Type: ACL; Schema: public; Owner: logos
--

REVOKE ALL ON TABLE server_cpu_info FROM PUBLIC;
REVOKE ALL ON TABLE server_cpu_info FROM logos;
GRANT ALL ON TABLE server_cpu_info TO logos;
GRANT SELECT ON TABLE server_cpu_info TO oracle;
GRANT SELECT ON TABLE server_cpu_info TO darwin;


--
-- Name: server_disk_allocations; Type: ACL; Schema: public; Owner: logos
--

REVOKE ALL ON TABLE server_disk_allocations FROM PUBLIC;
REVOKE ALL ON TABLE server_disk_allocations FROM logos;
GRANT ALL ON TABLE server_disk_allocations TO logos;
GRANT SELECT ON TABLE server_disk_allocations TO oracle;
GRANT SELECT ON TABLE server_disk_allocations TO darwin;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: public; Owner: logos
--

ALTER DEFAULT PRIVILEGES FOR ROLE logos IN SCHEMA public REVOKE ALL ON TABLES  FROM PUBLIC;
ALTER DEFAULT PRIVILEGES FOR ROLE logos IN SCHEMA public REVOKE ALL ON TABLES  FROM logos;
ALTER DEFAULT PRIVILEGES FOR ROLE logos IN SCHEMA public GRANT SELECT ON TABLES  TO oracle;


--
-- PostgreSQL database dump complete
--

