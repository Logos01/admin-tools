--
-- PostgreSQL database dump
--

-- Dumped from database version 9.1.11
-- Dumped by pg_dump version 9.1.11
-- Started on 2014-02-20 19:22:43 MST

SET statement_timeout = 0;
SET client_encoding = 'SQL_ASCII';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- TOC entry 2005 (class 1262 OID 16386)
-- Name: inventory; Type: DATABASE; Schema: -; Owner: logos
--

CREATE DATABASE inventory WITH TEMPLATE = template0 ENCODING = 'SQL_ASCII' LC_COLLATE = 'C' LC_CTYPE = 'C' TABLESPACE = inventory;


ALTER DATABASE inventory OWNER TO logos;

\connect inventory

SET statement_timeout = 0;
SET client_encoding = 'SQL_ASCII';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- TOC entry 186 (class 3079 OID 11645)
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- TOC entry 2008 (class 0 OID 0)
-- Dependencies: 186
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- TOC entry 178 (class 1259 OID 26184)
-- Dependencies: 6
-- Name: architectures; Type: TABLE; Schema: public; Owner: logos; Tablespace: 
--

CREATE TABLE architectures (
    primary_key integer NOT NULL,
    arch character varying(10),
    bits integer
);


ALTER TABLE public.architectures OWNER TO logos;

--
-- TOC entry 177 (class 1259 OID 26182)
-- Dependencies: 6 178
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
-- TOC entry 2010 (class 0 OID 0)
-- Dependencies: 177
-- Name: architectures_primary_key_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: logos
--

ALTER SEQUENCE architectures_primary_key_seq OWNED BY architectures.primary_key;


SET default_with_oids = true;

--
-- TOC entry 164 (class 1259 OID 16421)
-- Dependencies: 6
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
-- TOC entry 165 (class 1259 OID 16428)
-- Dependencies: 164 6
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
-- TOC entry 2012 (class 0 OID 0)
-- Dependencies: 165
-- Name: group_vars_primary_key_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: logos
--

ALTER SEQUENCE group_vars_primary_key_seq OWNED BY group_vars.primary_key;


--
-- TOC entry 162 (class 1259 OID 16405)
-- Dependencies: 1828 6
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
-- TOC entry 166 (class 1259 OID 16436)
-- Dependencies: 6 162
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
-- TOC entry 2014 (class 0 OID 0)
-- Dependencies: 166
-- Name: groups_primary_key_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: logos
--

ALTER SEQUENCE groups_primary_key_seq OWNED BY groups.primary_key;


SET default_with_oids = false;

--
-- TOC entry 163 (class 1259 OID 16412)
-- Dependencies: 6
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
-- TOC entry 161 (class 1259 OID 16387)
-- Dependencies: 1826 6
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
    arch character varying(10)
);


ALTER TABLE public.host_inventory OWNER TO logos;

--
-- TOC entry 176 (class 1259 OID 25174)
-- Dependencies: 6
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
-- TOC entry 180 (class 1259 OID 35059)
-- Dependencies: 6
-- Name: server_serials; Type: TABLE; Schema: public; Owner: logos; Tablespace: 
--

CREATE TABLE server_serials (
    hostname character varying(20),
    serial_tag character varying,
    primary_key integer NOT NULL
);


ALTER TABLE public.server_serials OWNER TO logos;

--
-- TOC entry 185 (class 1259 OID 43400)
-- Dependencies: 2000 6
-- Name: host_details; Type: VIEW; Schema: public; Owner: logos
--

CREATE VIEW host_details AS
    SELECT host_inventory.hostname, host_inventory.ipaddr, network_segments.segment_description, string_agg((host_groups.groupname)::text, ','::text) AS groupname, host_inventory.access_method, host_inventory.online, host_inventory.description, host_inventory.row_is_obsolete, host_inventory.in_dns, host_inventory.os, host_inventory.os_version, host_inventory.arch, server_serials.serial_tag, host_inventory.oob_access_method, host_inventory.oob_access_address FROM (((host_inventory LEFT JOIN network_segments ON (((network_segments.inet_segment)::inet >> (host_inventory.ipaddr)::inet))) LEFT JOIN host_groups ON (((host_groups.hostname)::text = (host_inventory.hostname)::text))) LEFT JOIN server_serials ON (((host_inventory.hostname)::text = (server_serials.hostname)::text))) GROUP BY host_inventory.hostname, host_inventory.ipaddr, network_segments.segment_description, host_inventory.access_method, host_inventory.online, host_inventory.description, host_inventory.row_is_obsolete, host_inventory.in_dns, host_inventory.os, host_inventory.os_version, host_inventory.arch, server_serials.serial_tag, host_inventory.oob_access_method, host_inventory.oob_access_address;


ALTER TABLE public.host_details OWNER TO logos;

--
-- TOC entry 172 (class 1259 OID 16602)
-- Dependencies: 6 163
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
-- TOC entry 2020 (class 0 OID 0)
-- Dependencies: 172
-- Name: host_groups_primary_key_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: logos
--

ALTER SEQUENCE host_groups_primary_key_seq OWNED BY host_groups.primary_key;


--
-- TOC entry 171 (class 1259 OID 16512)
-- Dependencies: 6 161
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
-- TOC entry 2021 (class 0 OID 0)
-- Dependencies: 171
-- Name: host_inventory_primary_key_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: logos
--

ALTER SEQUENCE host_inventory_primary_key_seq OWNED BY host_inventory.primary_key;


--
-- TOC entry 170 (class 1259 OID 16473)
-- Dependencies: 6
-- Name: hostnames; Type: TABLE; Schema: public; Owner: logos; Tablespace: 
--

CREATE TABLE hostnames (
    hostname character varying(20),
    primary_key integer NOT NULL
);


ALTER TABLE public.hostnames OWNER TO logos;

--
-- TOC entry 169 (class 1259 OID 16471)
-- Dependencies: 6 170
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
-- TOC entry 2023 (class 0 OID 0)
-- Dependencies: 169
-- Name: hostnames_primary_key_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: logos
--

ALTER SEQUENCE hostnames_primary_key_seq OWNED BY hostnames.primary_key;


--
-- TOC entry 168 (class 1259 OID 16460)
-- Dependencies: 6
-- Name: ipaddrs; Type: TABLE; Schema: public; Owner: logos; Tablespace: 
--

CREATE TABLE ipaddrs (
    ipaddr cidr NOT NULL,
    primary_key integer NOT NULL
);


ALTER TABLE public.ipaddrs OWNER TO logos;

--
-- TOC entry 167 (class 1259 OID 16458)
-- Dependencies: 168 6
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
-- TOC entry 2025 (class 0 OID 0)
-- Dependencies: 167
-- Name: ipaddrs_primary_key_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: logos
--

ALTER SEQUENCE ipaddrs_primary_key_seq OWNED BY ipaddrs.primary_key;


--
-- TOC entry 175 (class 1259 OID 25172)
-- Dependencies: 176 6
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
-- TOC entry 2026 (class 0 OID 0)
-- Dependencies: 175
-- Name: network_segments_primary_key_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: logos
--

ALTER SEQUENCE network_segments_primary_key_seq OWNED BY network_segments.primary_key;


--
-- TOC entry 174 (class 1259 OID 25157)
-- Dependencies: 6
-- Name: oob_access_methods; Type: TABLE; Schema: public; Owner: logos; Tablespace: 
--

CREATE TABLE oob_access_methods (
    primary_key integer NOT NULL,
    oob_access_method character varying(50) NOT NULL
);


ALTER TABLE public.oob_access_methods OWNER TO logos;

--
-- TOC entry 173 (class 1259 OID 25155)
-- Dependencies: 6 174
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
-- TOC entry 2028 (class 0 OID 0)
-- Dependencies: 173
-- Name: oob_access_methods_primary_key_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: logos
--

ALTER SEQUENCE oob_access_methods_primary_key_seq OWNED BY oob_access_methods.primary_key;


--
-- TOC entry 182 (class 1259 OID 43324)
-- Dependencies: 6
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
-- TOC entry 181 (class 1259 OID 43322)
-- Dependencies: 6 182
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
-- TOC entry 2030 (class 0 OID 0)
-- Dependencies: 181
-- Name: server_cpu_info_primary_key_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: logos
--

ALTER SEQUENCE server_cpu_info_primary_key_seq OWNED BY server_cpu_info.primary_key;


--
-- TOC entry 184 (class 1259 OID 43360)
-- Dependencies: 6
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
-- TOC entry 183 (class 1259 OID 43358)
-- Dependencies: 184 6
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
-- TOC entry 2032 (class 0 OID 0)
-- Dependencies: 183
-- Name: server_disk_allocations_primary_key_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: logos
--

ALTER SEQUENCE server_disk_allocations_primary_key_seq OWNED BY server_disk_allocations.primary_key;


--
-- TOC entry 179 (class 1259 OID 35057)
-- Dependencies: 180 6
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
-- TOC entry 2033 (class 0 OID 0)
-- Dependencies: 179
-- Name: server_serials_primary_key_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: logos
--

ALTER SEQUENCE server_serials_primary_key_seq OWNED BY server_serials.primary_key;


--
-- TOC entry 1836 (class 2604 OID 26187)
-- Dependencies: 177 178 178
-- Name: primary_key; Type: DEFAULT; Schema: public; Owner: logos
--

ALTER TABLE ONLY architectures ALTER COLUMN primary_key SET DEFAULT nextval('architectures_primary_key_seq'::regclass);


--
-- TOC entry 1831 (class 2604 OID 16430)
-- Dependencies: 165 164
-- Name: primary_key; Type: DEFAULT; Schema: public; Owner: logos
--

ALTER TABLE ONLY group_vars ALTER COLUMN primary_key SET DEFAULT nextval('group_vars_primary_key_seq'::regclass);


--
-- TOC entry 1829 (class 2604 OID 16438)
-- Dependencies: 166 162
-- Name: primary_key; Type: DEFAULT; Schema: public; Owner: logos
--

ALTER TABLE ONLY groups ALTER COLUMN primary_key SET DEFAULT nextval('groups_primary_key_seq'::regclass);


--
-- TOC entry 1830 (class 2604 OID 16604)
-- Dependencies: 172 163
-- Name: primary_key; Type: DEFAULT; Schema: public; Owner: logos
--

ALTER TABLE ONLY host_groups ALTER COLUMN primary_key SET DEFAULT nextval('host_groups_primary_key_seq'::regclass);


--
-- TOC entry 1827 (class 2604 OID 16514)
-- Dependencies: 171 161
-- Name: primary_key; Type: DEFAULT; Schema: public; Owner: logos
--

ALTER TABLE ONLY host_inventory ALTER COLUMN primary_key SET DEFAULT nextval('host_inventory_primary_key_seq'::regclass);


--
-- TOC entry 1833 (class 2604 OID 16476)
-- Dependencies: 169 170 170
-- Name: primary_key; Type: DEFAULT; Schema: public; Owner: logos
--

ALTER TABLE ONLY hostnames ALTER COLUMN primary_key SET DEFAULT nextval('hostnames_primary_key_seq'::regclass);


--
-- TOC entry 1832 (class 2604 OID 16463)
-- Dependencies: 168 167 168
-- Name: primary_key; Type: DEFAULT; Schema: public; Owner: logos
--

ALTER TABLE ONLY ipaddrs ALTER COLUMN primary_key SET DEFAULT nextval('ipaddrs_primary_key_seq'::regclass);


--
-- TOC entry 1835 (class 2604 OID 25177)
-- Dependencies: 176 175 176
-- Name: primary_key; Type: DEFAULT; Schema: public; Owner: logos
--

ALTER TABLE ONLY network_segments ALTER COLUMN primary_key SET DEFAULT nextval('network_segments_primary_key_seq'::regclass);


--
-- TOC entry 1834 (class 2604 OID 25160)
-- Dependencies: 174 173 174
-- Name: primary_key; Type: DEFAULT; Schema: public; Owner: logos
--

ALTER TABLE ONLY oob_access_methods ALTER COLUMN primary_key SET DEFAULT nextval('oob_access_methods_primary_key_seq'::regclass);


--
-- TOC entry 1838 (class 2604 OID 43327)
-- Dependencies: 181 182 182
-- Name: primary_key; Type: DEFAULT; Schema: public; Owner: logos
--

ALTER TABLE ONLY server_cpu_info ALTER COLUMN primary_key SET DEFAULT nextval('server_cpu_info_primary_key_seq'::regclass);


--
-- TOC entry 1839 (class 2604 OID 43363)
-- Dependencies: 184 183 184
-- Name: primary_key; Type: DEFAULT; Schema: public; Owner: logos
--

ALTER TABLE ONLY server_disk_allocations ALTER COLUMN primary_key SET DEFAULT nextval('server_disk_allocations_primary_key_seq'::regclass);


--
-- TOC entry 1837 (class 2604 OID 35062)
-- Dependencies: 180 179 180
-- Name: primary_key; Type: DEFAULT; Schema: public; Owner: logos
--

ALTER TABLE ONLY server_serials ALTER COLUMN primary_key SET DEFAULT nextval('server_serials_primary_key_seq'::regclass);


--
-- TOC entry 1866 (class 2606 OID 16478)
-- Dependencies: 170 170 2002
-- Name: PrimaryKey_hostname; Type: CONSTRAINT; Schema: public; Owner: logos; Tablespace: 
--

ALTER TABLE ONLY hostnames
    ADD CONSTRAINT "PrimaryKey_hostname" PRIMARY KEY (primary_key);


--
-- TOC entry 1862 (class 2606 OID 16468)
-- Dependencies: 168 168 2002
-- Name: PrimaryKey_ipaddrs; Type: CONSTRAINT; Schema: public; Owner: logos; Tablespace: 
--

ALTER TABLE ONLY ipaddrs
    ADD CONSTRAINT "PrimaryKey_ipaddrs" PRIMARY KEY (primary_key);


--
-- TOC entry 1878 (class 2606 OID 26193)
-- Dependencies: 178 178 2002
-- Name: architectures_arch_key; Type: CONSTRAINT; Schema: public; Owner: logos; Tablespace: 
--

ALTER TABLE ONLY architectures
    ADD CONSTRAINT architectures_arch_key UNIQUE (arch);


--
-- TOC entry 1880 (class 2606 OID 26189)
-- Dependencies: 178 178 2002
-- Name: architectures_pkey; Type: CONSTRAINT; Schema: public; Owner: logos; Tablespace: 
--

ALTER TABLE ONLY architectures
    ADD CONSTRAINT architectures_pkey PRIMARY KEY (primary_key);


--
-- TOC entry 1855 (class 2606 OID 16612)
-- Dependencies: 163 163 2002
-- Name: host_groups_primary_key; Type: CONSTRAINT; Schema: public; Owner: logos; Tablespace: 
--

ALTER TABLE ONLY host_groups
    ADD CONSTRAINT host_groups_primary_key PRIMARY KEY (primary_key);


--
-- TOC entry 1857 (class 2606 OID 25153)
-- Dependencies: 163 163 163 2002
-- Name: host_groups_unique_matching; Type: CONSTRAINT; Schema: public; Owner: logos; Tablespace: 
--

ALTER TABLE ONLY host_groups
    ADD CONSTRAINT host_groups_unique_matching UNIQUE (hostname, groupname);


--
-- TOC entry 1846 (class 2606 OID 16525)
-- Dependencies: 161 161 2002
-- Name: host_inventory_primary_key; Type: CONSTRAINT; Schema: public; Owner: logos; Tablespace: 
--

ALTER TABLE ONLY host_inventory
    ADD CONSTRAINT host_inventory_primary_key PRIMARY KEY (primary_key);


--
-- TOC entry 1870 (class 2606 OID 25162)
-- Dependencies: 174 174 2002
-- Name: oob_access_method_primary_key; Type: CONSTRAINT; Schema: public; Owner: logos; Tablespace: 
--

ALTER TABLE ONLY oob_access_methods
    ADD CONSTRAINT oob_access_method_primary_key PRIMARY KEY (primary_key);


--
-- TOC entry 1872 (class 2606 OID 25164)
-- Dependencies: 174 174 2002
-- Name: oob_access_method_uniqueness; Type: CONSTRAINT; Schema: public; Owner: logos; Tablespace: 
--

ALTER TABLE ONLY oob_access_methods
    ADD CONSTRAINT oob_access_method_uniqueness UNIQUE (oob_access_method);


--
-- TOC entry 1860 (class 2606 OID 16435)
-- Dependencies: 164 164 2002
-- Name: primary_key_group_vars; Type: CONSTRAINT; Schema: public; Owner: logos; Tablespace: 
--

ALTER TABLE ONLY group_vars
    ADD CONSTRAINT primary_key_group_vars PRIMARY KEY (primary_key);


--
-- TOC entry 1848 (class 2606 OID 16443)
-- Dependencies: 162 162 2002
-- Name: primary_key_groups; Type: CONSTRAINT; Schema: public; Owner: logos; Tablespace: 
--

ALTER TABLE ONLY groups
    ADD CONSTRAINT primary_key_groups PRIMARY KEY (primary_key);


--
-- TOC entry 1874 (class 2606 OID 25182)
-- Dependencies: 176 176 2002
-- Name: segment_list_primary_key; Type: CONSTRAINT; Schema: public; Owner: logos; Tablespace: 
--

ALTER TABLE ONLY network_segments
    ADD CONSTRAINT segment_list_primary_key PRIMARY KEY (primary_key);


--
-- TOC entry 1876 (class 2606 OID 25184)
-- Dependencies: 176 176 2002
-- Name: segment_list_unique_subnets; Type: CONSTRAINT; Schema: public; Owner: logos; Tablespace: 
--

ALTER TABLE ONLY network_segments
    ADD CONSTRAINT segment_list_unique_subnets UNIQUE (inet_segment);


--
-- TOC entry 1884 (class 2606 OID 43329)
-- Dependencies: 182 182 2002
-- Name: server_cpu_info_primary_key; Type: CONSTRAINT; Schema: public; Owner: logos; Tablespace: 
--

ALTER TABLE ONLY server_cpu_info
    ADD CONSTRAINT server_cpu_info_primary_key PRIMARY KEY (primary_key);


--
-- TOC entry 1886 (class 2606 OID 43365)
-- Dependencies: 184 184 2002
-- Name: server_disk_allocations_primary_key; Type: CONSTRAINT; Schema: public; Owner: logos; Tablespace: 
--

ALTER TABLE ONLY server_disk_allocations
    ADD CONSTRAINT server_disk_allocations_primary_key PRIMARY KEY (primary_key);


--
-- TOC entry 1888 (class 2606 OID 43367)
-- Dependencies: 184 184 184 2002
-- Name: server_disk_allocations_unique_disks_per_hostname; Type: CONSTRAINT; Schema: public; Owner: logos; Tablespace: 
--

ALTER TABLE ONLY server_disk_allocations
    ADD CONSTRAINT server_disk_allocations_unique_disks_per_hostname UNIQUE (hostname, disk_name);


--
-- TOC entry 1882 (class 2606 OID 35067)
-- Dependencies: 180 180 2002
-- Name: server_serials_primary_key; Type: CONSTRAINT; Schema: public; Owner: logos; Tablespace: 
--

ALTER TABLE ONLY server_serials
    ADD CONSTRAINT server_serials_primary_key PRIMARY KEY (primary_key);


--
-- TOC entry 1850 (class 2606 OID 16445)
-- Dependencies: 162 162 2002
-- Name: unique_group_names; Type: CONSTRAINT; Schema: public; Owner: logos; Tablespace: 
--

ALTER TABLE ONLY groups
    ADD CONSTRAINT unique_group_names UNIQUE (name);


--
-- TOC entry 1868 (class 2606 OID 16480)
-- Dependencies: 170 170 2002
-- Name: unique_hostname; Type: CONSTRAINT; Schema: public; Owner: logos; Tablespace: 
--

ALTER TABLE ONLY hostnames
    ADD CONSTRAINT unique_hostname UNIQUE (hostname);


--
-- TOC entry 1864 (class 2606 OID 16470)
-- Dependencies: 168 168 2002
-- Name: unique_ipaddrs; Type: CONSTRAINT; Schema: public; Owner: logos; Tablespace: 
--

ALTER TABLE ONLY ipaddrs
    ADD CONSTRAINT unique_ipaddrs UNIQUE (ipaddr);


--
-- TOC entry 1840 (class 1259 OID 16499)
-- Dependencies: 161 2002
-- Name: fki_Unique_ipaddrs; Type: INDEX; Schema: public; Owner: logos; Tablespace: 
--

CREATE INDEX "fki_Unique_ipaddrs" ON host_inventory USING btree (ipaddr);


--
-- TOC entry 1841 (class 1259 OID 26199)
-- Dependencies: 161 2002
-- Name: fki_arch_foreign_key; Type: INDEX; Schema: public; Owner: logos; Tablespace: 
--

CREATE INDEX fki_arch_foreign_key ON host_inventory USING btree (arch);


--
-- TOC entry 1858 (class 1259 OID 16451)
-- Dependencies: 164 2002
-- Name: fki_group_vars_groupname_foreign; Type: INDEX; Schema: public; Owner: logos; Tablespace: 
--

CREATE INDEX fki_group_vars_groupname_foreign ON group_vars USING btree (groupname);


--
-- TOC entry 1851 (class 1259 OID 16493)
-- Dependencies: 163 2002
-- Name: fki_host_groups_foreign_groupnames; Type: INDEX; Schema: public; Owner: logos; Tablespace: 
--

CREATE INDEX fki_host_groups_foreign_groupnames ON host_groups USING btree (groupname);


--
-- TOC entry 1852 (class 1259 OID 16487)
-- Dependencies: 163 2002
-- Name: fki_host_groups_foreign_hostnames; Type: INDEX; Schema: public; Owner: logos; Tablespace: 
--

CREATE INDEX fki_host_groups_foreign_hostnames ON host_groups USING btree (hostname);


--
-- TOC entry 1853 (class 1259 OID 16457)
-- Dependencies: 163 2002
-- Name: fki_host_groups_inventory_foreign; Type: INDEX; Schema: public; Owner: logos; Tablespace: 
--

CREATE INDEX fki_host_groups_inventory_foreign ON host_groups USING btree (hostname);


--
-- TOC entry 1842 (class 1259 OID 16511)
-- Dependencies: 161 2002
-- Name: fki_host_inventory_foreign_hostnames; Type: INDEX; Schema: public; Owner: logos; Tablespace: 
--

CREATE INDEX fki_host_inventory_foreign_hostnames ON host_inventory USING btree (hostname);


--
-- TOC entry 1843 (class 1259 OID 16505)
-- Dependencies: 161 2002
-- Name: fki_host_inventory_foreign_ipaddrs; Type: INDEX; Schema: public; Owner: logos; Tablespace: 
--

CREATE INDEX fki_host_inventory_foreign_ipaddrs ON host_inventory USING btree (ipaddr);


--
-- TOC entry 1844 (class 1259 OID 25170)
-- Dependencies: 161 2002
-- Name: fki_host_inventory_oob_access_method_foreign_key; Type: INDEX; Schema: public; Owner: logos; Tablespace: 
--

CREATE INDEX fki_host_inventory_oob_access_method_foreign_key ON host_inventory USING btree (oob_access_method);


--
-- TOC entry 1892 (class 2606 OID 26194)
-- Dependencies: 178 1877 161 2002
-- Name: arch_foreign_key; Type: FK CONSTRAINT; Schema: public; Owner: logos
--

ALTER TABLE ONLY host_inventory
    ADD CONSTRAINT arch_foreign_key FOREIGN KEY (arch) REFERENCES architectures(arch);


--
-- TOC entry 1895 (class 2606 OID 16446)
-- Dependencies: 1849 164 162 2002
-- Name: group_vars_groupname_foreign; Type: FK CONSTRAINT; Schema: public; Owner: logos
--

ALTER TABLE ONLY group_vars
    ADD CONSTRAINT group_vars_groupname_foreign FOREIGN KEY (groupname) REFERENCES groups(name);


--
-- TOC entry 1894 (class 2606 OID 16488)
-- Dependencies: 1849 162 163 2002
-- Name: host_groups_foreign_groupnames; Type: FK CONSTRAINT; Schema: public; Owner: logos
--

ALTER TABLE ONLY host_groups
    ADD CONSTRAINT host_groups_foreign_groupnames FOREIGN KEY (groupname) REFERENCES groups(name) MATCH FULL;


--
-- TOC entry 1893 (class 2606 OID 16482)
-- Dependencies: 1867 163 170 2002
-- Name: host_groups_foreign_hostnames; Type: FK CONSTRAINT; Schema: public; Owner: logos
--

ALTER TABLE ONLY host_groups
    ADD CONSTRAINT host_groups_foreign_hostnames FOREIGN KEY (hostname) REFERENCES hostnames(hostname) MATCH FULL;


--
-- TOC entry 1890 (class 2606 OID 16506)
-- Dependencies: 170 1867 161 2002
-- Name: host_inventory_foreign_hostnames; Type: FK CONSTRAINT; Schema: public; Owner: logos
--

ALTER TABLE ONLY host_inventory
    ADD CONSTRAINT host_inventory_foreign_hostnames FOREIGN KEY (hostname) REFERENCES hostnames(hostname);


--
-- TOC entry 1889 (class 2606 OID 16500)
-- Dependencies: 161 1863 168 2002
-- Name: host_inventory_foreign_ipaddrs; Type: FK CONSTRAINT; Schema: public; Owner: logos
--

ALTER TABLE ONLY host_inventory
    ADD CONSTRAINT host_inventory_foreign_ipaddrs FOREIGN KEY (ipaddr) REFERENCES ipaddrs(ipaddr);


--
-- TOC entry 1891 (class 2606 OID 25165)
-- Dependencies: 174 1871 161 2002
-- Name: host_inventory_oob_access_method_foreign_key; Type: FK CONSTRAINT; Schema: public; Owner: logos
--

ALTER TABLE ONLY host_inventory
    ADD CONSTRAINT host_inventory_oob_access_method_foreign_key FOREIGN KEY (oob_access_method) REFERENCES oob_access_methods(oob_access_method);


--
-- TOC entry 1897 (class 2606 OID 43330)
-- Dependencies: 182 170 1867 2002
-- Name: server_cpu_info_hostname_foreign_key; Type: FK CONSTRAINT; Schema: public; Owner: logos
--

ALTER TABLE ONLY server_cpu_info
    ADD CONSTRAINT server_cpu_info_hostname_foreign_key FOREIGN KEY (hostname) REFERENCES hostnames(hostname);


--
-- TOC entry 1898 (class 2606 OID 43368)
-- Dependencies: 170 184 1867 2002
-- Name: server_disk_allocations_foreign_key_hostnames; Type: FK CONSTRAINT; Schema: public; Owner: logos
--

ALTER TABLE ONLY server_disk_allocations
    ADD CONSTRAINT server_disk_allocations_foreign_key_hostnames FOREIGN KEY (hostname) REFERENCES hostnames(hostname);


--
-- TOC entry 1896 (class 2606 OID 35068)
-- Dependencies: 180 170 1867 2002
-- Name: server_serials_hostname_foreign_key; Type: FK CONSTRAINT; Schema: public; Owner: logos
--

ALTER TABLE ONLY server_serials
    ADD CONSTRAINT server_serials_hostname_foreign_key FOREIGN KEY (hostname) REFERENCES hostnames(hostname);


--
-- TOC entry 2007 (class 0 OID 0)
-- Dependencies: 6
-- Name: public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;
GRANT USAGE ON SCHEMA public TO oracle;


--
-- TOC entry 2009 (class 0 OID 0)
-- Dependencies: 178
-- Name: architectures; Type: ACL; Schema: public; Owner: logos
--

REVOKE ALL ON TABLE architectures FROM PUBLIC;
REVOKE ALL ON TABLE architectures FROM logos;
GRANT ALL ON TABLE architectures TO logos;
GRANT SELECT ON TABLE architectures TO oracle;


--
-- TOC entry 2011 (class 0 OID 0)
-- Dependencies: 164
-- Name: group_vars; Type: ACL; Schema: public; Owner: logos
--

REVOKE ALL ON TABLE group_vars FROM PUBLIC;
REVOKE ALL ON TABLE group_vars FROM logos;
GRANT ALL ON TABLE group_vars TO logos;
GRANT SELECT ON TABLE group_vars TO oracle;


--
-- TOC entry 2013 (class 0 OID 0)
-- Dependencies: 162
-- Name: groups; Type: ACL; Schema: public; Owner: logos
--

REVOKE ALL ON TABLE groups FROM PUBLIC;
REVOKE ALL ON TABLE groups FROM logos;
GRANT ALL ON TABLE groups TO logos;
GRANT SELECT ON TABLE groups TO oracle;


--
-- TOC entry 2015 (class 0 OID 0)
-- Dependencies: 163
-- Name: host_groups; Type: ACL; Schema: public; Owner: logos
--

REVOKE ALL ON TABLE host_groups FROM PUBLIC;
REVOKE ALL ON TABLE host_groups FROM logos;
GRANT ALL ON TABLE host_groups TO logos;
GRANT SELECT ON TABLE host_groups TO oracle;


--
-- TOC entry 2016 (class 0 OID 0)
-- Dependencies: 161
-- Name: host_inventory; Type: ACL; Schema: public; Owner: logos
--

REVOKE ALL ON TABLE host_inventory FROM PUBLIC;
REVOKE ALL ON TABLE host_inventory FROM logos;
GRANT ALL ON TABLE host_inventory TO logos;
GRANT SELECT ON TABLE host_inventory TO oracle;


--
-- TOC entry 2017 (class 0 OID 0)
-- Dependencies: 176
-- Name: network_segments; Type: ACL; Schema: public; Owner: logos
--

REVOKE ALL ON TABLE network_segments FROM PUBLIC;
REVOKE ALL ON TABLE network_segments FROM logos;
GRANT ALL ON TABLE network_segments TO logos;
GRANT SELECT ON TABLE network_segments TO oracle;


--
-- TOC entry 2018 (class 0 OID 0)
-- Dependencies: 180
-- Name: server_serials; Type: ACL; Schema: public; Owner: logos
--

REVOKE ALL ON TABLE server_serials FROM PUBLIC;
REVOKE ALL ON TABLE server_serials FROM logos;
GRANT ALL ON TABLE server_serials TO logos;
GRANT SELECT ON TABLE server_serials TO oracle;


--
-- TOC entry 2019 (class 0 OID 0)
-- Dependencies: 185
-- Name: host_details; Type: ACL; Schema: public; Owner: logos
--

REVOKE ALL ON TABLE host_details FROM PUBLIC;
REVOKE ALL ON TABLE host_details FROM logos;
GRANT ALL ON TABLE host_details TO logos;
GRANT SELECT ON TABLE host_details TO oracle;


--
-- TOC entry 2022 (class 0 OID 0)
-- Dependencies: 170
-- Name: hostnames; Type: ACL; Schema: public; Owner: logos
--

REVOKE ALL ON TABLE hostnames FROM PUBLIC;
REVOKE ALL ON TABLE hostnames FROM logos;
GRANT ALL ON TABLE hostnames TO logos;
GRANT SELECT ON TABLE hostnames TO oracle;


--
-- TOC entry 2024 (class 0 OID 0)
-- Dependencies: 168
-- Name: ipaddrs; Type: ACL; Schema: public; Owner: logos
--

REVOKE ALL ON TABLE ipaddrs FROM PUBLIC;
REVOKE ALL ON TABLE ipaddrs FROM logos;
GRANT ALL ON TABLE ipaddrs TO logos;
GRANT SELECT ON TABLE ipaddrs TO oracle;


--
-- TOC entry 2027 (class 0 OID 0)
-- Dependencies: 174
-- Name: oob_access_methods; Type: ACL; Schema: public; Owner: logos
--

REVOKE ALL ON TABLE oob_access_methods FROM PUBLIC;
REVOKE ALL ON TABLE oob_access_methods FROM logos;
GRANT ALL ON TABLE oob_access_methods TO logos;
GRANT SELECT ON TABLE oob_access_methods TO oracle;


--
-- TOC entry 2029 (class 0 OID 0)
-- Dependencies: 182
-- Name: server_cpu_info; Type: ACL; Schema: public; Owner: logos
--

REVOKE ALL ON TABLE server_cpu_info FROM PUBLIC;
REVOKE ALL ON TABLE server_cpu_info FROM logos;
GRANT ALL ON TABLE server_cpu_info TO logos;
GRANT SELECT ON TABLE server_cpu_info TO oracle;


--
-- TOC entry 2031 (class 0 OID 0)
-- Dependencies: 184
-- Name: server_disk_allocations; Type: ACL; Schema: public; Owner: logos
--

REVOKE ALL ON TABLE server_disk_allocations FROM PUBLIC;
REVOKE ALL ON TABLE server_disk_allocations FROM logos;
GRANT ALL ON TABLE server_disk_allocations TO logos;
GRANT SELECT ON TABLE server_disk_allocations TO oracle;


--
-- TOC entry 1490 (class 826 OID 35039)
-- Dependencies: 6 2002
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: public; Owner: logos
--

ALTER DEFAULT PRIVILEGES FOR ROLE logos IN SCHEMA public REVOKE ALL ON TABLES  FROM PUBLIC;
ALTER DEFAULT PRIVILEGES FOR ROLE logos IN SCHEMA public REVOKE ALL ON TABLES  FROM logos;
ALTER DEFAULT PRIVILEGES FOR ROLE logos IN SCHEMA public GRANT SELECT ON TABLES  TO oracle;


-- Completed on 2014-02-20 19:22:43 MST

--
-- PostgreSQL database dump complete
--

