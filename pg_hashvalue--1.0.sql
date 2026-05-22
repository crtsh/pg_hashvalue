-- pg_hashvalue 1.0
-- Fixed-length types for md5hash (16 bytes), sha1hash (20 bytes), sha256hash (32 bytes).

\echo Use "CREATE EXTENSION pg_hashvalue" to load this file. \quit

------------------------------------------------------------
-- md5hash (16 bytes)
------------------------------------------------------------

CREATE TYPE md5hash;

CREATE FUNCTION md5hash_in(cstring) RETURNS md5hash
    AS 'MODULE_PATHNAME', 'md5hash_in'
    LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION md5hash_out(md5hash) RETURNS cstring
    AS 'MODULE_PATHNAME', 'md5hash_out'
    LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION md5hash_recv(internal) RETURNS md5hash
    AS 'MODULE_PATHNAME', 'md5hash_recv'
    LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION md5hash_send(md5hash) RETURNS bytea
    AS 'MODULE_PATHNAME', 'md5hash_send'
    LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE TYPE md5hash (
    INPUT          = md5hash_in,
    OUTPUT         = md5hash_out,
    RECEIVE        = md5hash_recv,
    SEND           = md5hash_send,
    INTERNALLENGTH = 16,
    PASSEDBYVALUE  = false,
    ALIGNMENT      = int,
    STORAGE        = plain,
    CATEGORY       = 'U'
);

CREATE FUNCTION md5hash_eq(md5hash, md5hash) RETURNS bool
    AS 'MODULE_PATHNAME', 'md5hash_eq'
    LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE LEAKPROOF;
CREATE FUNCTION md5hash_ne(md5hash, md5hash) RETURNS bool
    AS 'MODULE_PATHNAME', 'md5hash_ne'
    LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE LEAKPROOF;
CREATE FUNCTION md5hash_lt(md5hash, md5hash) RETURNS bool
    AS 'MODULE_PATHNAME', 'md5hash_lt'
    LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE LEAKPROOF;
CREATE FUNCTION md5hash_le(md5hash, md5hash) RETURNS bool
    AS 'MODULE_PATHNAME', 'md5hash_le'
    LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE LEAKPROOF;
CREATE FUNCTION md5hash_gt(md5hash, md5hash) RETURNS bool
    AS 'MODULE_PATHNAME', 'md5hash_gt'
    LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE LEAKPROOF;
CREATE FUNCTION md5hash_ge(md5hash, md5hash) RETURNS bool
    AS 'MODULE_PATHNAME', 'md5hash_ge'
    LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE LEAKPROOF;
CREATE FUNCTION md5hash_cmp(md5hash, md5hash) RETURNS int4
    AS 'MODULE_PATHNAME', 'md5hash_cmp'
    LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
CREATE FUNCTION md5hash_hash(md5hash) RETURNS int4
    AS 'MODULE_PATHNAME', 'md5hash_hash'
    LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
CREATE FUNCTION md5hash_hash_extended(md5hash, int8) RETURNS int8
    AS 'MODULE_PATHNAME', 'md5hash_hash_extended'
    LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR = (
    LEFTARG = md5hash, RIGHTARG = md5hash, PROCEDURE = md5hash_eq,
    COMMUTATOR = =, NEGATOR = <>,
    RESTRICT = eqsel, JOIN = eqjoinsel, HASHES, MERGES);
CREATE OPERATOR <> (
    LEFTARG = md5hash, RIGHTARG = md5hash, PROCEDURE = md5hash_ne,
    COMMUTATOR = <>, NEGATOR = =,
    RESTRICT = neqsel, JOIN = neqjoinsel);
CREATE OPERATOR < (
    LEFTARG = md5hash, RIGHTARG = md5hash, PROCEDURE = md5hash_lt,
    COMMUTATOR = >, NEGATOR = >=,
    RESTRICT = scalarltsel, JOIN = scalarltjoinsel);
CREATE OPERATOR <= (
    LEFTARG = md5hash, RIGHTARG = md5hash, PROCEDURE = md5hash_le,
    COMMUTATOR = >=, NEGATOR = >,
    RESTRICT = scalarlesel, JOIN = scalarlejoinsel);
CREATE OPERATOR > (
    LEFTARG = md5hash, RIGHTARG = md5hash, PROCEDURE = md5hash_gt,
    COMMUTATOR = <, NEGATOR = <=,
    RESTRICT = scalargtsel, JOIN = scalargtjoinsel);
CREATE OPERATOR >= (
    LEFTARG = md5hash, RIGHTARG = md5hash, PROCEDURE = md5hash_ge,
    COMMUTATOR = <=, NEGATOR = <,
    RESTRICT = scalargesel, JOIN = scalargejoinsel);

CREATE OPERATOR CLASS md5hash_ops
    DEFAULT FOR TYPE md5hash USING btree AS
        OPERATOR 1 < , OPERATOR 2 <= , OPERATOR 3 = ,
        OPERATOR 4 >= , OPERATOR 5 > ,
        FUNCTION 1 md5hash_cmp(md5hash, md5hash);

CREATE OPERATOR CLASS md5hash_ops
    DEFAULT FOR TYPE md5hash USING hash AS
        OPERATOR 1 = ,
        FUNCTION 1 md5hash_hash(md5hash),
        FUNCTION 2 md5hash_hash_extended(md5hash, int8);

CREATE FUNCTION md5hash_to_bytea(md5hash) RETURNS bytea
    AS 'MODULE_PATHNAME', 'md5hash_to_bytea'
    LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
CREATE FUNCTION bytea_to_md5hash(bytea) RETURNS md5hash
    AS 'MODULE_PATHNAME', 'bytea_to_md5hash'
    LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
CREATE CAST (md5hash AS bytea) WITH FUNCTION md5hash_to_bytea(md5hash) AS ASSIGNMENT;
CREATE CAST (bytea AS md5hash) WITH FUNCTION bytea_to_md5hash(bytea) AS ASSIGNMENT;

-- ---- GiST ----
-- Per-type fixed-length bbox shell type used as GiST STORAGE so that
-- index entries are stored as raw 32 bytes (no varlena header).
CREATE TYPE md5hash_bbox;
CREATE FUNCTION md5hash_bbox_in(cstring) RETURNS md5hash_bbox
    AS 'MODULE_PATHNAME', 'md5hash_bbox_in' LANGUAGE C IMMUTABLE STRICT;
CREATE FUNCTION md5hash_bbox_out(md5hash_bbox) RETURNS cstring
    AS 'MODULE_PATHNAME', 'md5hash_bbox_out' LANGUAGE C IMMUTABLE STRICT;
CREATE FUNCTION md5hash_bbox_recv(internal) RETURNS md5hash_bbox
    AS 'MODULE_PATHNAME', 'md5hash_bbox_recv' LANGUAGE C IMMUTABLE STRICT;
CREATE FUNCTION md5hash_bbox_send(md5hash_bbox) RETURNS bytea
    AS 'MODULE_PATHNAME', 'md5hash_bbox_send' LANGUAGE C IMMUTABLE STRICT;
CREATE TYPE md5hash_bbox (
    INPUT          = md5hash_bbox_in,
    OUTPUT         = md5hash_bbox_out,
    RECEIVE        = md5hash_bbox_recv,
    SEND           = md5hash_bbox_send,
    INTERNALLENGTH = 32,
    PASSEDBYVALUE  = false,
    ALIGNMENT      = int,
    STORAGE        = plain,
    CATEGORY       = 'U'
);

CREATE FUNCTION md5hash_gist_compress(internal) RETURNS internal
    AS 'MODULE_PATHNAME', 'md5hash_gist_compress' LANGUAGE C IMMUTABLE STRICT;
CREATE FUNCTION md5hash_gist_consistent(internal, md5hash, smallint, oid, internal) RETURNS bool
    AS 'MODULE_PATHNAME', 'md5hash_gist_consistent' LANGUAGE C IMMUTABLE STRICT;
CREATE FUNCTION md5hash_gist_union(internal, internal) RETURNS internal
    AS 'MODULE_PATHNAME', 'md5hash_gist_union' LANGUAGE C IMMUTABLE STRICT;
CREATE FUNCTION md5hash_gist_penalty(internal, internal, internal) RETURNS internal
    AS 'MODULE_PATHNAME', 'md5hash_gist_penalty' LANGUAGE C IMMUTABLE STRICT;
CREATE FUNCTION md5hash_gist_picksplit(internal, internal) RETURNS internal
    AS 'MODULE_PATHNAME', 'md5hash_gist_picksplit' LANGUAGE C IMMUTABLE STRICT;
CREATE FUNCTION md5hash_gist_same(internal, internal, internal) RETURNS internal
    AS 'MODULE_PATHNAME', 'md5hash_gist_same' LANGUAGE C IMMUTABLE STRICT;

CREATE OPERATOR CLASS md5hash_gist_ops
    DEFAULT FOR TYPE md5hash USING gist AS
        OPERATOR 1 < , OPERATOR 2 <= , OPERATOR 3 = ,
        OPERATOR 4 >= , OPERATOR 5 > ,
        FUNCTION 1 md5hash_gist_consistent(internal, md5hash, smallint, oid, internal),
        FUNCTION 2 md5hash_gist_union(internal, internal),
        FUNCTION 3 md5hash_gist_compress(internal),
        FUNCTION 5 md5hash_gist_penalty(internal, internal, internal),
        FUNCTION 6 md5hash_gist_picksplit(internal, internal),
        FUNCTION 7 md5hash_gist_same(internal, internal, internal),
        STORAGE md5hash_bbox;

-- ---- SP-GiST ----
CREATE FUNCTION md5hash_spg_config(internal, internal) RETURNS void
    AS 'MODULE_PATHNAME', 'md5hash_spg_config' LANGUAGE C IMMUTABLE STRICT;
CREATE FUNCTION md5hash_spg_choose(internal, internal) RETURNS void
    AS 'MODULE_PATHNAME', 'md5hash_spg_choose' LANGUAGE C IMMUTABLE STRICT;
CREATE FUNCTION md5hash_spg_picksplit(internal, internal) RETURNS void
    AS 'MODULE_PATHNAME', 'md5hash_spg_picksplit' LANGUAGE C IMMUTABLE STRICT;
CREATE FUNCTION md5hash_spg_inner_consistent(internal, internal) RETURNS void
    AS 'MODULE_PATHNAME', 'md5hash_spg_inner_consistent' LANGUAGE C IMMUTABLE STRICT;
CREATE FUNCTION md5hash_spg_leaf_consistent(internal, internal) RETURNS bool
    AS 'MODULE_PATHNAME', 'md5hash_spg_leaf_consistent' LANGUAGE C IMMUTABLE STRICT;

CREATE OPERATOR CLASS md5hash_spgist_ops
    DEFAULT FOR TYPE md5hash USING spgist AS
        OPERATOR 1 < , OPERATOR 2 <= , OPERATOR 3 = ,
        OPERATOR 4 >= , OPERATOR 5 > ,
        FUNCTION 1 md5hash_spg_config(internal, internal),
        FUNCTION 2 md5hash_spg_choose(internal, internal),
        FUNCTION 3 md5hash_spg_picksplit(internal, internal),
        FUNCTION 4 md5hash_spg_inner_consistent(internal, internal),
        FUNCTION 5 md5hash_spg_leaf_consistent(internal, internal);

-- Constructor: parse a 32-char hex string (with optional \x prefix).
CREATE FUNCTION md5hash_from_hex(text) RETURNS md5hash
    AS 'SELECT md5hash_in($1::cstring)'
    LANGUAGE SQL IMMUTABLE STRICT PARALLEL SAFE;

-- Shortcut: compute MD5 of a bytea and return it as the md5hash type.
CREATE FUNCTION calculate_md5hash(bytea) RETURNS md5hash
    AS $$ SELECT public.digest($1, 'md5')::bytea::md5hash $$
    LANGUAGE SQL IMMUTABLE STRICT PARALLEL SAFE;

------------------------------------------------------------
-- sha1hash (20 bytes)
------------------------------------------------------------

CREATE TYPE sha1hash;

CREATE FUNCTION sha1hash_in(cstring) RETURNS sha1hash
    AS 'MODULE_PATHNAME', 'sha1hash_in'
    LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sha1hash_out(sha1hash) RETURNS cstring
    AS 'MODULE_PATHNAME', 'sha1hash_out'
    LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sha1hash_recv(internal) RETURNS sha1hash
    AS 'MODULE_PATHNAME', 'sha1hash_recv'
    LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sha1hash_send(sha1hash) RETURNS bytea
    AS 'MODULE_PATHNAME', 'sha1hash_send'
    LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE TYPE sha1hash (
    INPUT          = sha1hash_in,
    OUTPUT         = sha1hash_out,
    RECEIVE        = sha1hash_recv,
    SEND           = sha1hash_send,
    INTERNALLENGTH = 20,
    PASSEDBYVALUE  = false,
    ALIGNMENT      = int,
    STORAGE        = plain,
    CATEGORY       = 'U'
);

CREATE FUNCTION sha1hash_eq(sha1hash, sha1hash) RETURNS bool
    AS 'MODULE_PATHNAME', 'sha1hash_eq'
    LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE LEAKPROOF;
CREATE FUNCTION sha1hash_ne(sha1hash, sha1hash) RETURNS bool
    AS 'MODULE_PATHNAME', 'sha1hash_ne'
    LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE LEAKPROOF;
CREATE FUNCTION sha1hash_lt(sha1hash, sha1hash) RETURNS bool
    AS 'MODULE_PATHNAME', 'sha1hash_lt'
    LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE LEAKPROOF;
CREATE FUNCTION sha1hash_le(sha1hash, sha1hash) RETURNS bool
    AS 'MODULE_PATHNAME', 'sha1hash_le'
    LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE LEAKPROOF;
CREATE FUNCTION sha1hash_gt(sha1hash, sha1hash) RETURNS bool
    AS 'MODULE_PATHNAME', 'sha1hash_gt'
    LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE LEAKPROOF;
CREATE FUNCTION sha1hash_ge(sha1hash, sha1hash) RETURNS bool
    AS 'MODULE_PATHNAME', 'sha1hash_ge'
    LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE LEAKPROOF;
CREATE FUNCTION sha1hash_cmp(sha1hash, sha1hash) RETURNS int4
    AS 'MODULE_PATHNAME', 'sha1hash_cmp'
    LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
CREATE FUNCTION sha1hash_hash(sha1hash) RETURNS int4
    AS 'MODULE_PATHNAME', 'sha1hash_hash'
    LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
CREATE FUNCTION sha1hash_hash_extended(sha1hash, int8) RETURNS int8
    AS 'MODULE_PATHNAME', 'sha1hash_hash_extended'
    LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR = (
    LEFTARG = sha1hash, RIGHTARG = sha1hash, PROCEDURE = sha1hash_eq,
    COMMUTATOR = =, NEGATOR = <>,
    RESTRICT = eqsel, JOIN = eqjoinsel, HASHES, MERGES);
CREATE OPERATOR <> (
    LEFTARG = sha1hash, RIGHTARG = sha1hash, PROCEDURE = sha1hash_ne,
    COMMUTATOR = <>, NEGATOR = =,
    RESTRICT = neqsel, JOIN = neqjoinsel);
CREATE OPERATOR < (
    LEFTARG = sha1hash, RIGHTARG = sha1hash, PROCEDURE = sha1hash_lt,
    COMMUTATOR = >, NEGATOR = >=,
    RESTRICT = scalarltsel, JOIN = scalarltjoinsel);
CREATE OPERATOR <= (
    LEFTARG = sha1hash, RIGHTARG = sha1hash, PROCEDURE = sha1hash_le,
    COMMUTATOR = >=, NEGATOR = >,
    RESTRICT = scalarlesel, JOIN = scalarlejoinsel);
CREATE OPERATOR > (
    LEFTARG = sha1hash, RIGHTARG = sha1hash, PROCEDURE = sha1hash_gt,
    COMMUTATOR = <, NEGATOR = <=,
    RESTRICT = scalargtsel, JOIN = scalargtjoinsel);
CREATE OPERATOR >= (
    LEFTARG = sha1hash, RIGHTARG = sha1hash, PROCEDURE = sha1hash_ge,
    COMMUTATOR = <=, NEGATOR = <,
    RESTRICT = scalargesel, JOIN = scalargejoinsel);

CREATE OPERATOR CLASS sha1hash_ops
    DEFAULT FOR TYPE sha1hash USING btree AS
        OPERATOR 1 < , OPERATOR 2 <= , OPERATOR 3 = ,
        OPERATOR 4 >= , OPERATOR 5 > ,
        FUNCTION 1 sha1hash_cmp(sha1hash, sha1hash);

CREATE OPERATOR CLASS sha1hash_ops
    DEFAULT FOR TYPE sha1hash USING hash AS
        OPERATOR 1 = ,
        FUNCTION 1 sha1hash_hash(sha1hash),
        FUNCTION 2 sha1hash_hash_extended(sha1hash, int8);

CREATE FUNCTION sha1hash_to_bytea(sha1hash) RETURNS bytea
    AS 'MODULE_PATHNAME', 'sha1hash_to_bytea'
    LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
CREATE FUNCTION bytea_to_sha1hash(bytea) RETURNS sha1hash
    AS 'MODULE_PATHNAME', 'bytea_to_sha1hash'
    LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
CREATE CAST (sha1hash AS bytea) WITH FUNCTION sha1hash_to_bytea(sha1hash) AS ASSIGNMENT;
CREATE CAST (bytea AS sha1hash) WITH FUNCTION bytea_to_sha1hash(bytea) AS ASSIGNMENT;

-- ---- GiST ----
CREATE TYPE sha1hash_bbox;
CREATE FUNCTION sha1hash_bbox_in(cstring) RETURNS sha1hash_bbox
    AS 'MODULE_PATHNAME', 'sha1hash_bbox_in' LANGUAGE C IMMUTABLE STRICT;
CREATE FUNCTION sha1hash_bbox_out(sha1hash_bbox) RETURNS cstring
    AS 'MODULE_PATHNAME', 'sha1hash_bbox_out' LANGUAGE C IMMUTABLE STRICT;
CREATE FUNCTION sha1hash_bbox_recv(internal) RETURNS sha1hash_bbox
    AS 'MODULE_PATHNAME', 'sha1hash_bbox_recv' LANGUAGE C IMMUTABLE STRICT;
CREATE FUNCTION sha1hash_bbox_send(sha1hash_bbox) RETURNS bytea
    AS 'MODULE_PATHNAME', 'sha1hash_bbox_send' LANGUAGE C IMMUTABLE STRICT;
CREATE TYPE sha1hash_bbox (
    INPUT          = sha1hash_bbox_in,
    OUTPUT         = sha1hash_bbox_out,
    RECEIVE        = sha1hash_bbox_recv,
    SEND           = sha1hash_bbox_send,
    INTERNALLENGTH = 40,
    PASSEDBYVALUE  = false,
    ALIGNMENT      = int,
    STORAGE        = plain,
    CATEGORY       = 'U'
);

CREATE FUNCTION sha1hash_gist_compress(internal) RETURNS internal
    AS 'MODULE_PATHNAME', 'sha1hash_gist_compress' LANGUAGE C IMMUTABLE STRICT;
CREATE FUNCTION sha1hash_gist_consistent(internal, sha1hash, smallint, oid, internal) RETURNS bool
    AS 'MODULE_PATHNAME', 'sha1hash_gist_consistent' LANGUAGE C IMMUTABLE STRICT;
CREATE FUNCTION sha1hash_gist_union(internal, internal) RETURNS internal
    AS 'MODULE_PATHNAME', 'sha1hash_gist_union' LANGUAGE C IMMUTABLE STRICT;
CREATE FUNCTION sha1hash_gist_penalty(internal, internal, internal) RETURNS internal
    AS 'MODULE_PATHNAME', 'sha1hash_gist_penalty' LANGUAGE C IMMUTABLE STRICT;
CREATE FUNCTION sha1hash_gist_picksplit(internal, internal) RETURNS internal
    AS 'MODULE_PATHNAME', 'sha1hash_gist_picksplit' LANGUAGE C IMMUTABLE STRICT;
CREATE FUNCTION sha1hash_gist_same(internal, internal, internal) RETURNS internal
    AS 'MODULE_PATHNAME', 'sha1hash_gist_same' LANGUAGE C IMMUTABLE STRICT;

CREATE OPERATOR CLASS sha1hash_gist_ops
    DEFAULT FOR TYPE sha1hash USING gist AS
        OPERATOR 1 < , OPERATOR 2 <= , OPERATOR 3 = ,
        OPERATOR 4 >= , OPERATOR 5 > ,
        FUNCTION 1 sha1hash_gist_consistent(internal, sha1hash, smallint, oid, internal),
        FUNCTION 2 sha1hash_gist_union(internal, internal),
        FUNCTION 3 sha1hash_gist_compress(internal),
        FUNCTION 5 sha1hash_gist_penalty(internal, internal, internal),
        FUNCTION 6 sha1hash_gist_picksplit(internal, internal),
        FUNCTION 7 sha1hash_gist_same(internal, internal, internal),
        STORAGE sha1hash_bbox;

-- ---- SP-GiST ----
CREATE FUNCTION sha1hash_spg_config(internal, internal) RETURNS void
    AS 'MODULE_PATHNAME', 'sha1hash_spg_config' LANGUAGE C IMMUTABLE STRICT;
CREATE FUNCTION sha1hash_spg_choose(internal, internal) RETURNS void
    AS 'MODULE_PATHNAME', 'sha1hash_spg_choose' LANGUAGE C IMMUTABLE STRICT;
CREATE FUNCTION sha1hash_spg_picksplit(internal, internal) RETURNS void
    AS 'MODULE_PATHNAME', 'sha1hash_spg_picksplit' LANGUAGE C IMMUTABLE STRICT;
CREATE FUNCTION sha1hash_spg_inner_consistent(internal, internal) RETURNS void
    AS 'MODULE_PATHNAME', 'sha1hash_spg_inner_consistent' LANGUAGE C IMMUTABLE STRICT;
CREATE FUNCTION sha1hash_spg_leaf_consistent(internal, internal) RETURNS bool
    AS 'MODULE_PATHNAME', 'sha1hash_spg_leaf_consistent' LANGUAGE C IMMUTABLE STRICT;

CREATE OPERATOR CLASS sha1hash_spgist_ops
    DEFAULT FOR TYPE sha1hash USING spgist AS
        OPERATOR 1 < , OPERATOR 2 <= , OPERATOR 3 = ,
        OPERATOR 4 >= , OPERATOR 5 > ,
        FUNCTION 1 sha1hash_spg_config(internal, internal),
        FUNCTION 2 sha1hash_spg_choose(internal, internal),
        FUNCTION 3 sha1hash_spg_picksplit(internal, internal),
        FUNCTION 4 sha1hash_spg_inner_consistent(internal, internal),
        FUNCTION 5 sha1hash_spg_leaf_consistent(internal, internal);

-- Constructor: parse a 40-char hex string (with optional \x prefix).
CREATE FUNCTION sha1hash_from_hex(text) RETURNS sha1hash
    AS 'SELECT sha1hash_in($1::cstring)'
    LANGUAGE SQL IMMUTABLE STRICT PARALLEL SAFE;

-- Shortcut: compute SHA-1 of a bytea and return it as the sha1hash type.
CREATE FUNCTION calculate_sha1hash(bytea) RETURNS sha1hash
    AS $$ SELECT public.digest($1, 'sha1')::bytea::sha1hash $$
    LANGUAGE SQL IMMUTABLE STRICT PARALLEL SAFE;

------------------------------------------------------------
-- sha256hash (32 bytes)
------------------------------------------------------------

CREATE TYPE sha256hash;

CREATE FUNCTION sha256hash_in(cstring) RETURNS sha256hash
    AS 'MODULE_PATHNAME', 'sha256hash_in'
    LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sha256hash_out(sha256hash) RETURNS cstring
    AS 'MODULE_PATHNAME', 'sha256hash_out'
    LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sha256hash_recv(internal) RETURNS sha256hash
    AS 'MODULE_PATHNAME', 'sha256hash_recv'
    LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE FUNCTION sha256hash_send(sha256hash) RETURNS bytea
    AS 'MODULE_PATHNAME', 'sha256hash_send'
    LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE TYPE sha256hash (
    INPUT          = sha256hash_in,
    OUTPUT         = sha256hash_out,
    RECEIVE        = sha256hash_recv,
    SEND           = sha256hash_send,
    INTERNALLENGTH = 32,
    PASSEDBYVALUE  = false,
    ALIGNMENT      = int,
    STORAGE        = plain,
    CATEGORY       = 'U'
);

CREATE FUNCTION sha256hash_eq(sha256hash, sha256hash) RETURNS bool
    AS 'MODULE_PATHNAME', 'sha256hash_eq'
    LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE LEAKPROOF;
CREATE FUNCTION sha256hash_ne(sha256hash, sha256hash) RETURNS bool
    AS 'MODULE_PATHNAME', 'sha256hash_ne'
    LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE LEAKPROOF;
CREATE FUNCTION sha256hash_lt(sha256hash, sha256hash) RETURNS bool
    AS 'MODULE_PATHNAME', 'sha256hash_lt'
    LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE LEAKPROOF;
CREATE FUNCTION sha256hash_le(sha256hash, sha256hash) RETURNS bool
    AS 'MODULE_PATHNAME', 'sha256hash_le'
    LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE LEAKPROOF;
CREATE FUNCTION sha256hash_gt(sha256hash, sha256hash) RETURNS bool
    AS 'MODULE_PATHNAME', 'sha256hash_gt'
    LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE LEAKPROOF;
CREATE FUNCTION sha256hash_ge(sha256hash, sha256hash) RETURNS bool
    AS 'MODULE_PATHNAME', 'sha256hash_ge'
    LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE LEAKPROOF;
CREATE FUNCTION sha256hash_cmp(sha256hash, sha256hash) RETURNS int4
    AS 'MODULE_PATHNAME', 'sha256hash_cmp'
    LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
CREATE FUNCTION sha256hash_hash(sha256hash) RETURNS int4
    AS 'MODULE_PATHNAME', 'sha256hash_hash'
    LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
CREATE FUNCTION sha256hash_hash_extended(sha256hash, int8) RETURNS int8
    AS 'MODULE_PATHNAME', 'sha256hash_hash_extended'
    LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR = (
    LEFTARG = sha256hash, RIGHTARG = sha256hash, PROCEDURE = sha256hash_eq,
    COMMUTATOR = =, NEGATOR = <>,
    RESTRICT = eqsel, JOIN = eqjoinsel, HASHES, MERGES);
CREATE OPERATOR <> (
    LEFTARG = sha256hash, RIGHTARG = sha256hash, PROCEDURE = sha256hash_ne,
    COMMUTATOR = <>, NEGATOR = =,
    RESTRICT = neqsel, JOIN = neqjoinsel);
CREATE OPERATOR < (
    LEFTARG = sha256hash, RIGHTARG = sha256hash, PROCEDURE = sha256hash_lt,
    COMMUTATOR = >, NEGATOR = >=,
    RESTRICT = scalarltsel, JOIN = scalarltjoinsel);
CREATE OPERATOR <= (
    LEFTARG = sha256hash, RIGHTARG = sha256hash, PROCEDURE = sha256hash_le,
    COMMUTATOR = >=, NEGATOR = >,
    RESTRICT = scalarlesel, JOIN = scalarlejoinsel);
CREATE OPERATOR > (
    LEFTARG = sha256hash, RIGHTARG = sha256hash, PROCEDURE = sha256hash_gt,
    COMMUTATOR = <, NEGATOR = <=,
    RESTRICT = scalargtsel, JOIN = scalargtjoinsel);
CREATE OPERATOR >= (
    LEFTARG = sha256hash, RIGHTARG = sha256hash, PROCEDURE = sha256hash_ge,
    COMMUTATOR = <=, NEGATOR = <,
    RESTRICT = scalargesel, JOIN = scalargejoinsel);

CREATE OPERATOR CLASS sha256hash_ops
    DEFAULT FOR TYPE sha256hash USING btree AS
        OPERATOR 1 < , OPERATOR 2 <= , OPERATOR 3 = ,
        OPERATOR 4 >= , OPERATOR 5 > ,
        FUNCTION 1 sha256hash_cmp(sha256hash, sha256hash);

CREATE OPERATOR CLASS sha256hash_ops
    DEFAULT FOR TYPE sha256hash USING hash AS
        OPERATOR 1 = ,
        FUNCTION 1 sha256hash_hash(sha256hash),
        FUNCTION 2 sha256hash_hash_extended(sha256hash, int8);

CREATE FUNCTION sha256hash_to_bytea(sha256hash) RETURNS bytea
    AS 'MODULE_PATHNAME', 'sha256hash_to_bytea'
    LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
CREATE FUNCTION bytea_to_sha256hash(bytea) RETURNS sha256hash
    AS 'MODULE_PATHNAME', 'bytea_to_sha256hash'
    LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
CREATE CAST (sha256hash AS bytea) WITH FUNCTION sha256hash_to_bytea(sha256hash) AS ASSIGNMENT;
CREATE CAST (bytea AS sha256hash) WITH FUNCTION bytea_to_sha256hash(bytea) AS ASSIGNMENT;

-- Shortcut: compute SHA-256 of a bytea and return it as the sha256hash type.
CREATE FUNCTION calculate_sha256hash(bytea) RETURNS sha256hash
    AS $$ SELECT public.digest($1, 'sha256')::bytea::sha256hash $$
    LANGUAGE SQL IMMUTABLE STRICT PARALLEL SAFE;

-- Constructor: parse a 64-char hex string (with optional \x prefix).
CREATE FUNCTION sha256hash_from_hex(text) RETURNS sha256hash
    AS 'SELECT sha256hash_in($1::cstring)'
    LANGUAGE SQL IMMUTABLE STRICT PARALLEL SAFE;

-- ---- GiST ----
CREATE TYPE sha256hash_bbox;
CREATE FUNCTION sha256hash_bbox_in(cstring) RETURNS sha256hash_bbox
    AS 'MODULE_PATHNAME', 'sha256hash_bbox_in' LANGUAGE C IMMUTABLE STRICT;
CREATE FUNCTION sha256hash_bbox_out(sha256hash_bbox) RETURNS cstring
    AS 'MODULE_PATHNAME', 'sha256hash_bbox_out' LANGUAGE C IMMUTABLE STRICT;
CREATE FUNCTION sha256hash_bbox_recv(internal) RETURNS sha256hash_bbox
    AS 'MODULE_PATHNAME', 'sha256hash_bbox_recv' LANGUAGE C IMMUTABLE STRICT;
CREATE FUNCTION sha256hash_bbox_send(sha256hash_bbox) RETURNS bytea
    AS 'MODULE_PATHNAME', 'sha256hash_bbox_send' LANGUAGE C IMMUTABLE STRICT;
CREATE TYPE sha256hash_bbox (
    INPUT          = sha256hash_bbox_in,
    OUTPUT         = sha256hash_bbox_out,
    RECEIVE        = sha256hash_bbox_recv,
    SEND           = sha256hash_bbox_send,
    INTERNALLENGTH = 64,
    PASSEDBYVALUE  = false,
    ALIGNMENT      = int,
    STORAGE        = plain,
    CATEGORY       = 'U'
);

CREATE FUNCTION sha256hash_gist_compress(internal) RETURNS internal
    AS 'MODULE_PATHNAME', 'sha256hash_gist_compress' LANGUAGE C IMMUTABLE STRICT;
CREATE FUNCTION sha256hash_gist_consistent(internal, sha256hash, smallint, oid, internal) RETURNS bool
    AS 'MODULE_PATHNAME', 'sha256hash_gist_consistent' LANGUAGE C IMMUTABLE STRICT;
CREATE FUNCTION sha256hash_gist_union(internal, internal) RETURNS internal
    AS 'MODULE_PATHNAME', 'sha256hash_gist_union' LANGUAGE C IMMUTABLE STRICT;
CREATE FUNCTION sha256hash_gist_penalty(internal, internal, internal) RETURNS internal
    AS 'MODULE_PATHNAME', 'sha256hash_gist_penalty' LANGUAGE C IMMUTABLE STRICT;
CREATE FUNCTION sha256hash_gist_picksplit(internal, internal) RETURNS internal
    AS 'MODULE_PATHNAME', 'sha256hash_gist_picksplit' LANGUAGE C IMMUTABLE STRICT;
CREATE FUNCTION sha256hash_gist_same(internal, internal, internal) RETURNS internal
    AS 'MODULE_PATHNAME', 'sha256hash_gist_same' LANGUAGE C IMMUTABLE STRICT;

CREATE OPERATOR CLASS sha256hash_gist_ops
    DEFAULT FOR TYPE sha256hash USING gist AS
        OPERATOR 1 < , OPERATOR 2 <= , OPERATOR 3 = ,
        OPERATOR 4 >= , OPERATOR 5 > ,
        FUNCTION 1 sha256hash_gist_consistent(internal, sha256hash, smallint, oid, internal),
        FUNCTION 2 sha256hash_gist_union(internal, internal),
        FUNCTION 3 sha256hash_gist_compress(internal),
        FUNCTION 5 sha256hash_gist_penalty(internal, internal, internal),
        FUNCTION 6 sha256hash_gist_picksplit(internal, internal),
        FUNCTION 7 sha256hash_gist_same(internal, internal, internal),
        STORAGE sha256hash_bbox;

-- ---- SP-GiST ----
CREATE FUNCTION sha256hash_spg_config(internal, internal) RETURNS void
    AS 'MODULE_PATHNAME', 'sha256hash_spg_config' LANGUAGE C IMMUTABLE STRICT;
CREATE FUNCTION sha256hash_spg_choose(internal, internal) RETURNS void
    AS 'MODULE_PATHNAME', 'sha256hash_spg_choose' LANGUAGE C IMMUTABLE STRICT;
CREATE FUNCTION sha256hash_spg_picksplit(internal, internal) RETURNS void
    AS 'MODULE_PATHNAME', 'sha256hash_spg_picksplit' LANGUAGE C IMMUTABLE STRICT;
CREATE FUNCTION sha256hash_spg_inner_consistent(internal, internal) RETURNS void
    AS 'MODULE_PATHNAME', 'sha256hash_spg_inner_consistent' LANGUAGE C IMMUTABLE STRICT;
CREATE FUNCTION sha256hash_spg_leaf_consistent(internal, internal) RETURNS bool
    AS 'MODULE_PATHNAME', 'sha256hash_spg_leaf_consistent' LANGUAGE C IMMUTABLE STRICT;

CREATE OPERATOR CLASS sha256hash_spgist_ops
    DEFAULT FOR TYPE sha256hash USING spgist AS
        OPERATOR 1 < , OPERATOR 2 <= , OPERATOR 3 = ,
        OPERATOR 4 >= , OPERATOR 5 > ,
        FUNCTION 1 sha256hash_spg_config(internal, internal),
        FUNCTION 2 sha256hash_spg_choose(internal, internal),
        FUNCTION 3 sha256hash_spg_picksplit(internal, internal),
        FUNCTION 4 sha256hash_spg_inner_consistent(internal, internal),
        FUNCTION 5 sha256hash_spg_leaf_consistent(internal, internal);
