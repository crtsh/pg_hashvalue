CREATE EXTENSION pg_hashvalue CASCADE;

-- Verify fixed-length, varlena-bypass storage settings
SELECT typname, typlen, typbyval, typalign, typstorage
FROM   pg_type
WHERE  typname IN ('md5hash', 'sha1hash', 'sha256hash')
ORDER  BY typlen;

-- md5hash
SELECT '\xd41d8cd98f00b204e9800998ecf8427e'::md5hash;
SELECT 'd41d8cd98f00b204e9800998ecf8427e'::md5hash;
SELECT 'short'::md5hash;

-- sha1hash
SELECT '\xda39a3ee5e6b4b0d3255bfef95601890afd80709'::sha1hash;
SELECT 'da39a3ee5e6b4b0d3255bfef95601890afd80709'::sha1hash;

-- sha256hash
SELECT '\xe3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855'::sha256hash;

-- Comparisons across types
SELECT '\x00000000000000000000000000000001'::md5hash
     < '\x00000000000000000000000000000002'::md5hash;
SELECT '\x0000000000000000000000000000000000000001'::sha1hash
     = '\x0000000000000000000000000000000000000001'::sha1hash;
SELECT '\x0000000000000000000000000000000000000000000000000000000000000001'::sha256hash
     < '\x0000000000000000000000000000000000000000000000000000000000000002'::sha256hash;

-- bytea round-trip
SELECT '\xd41d8cd98f00b204e9800998ecf8427e'::md5hash::bytea;
SELECT ('\xda39a3ee5e6b4b0d3255bfef95601890afd80709'::bytea)::sha1hash;

-- Indexed table
CREATE TABLE t (
    h_md5hash    md5hash,
    h_sha1hash   sha1hash,
    h_sha256hash sha256hash
);

INSERT INTO t
SELECT calculate_md5hash(convert_to(g::text, 'UTF8')),
       calculate_sha1hash(convert_to(g::text, 'UTF8')),
       calculate_sha256hash(convert_to(g::text, 'UTF8'))
FROM   generate_series(1, 1000) g;

CREATE INDEX ON t USING btree (h_md5hash);
CREATE INDEX ON t USING hash  (h_md5hash);
CREATE INDEX ON t USING gist  (h_md5hash);
CREATE INDEX ON t USING spgist (h_md5hash);
CREATE INDEX ON t USING btree (h_sha1hash);
CREATE INDEX ON t USING hash  (h_sha1hash);
CREATE INDEX ON t USING gist  (h_sha1hash);
CREATE INDEX ON t USING spgist (h_sha1hash);
CREATE INDEX ON t USING btree (h_sha256hash);
CREATE INDEX ON t USING hash  (h_sha256hash);
CREATE INDEX ON t USING gist  (h_sha256hash);
CREATE INDEX ON t USING spgist (h_sha256hash);

SET enable_seqscan = off;
SELECT count(*) FROM t WHERE h_sha256hash = (SELECT h_sha256hash FROM t LIMIT 1);
SELECT count(*) FROM t WHERE h_sha1hash   = (SELECT h_sha1hash   FROM t LIMIT 1);
SELECT count(*) FROM t WHERE h_md5hash    = (SELECT h_md5hash    FROM t LIMIT 1);
RESET enable_seqscan;

SELECT count(*) FROM t;
SELECT h_sha256hash FROM t ORDER BY h_sha256hash LIMIT 1;

DROP TABLE t;
