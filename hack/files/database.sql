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
-- Name: bounties; Type: TABLE; Schema: comunion; Owner: -
--

CREATE TABLE comunion.bounties (
    id bigint DEFAULT comunion.id_generator() NOT NULL,
    startup_id bigint NOT NULL,
    user_id bigint NOT NULL,
    title text NOT NULL,
    type text NOT NULL,
    keywords text[] NOT NULL,
    contact_email text NOT NULL,
    intro text NOT NULL,
    description_addr text NOT NULL,
    description_file_addr text,
    duration smallint NOT NULL,
    expired_at timestamp with time zone NOT NULL,
    payments jsonb DEFAULT '[]'::jsonb NOT NULL,
    status integer DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    is_closed boolean DEFAULT false,
    serial_no integer NOT NULL
);


--
-- Name: bounties_hunters_rel; Type: TABLE; Schema: comunion; Owner: -
--

CREATE TABLE comunion.bounties_hunters_rel (
    id bigint DEFAULT comunion.id_generator() NOT NULL,
    bounty_id bigint NOT NULL,
    uid bigint NOT NULL,
    status integer DEFAULT 0 NOT NULL,
    started_at timestamp with time zone,
    submitted_at timestamp with time zone,
    quited_at timestamp with time zone,
    paid_at timestamp with time zone,
    paid_tokens jsonb DEFAULT '[]'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    rejected_at timestamp with time zone
);


--
-- Name: bounties_serial_no_seq; Type: SEQUENCE; Schema: comunion; Owner: -
--

CREATE SEQUENCE comunion.bounties_serial_no_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: bounties_serial_no_seq; Type: SEQUENCE OWNED BY; Schema: comunion; Owner: -
--

ALTER SEQUENCE comunion.bounties_serial_no_seq OWNED BY comunion.bounties.serial_no;


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
-- Name: disco_investors; Type: TABLE; Schema: comunion; Owner: -
--

CREATE TABLE comunion.disco_investors (
    id bigint DEFAULT comunion.id_generator() NOT NULL,
    disco_id bigint NOT NULL,
    uid bigint NOT NULL,
    eth_count bigint NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: discos; Type: TABLE; Schema: comunion; Owner: -
--

CREATE TABLE comunion.discos (
    id bigint DEFAULT comunion.id_generator() NOT NULL,
    startup_id bigint NOT NULL,
    wallet_addr text NOT NULL,
    token_addr text NOT NULL,
    description text NOT NULL,
    fund_raising_started_at timestamp with time zone NOT NULL,
    fund_raising_ended_at timestamp with time zone NOT NULL,
    investment_reward bigint NOT NULL,
    reward_decline_rate integer NOT NULL,
    share_token bigint NOT NULL,
    min_fund_raising bigint NOT NULL,
    add_liquidity_pool bigint NOT NULL,
    total_deposit_token double precision NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    state integer DEFAULT 0 NOT NULL,
    fund_raising_addr text
);


--
-- Name: exchange_transactions; Type: TABLE; Schema: comunion; Owner: -
--

CREATE TABLE comunion.exchange_transactions (
    id bigint DEFAULT comunion.id_generator() NOT NULL,
    tx_id text NOT NULL,
    exchange_id bigint NOT NULL,
    account text NOT NULL,
    type integer NOT NULL,
    name text DEFAULT ''::text NOT NULL,
    total_value double precision DEFAULT 0 NOT NULL,
    token_amount1 double precision DEFAULT 0 NOT NULL,
    token_amount2 double precision DEFAULT 0 NOT NULL,
    fee double precision DEFAULT 0 NOT NULL,
    price_per_token1 double precision DEFAULT 0 NOT NULL,
    price_per_token2 double precision DEFAULT 0 NOT NULL,
    status integer DEFAULT 0 NOT NULL,
    occured_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: COLUMN exchange_transactions.type; Type: COMMENT; Schema: comunion; Owner: -
--

COMMENT ON COLUMN comunion.exchange_transactions.type IS '1：增加流动性，2：删除流动性，3：1兑换2，4：2兑换1';


--
-- Name: COLUMN exchange_transactions.status; Type: COMMENT; Schema: comunion; Owner: -
--

COMMENT ON COLUMN comunion.exchange_transactions.status IS '0：待确认，1：已完成，2：未完成';


--
-- Name: exchanges; Type: TABLE; Schema: comunion; Owner: -
--

CREATE TABLE comunion.exchanges (
    id bigint DEFAULT comunion.id_generator() NOT NULL,
    tx_id text NOT NULL,
    startup_id bigint NOT NULL,
    pair_name text,
    pair_address text,
    token_name1 text NOT NULL,
    token_symbol1 text NOT NULL,
    token_address1 text,
    token_name2 text NOT NULL,
    token_symbol2 text NOT NULL,
    token_address2 text,
    newest_day text,
    newest_pooled_tokens1 double precision DEFAULT 0 NOT NULL,
    newest_pooled_tokens2 double precision DEFAULT 0 NOT NULL,
    last_day text,
    last_pooled_tokens1 double precision DEFAULT 0 NOT NULL,
    last_pooled_tokens2 double precision DEFAULT 0 NOT NULL,
    price double precision DEFAULT 0 NOT NULL,
    fees double precision DEFAULT 0 NOT NULL,
    status integer DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: COLUMN exchanges.status; Type: COMMENT; Schema: comunion; Owner: -
--

COMMENT ON COLUMN comunion.exchanges.status IS '0：待确认，1：已完成，2：未完成';


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
    voter_type integer NOT NULL,
    voter_token_limit bigint,
    assigned_proposers text[],
    assigned_voters text[],
    proposer_type integer NOT NULL,
    proposer_token_limit bigint,
    proposal_supporters bigint NOT NULL,
    proposal_min_approval_percent bigint NOT NULL,
    proposal_min_duration bigint NOT NULL,
    proposal_max_duration bigint NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: COLUMN startup_setting_revisions.voter_type; Type: COMMENT; Schema: comunion; Owner: -
--

COMMENT ON COLUMN comunion.startup_setting_revisions.voter_type IS 'FounderAssign 指定人投票 持有一定数量token的人才可以投票;POS;ALL 所有人投票';


--
-- Name: COLUMN startup_setting_revisions.proposer_type; Type: COMMENT; Schema: comunion; Owner: -
--

COMMENT ON COLUMN comunion.startup_setting_revisions.proposer_type IS 'FounderAssign;POS;ALL';


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
-- Name: startups_follows_rel; Type: TABLE; Schema: comunion; Owner: -
--

CREATE TABLE comunion.startups_follows_rel (
    id bigint DEFAULT comunion.id_generator() NOT NULL,
    startup_id bigint NOT NULL,
    user_id bigint NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: tags; Type: TABLE; Schema: comunion; Owner: -
--

CREATE TABLE comunion.tags (
    id bigint DEFAULT comunion.id_generator() NOT NULL,
    name text NOT NULL,
    source text NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    deleted boolean DEFAULT false NOT NULL
);


--
-- Name: COLUMN tags.source; Type: COMMENT; Schema: comunion; Owner: -
--

COMMENT ON COLUMN comunion.tags.source IS 'skills';


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
-- Name: bounties serial_no; Type: DEFAULT; Schema: comunion; Owner: -
--

ALTER TABLE ONLY comunion.bounties ALTER COLUMN serial_no SET DEFAULT nextval('comunion.bounties_serial_no_seq'::regclass);


--
-- Name: bounties_hunters_rel bounties_hunters_rel_pk; Type: CONSTRAINT; Schema: comunion; Owner: -
--

ALTER TABLE ONLY comunion.bounties_hunters_rel
    ADD CONSTRAINT bounties_hunters_rel_pk PRIMARY KEY (id);


--
-- Name: bounties bounties_id_pk; Type: CONSTRAINT; Schema: comunion; Owner: -
--

ALTER TABLE ONLY comunion.bounties
    ADD CONSTRAINT bounties_id_pk PRIMARY KEY (id);


--
-- Name: categories categories_id_pk; Type: CONSTRAINT; Schema: comunion; Owner: -
--

ALTER TABLE ONLY comunion.categories
    ADD CONSTRAINT categories_id_pk PRIMARY KEY (id);


--
-- Name: disco_investors disco_investors_id_pk; Type: CONSTRAINT; Schema: comunion; Owner: -
--

ALTER TABLE ONLY comunion.disco_investors
    ADD CONSTRAINT disco_investors_id_pk PRIMARY KEY (id);


--
-- Name: discos discos_id_pk; Type: CONSTRAINT; Schema: comunion; Owner: -
--

ALTER TABLE ONLY comunion.discos
    ADD CONSTRAINT discos_id_pk PRIMARY KEY (id);


--
-- Name: exchange_transactions exchange_transactions_id_pk; Type: CONSTRAINT; Schema: comunion; Owner: -
--

ALTER TABLE ONLY comunion.exchange_transactions
    ADD CONSTRAINT exchange_transactions_id_pk PRIMARY KEY (id);


--
-- Name: exchanges exchanges_id_pk; Type: CONSTRAINT; Schema: comunion; Owner: -
--

ALTER TABLE ONLY comunion.exchanges
    ADD CONSTRAINT exchanges_id_pk PRIMARY KEY (id);


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
-- Name: startups_follows_rel startups_follows_rel_pk; Type: CONSTRAINT; Schema: comunion; Owner: -
--

ALTER TABLE ONLY comunion.startups_follows_rel
    ADD CONSTRAINT startups_follows_rel_pk PRIMARY KEY (id);


--
-- Name: startups startups_id_pk; Type: CONSTRAINT; Schema: comunion; Owner: -
--

ALTER TABLE ONLY comunion.startups
    ADD CONSTRAINT startups_id_pk PRIMARY KEY (id);


--
-- Name: tags tags_id_pk; Type: CONSTRAINT; Schema: comunion; Owner: -
--

ALTER TABLE ONLY comunion.tags
    ADD CONSTRAINT tags_id_pk PRIMARY KEY (id);


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
-- Name: bounties_hunters_rel_bounty_id_hunter_id; Type: INDEX; Schema: comunion; Owner: -
--

CREATE UNIQUE INDEX bounties_hunters_rel_bounty_id_hunter_id ON comunion.bounties_hunters_rel USING btree (bounty_id, uid);


--
-- Name: categories_code; Type: INDEX; Schema: comunion; Owner: -
--

CREATE UNIQUE INDEX categories_code ON comunion.categories USING btree (code);


--
-- Name: categories_name; Type: INDEX; Schema: comunion; Owner: -
--

CREATE UNIQUE INDEX categories_name ON comunion.categories USING btree (name);


--
-- Name: discos_startup_id_uindex; Type: INDEX; Schema: comunion; Owner: -
--

CREATE UNIQUE INDEX discos_startup_id_uindex ON comunion.discos USING btree (startup_id);


--
-- Name: exchange_transactions_tx_id; Type: INDEX; Schema: comunion; Owner: -
--

CREATE UNIQUE INDEX exchange_transactions_tx_id ON comunion.exchange_transactions USING btree (tx_id);


--
-- Name: exchanges_pair_address; Type: INDEX; Schema: comunion; Owner: -
--

CREATE UNIQUE INDEX exchanges_pair_address ON comunion.exchanges USING btree (pair_address);


--
-- Name: exchanges_startup_id; Type: INDEX; Schema: comunion; Owner: -
--

CREATE UNIQUE INDEX exchanges_startup_id ON comunion.exchanges USING btree (startup_id);


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
-- Name: startups_follows_rel_startup_id_user_id; Type: INDEX; Schema: comunion; Owner: -
--

CREATE UNIQUE INDEX startups_follows_rel_startup_id_user_id ON comunion.startups_follows_rel USING btree (startup_id, user_id);


--
-- Name: startups_name_idx; Type: INDEX; Schema: comunion; Owner: -
--

CREATE UNIQUE INDEX startups_name_idx ON comunion.startups USING btree (name) WHERE ((current_revision_id IS NOT NULL) AND (confirming_revision_id IS NOT NULL));


--
-- Name: tags_source_name; Type: INDEX; Schema: comunion; Owner: -
--

CREATE UNIQUE INDEX tags_source_name ON comunion.tags USING btree (source, name);


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

