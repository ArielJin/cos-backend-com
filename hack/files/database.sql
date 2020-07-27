--
-- PostgreSQL database dump
--

-- Dumped from database version 10.3
-- Dumped by pg_dump version 10.3

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: comunion; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA comunion;


--
-- Name: fake_id(text); Type: FUNCTION; Schema: comunion; Owner: -
--

CREATE FUNCTION comunion.fake_id(id text) RETURNS bigint
    LANGUAGE sql IMMUTABLE
    AS $_$
SELECT comunion.hex_to_int(concat(left(md5(substring(id from '(.*?)(?:-\d+)?$')), 10), coalesce(
    lpad(to_hex(substring(id from '.*-(\d+)$')::BIGINT), 4, '0')
)))
$_$;


--
-- Name: generate_date_series(timestamp with time zone, timestamp with time zone, text, text); Type: FUNCTION; Schema: comunion; Owner: -
--

CREATE FUNCTION comunion.generate_date_series(from_date timestamp with time zone, to_date timestamp with time zone, tz_time text, intval text) RETURNS SETOF timestamp with time zone
    LANGUAGE plpgsql IMMUTABLE
    AS $$
DECLARE
    r TIMESTAMPTZ;
BEGIN
    PERFORM set_config('timezone', 'UTC', FALSE);
    PERFORM set_config('timezone', (tz_time::timestamptz - tz_time::timestamp)::text, FALSE);
    FOR r IN SELECT
        date_trunc(intval, series)
    FROM generate_series(from_date , to_date-'1s'::INTERVAL, concat('1 ', intval)::interval) AS series LOOP
        RETURN NEXT r;
    END LOOP;
    RETURN;
END;
$$;


--
-- Name: hex_to_int(text); Type: FUNCTION; Schema: comunion; Owner: -
--

CREATE FUNCTION comunion.hex_to_int(id text) RETURNS bigint
    LANGUAGE plpgsql IMMUTABLE
    AS $$
DECLARE
  result BIGINT;
BEGIN
  EXECUTE 'SELECT x''' || id || '''::bigint' INTO result;
  RETURN result;
END;
$$;


--
-- Name: id_generator(); Type: FUNCTION; Schema: comunion; Owner: -
--

CREATE FUNCTION comunion.id_generator() RETURNS bigint
    LANGUAGE sql
    AS $$
		SELECT
			(((EXTRACT(EPOCH FROM clock_timestamp()) * 1000)::BIGINT - 946684800000) << 22) |
			(1 << 12) |
			(nextval('global_id_sequence') % 4096)
$$;


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: access_tokens; Type: TABLE; Schema: comunion; Owner: -
--

CREATE TABLE comunion.access_tokens (
    id bigint DEFAULT comunion.id_generator() NOT NULL,
    uid bigint NOT NULL,
    token text NOT NULL,
    refresh text NOT NULL,
    key text NOT NULL,
    secret text NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: categories; Type: TABLE; Schema: comunion; Owner: -
--

CREATE TABLE comunion.categories (
    id bigint DEFAULT comunion.id_generator() NOT NULL,
    name text NOT NULL,
    code text NOT NULL,
    source text NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted boolean DEFAULT false NOT NULL
);


--
-- Name: COLUMN categories.source; Type: COMMENT; Schema: comunion; Owner: -
--

COMMENT ON COLUMN comunion.categories.source IS 'startup';


--
-- Name: global_id_sequence; Type: SEQUENCE; Schema: comunion; Owner: -
--

CREATE SEQUENCE comunion.global_id_sequence
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hunters; Type: TABLE; Schema: comunion; Owner: -
--

CREATE TABLE comunion.hunters (
    id bigint DEFAULT comunion.id_generator() NOT NULL,
    user_id bigint NOT NULL,
    name text NOT NULL,
    skills text[] NOT NULL,
    about text NOT NULL,
    description_addr text NOT NULL,
    email text NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: startup_revisions; Type: TABLE; Schema: comunion; Owner: -
--

CREATE TABLE comunion.startup_revisions (
    id bigint DEFAULT comunion.id_generator() NOT NULL,
    startup_id bigint NOT NULL,
    name text NOT NULL,
    mission text,
    logo text NOT NULL,
    description_addr text NOT NULL,
    category_id bigint NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: startup_setting_revisions; Type: TABLE; Schema: comunion; Owner: -
--

CREATE TABLE comunion.startup_setting_revisions (
    id bigint DEFAULT comunion.id_generator() NOT NULL,
    startup_setting_id bigint NOT NULL,
    token_name text NOT NULL,
    token_symbol text NOT NULL,
    token_addr text,
    wallet_addrs jsonb DEFAULT '[]'::jsonb NOT NULL,
    type text NOT NULL,
    vote_token_limit bigint,
    vote_assign_addrs text[],
    vote_support_percent integer NOT NULL,
    vote_min_approval_percent integer NOT NULL,
    vote_min_duration_hours bigint NOT NULL,
    vote_max_duration_hours bigint NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: COLUMN startup_setting_revisions.type; Type: COMMENT; Schema: comunion; Owner: -
--

COMMENT ON COLUMN comunion.startup_setting_revisions.type IS 'FounderAssign 指定人投票 持有一定数量token的人才可以投票;POS;ALL 所有人投票';


--
-- Name: startup_settings; Type: TABLE; Schema: comunion; Owner: -
--

CREATE TABLE comunion.startup_settings (
    id bigint DEFAULT comunion.id_generator() NOT NULL,
    startup_id bigint NOT NULL,
    current_revision_id bigint,
    confirming_revision_id bigint,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: startups; Type: TABLE; Schema: comunion; Owner: -
--

CREATE TABLE comunion.startups (
    id bigint DEFAULT comunion.id_generator() NOT NULL,
    name text NOT NULL,
    uid bigint NOT NULL,
    current_revision_id bigint,
    confirming_revision_id bigint,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: transactions; Type: TABLE; Schema: comunion; Owner: -
--

CREATE TABLE comunion.transactions (
    id bigint DEFAULT comunion.id_generator() NOT NULL,
    tx_id text NOT NULL,
    block_addr text,
    source text NOT NULL,
    source_id bigint NOT NULL,
    retry_time integer DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    state integer DEFAULT 1 NOT NULL
);


--
-- Name: COLUMN transactions.state; Type: COMMENT; Schema: comunion; Owner: -
--

COMMENT ON COLUMN comunion.transactions.state IS '1 等待确认，2 已确认，3 未确认到';


--
-- Name: users; Type: TABLE; Schema: comunion; Owner: -
--

CREATE TABLE comunion.users (
    id bigint DEFAULT comunion.id_generator() NOT NULL,
    avatar text NOT NULL,
    public_key text NOT NULL,
    nonce text NOT NULL,
    public_secret text NOT NULL,
    private_secret text NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    is_hunter boolean DEFAULT false NOT NULL
);


--
-- Name: categories categories_id_pk; Type: CONSTRAINT; Schema: comunion; Owner: -
--

ALTER TABLE ONLY comunion.categories
    ADD CONSTRAINT categories_id_pk PRIMARY KEY (id);


--
-- Name: hunters hunters_id_pk; Type: CONSTRAINT; Schema: comunion; Owner: -
--

ALTER TABLE ONLY comunion.hunters
    ADD CONSTRAINT hunters_id_pk PRIMARY KEY (id);


--
-- Name: startup_revisions startup_revisions_id_pk; Type: CONSTRAINT; Schema: comunion; Owner: -
--

ALTER TABLE ONLY comunion.startup_revisions
    ADD CONSTRAINT startup_revisions_id_pk PRIMARY KEY (id);


--
-- Name: startup_setting_revisions startup_setting_revisions_id_pk; Type: CONSTRAINT; Schema: comunion; Owner: -
--

ALTER TABLE ONLY comunion.startup_setting_revisions
    ADD CONSTRAINT startup_setting_revisions_id_pk PRIMARY KEY (id);


--
-- Name: startup_settings startup_settings_id_pk; Type: CONSTRAINT; Schema: comunion; Owner: -
--

ALTER TABLE ONLY comunion.startup_settings
    ADD CONSTRAINT startup_settings_id_pk PRIMARY KEY (id);


--
-- Name: startups startups_id_pk; Type: CONSTRAINT; Schema: comunion; Owner: -
--

ALTER TABLE ONLY comunion.startups
    ADD CONSTRAINT startups_id_pk PRIMARY KEY (id);


--
-- Name: transactions transactions_id_pk; Type: CONSTRAINT; Schema: comunion; Owner: -
--

ALTER TABLE ONLY comunion.transactions
    ADD CONSTRAINT transactions_id_pk PRIMARY KEY (id);


--
-- Name: users users_id_pk; Type: CONSTRAINT; Schema: comunion; Owner: -
--

ALTER TABLE ONLY comunion.users
    ADD CONSTRAINT users_id_pk PRIMARY KEY (id);


--
-- Name: access_tokens_ak_sk_index; Type: INDEX; Schema: comunion; Owner: -
--

CREATE INDEX access_tokens_ak_sk_index ON comunion.access_tokens USING btree (key, secret);


--
-- Name: access_tokens_created_at_index; Type: INDEX; Schema: comunion; Owner: -
--

CREATE INDEX access_tokens_created_at_index ON comunion.access_tokens USING btree (created_at);


--
-- Name: access_tokens_refresh_uindex; Type: INDEX; Schema: comunion; Owner: -
--

CREATE UNIQUE INDEX access_tokens_refresh_uindex ON comunion.access_tokens USING btree (refresh);


--
-- Name: categories_code; Type: INDEX; Schema: comunion; Owner: -
--

CREATE UNIQUE INDEX categories_code ON comunion.categories USING btree (code);


--
-- Name: categories_name; Type: INDEX; Schema: comunion; Owner: -
--

CREATE UNIQUE INDEX categories_name ON comunion.categories USING btree (name);


--
-- Name: hunters_user_id_uindex; Type: INDEX; Schema: comunion; Owner: -
--

CREATE UNIQUE INDEX hunters_user_id_uindex ON comunion.hunters USING btree (user_id);


--
-- Name: startup_revisions_startup_id_idx; Type: INDEX; Schema: comunion; Owner: -
--

CREATE INDEX startup_revisions_startup_id_idx ON comunion.startup_revisions USING btree (startup_id);


--
-- Name: startup_setting_revisions_startup_setting_id_idx; Type: INDEX; Schema: comunion; Owner: -
--

CREATE INDEX startup_setting_revisions_startup_setting_id_idx ON comunion.startup_setting_revisions USING btree (startup_setting_id);


--
-- Name: startup_settings_startup_id; Type: INDEX; Schema: comunion; Owner: -
--

CREATE UNIQUE INDEX startup_settings_startup_id ON comunion.startup_settings USING btree (startup_id);


--
-- Name: startups_name_idx; Type: INDEX; Schema: comunion; Owner: -
--

CREATE UNIQUE INDEX startups_name_idx ON comunion.startups USING btree (name) WHERE ((current_revision_id IS NOT NULL) AND (confirming_revision_id IS NOT NULL));


--
-- Name: transactions_tx_id; Type: INDEX; Schema: comunion; Owner: -
--

CREATE UNIQUE INDEX transactions_tx_id ON comunion.transactions USING btree (tx_id) WHERE (state <> 3);


--
-- Name: users_public_key; Type: INDEX; Schema: comunion; Owner: -
--

CREATE UNIQUE INDEX users_public_key ON comunion.users USING btree (public_key);


--
-- PostgreSQL database dump complete
--

