# pg_hashvalue

Efficient fixed-length storage and indexing of cryptographic hash values
in PostgreSQL.

`pg_hashvalue` provides three new PostgreSQL data types — `md5hash`,
`sha1hash`, and `sha256hash` — that store the raw bytes of an MD5, SHA-1,
or SHA-256 digest inline, with no variable-length (varlena) header. The
extension ships full operator support (equality, ordering, hashing) and
four index access methods (btree, hash, GiST, SP-GiST) for each type.

---

## Why?

The obvious alternative — storing hash digests in a `bytea` column — works
but has measurable overhead:

* Every value carries a 1- or 4-byte **varlena length header**, even though
  the length is statically known.
* Every read goes through `PG_DETOAST_DATUM` / `VARSIZE_ANY_EXHDR`
  decoding.
* The planner cannot use the type itself as a correctness guarantee that
  the value is exactly 16 / 20 / 32 bytes long.

The `pg_hashvalue` types are declared with `INTERNALLENGTH = N`,
`PASSEDBYVALUE = false`, `ALIGNMENT = int`, `STORAGE = plain`, so they are
**fixed-length pass-by-reference**. A `Datum` is simply a pointer to the
N raw bytes — no header, no TOAST consideration, no length decoding on
access. Indexes (including GiST, via per-type bounding-box shell types)
also store the raw bytes only.

Bytes are bytes — the extension performs no hashing of its own (apart from
the optional `calculate_*hash(bytea)` shortcuts that delegate to
pgcrypto). You can populate these columns from any source: pgcrypto,
application code, a network protocol, a hardware module, etc.

---

## Installation

Requires PostgreSQL 13 or later (developed and tested against 18). The
extension uses only long-stable C and SQL APIs; the `trusted = true` flag
in the control file is the newest thing it depends on, and that has been
available since PostgreSQL 13. The contrib `pgcrypto` extension must also
be available, but it is only used by the `calculate_*hash` shortcut
functions — if you populate the columns from another source you do not
need pgcrypto at runtime.

```sh
make
sudo make install
```

The build uses PGXS and honours `PG_CONFIG`:

```sh
make PG_CONFIG=/path/to/pg_config
```

Then, in a database:

```sql
CREATE EXTENSION pg_hashvalue CASCADE;
```

`CASCADE` is recommended because the extension declares
`requires = 'pgcrypto'`. The extension is marked `trusted`, so a
non-superuser with `CREATE` on the database can install it.

To run the regression test:

```sh
sudo -u postgres psql -X -f sql/pg_hashvalue.sql
```

---

## Types

| Type         | Length   | Alignment | Storage |
| ------------ | -------- | --------- | ------- |
| `md5hash`    | 16 bytes | 4         | plain   |
| `sha1hash`   | 20 bytes | 4         | plain   |
| `sha256hash` | 32 bytes | 4         | plain   |

### Text I/O

Input accepts either a bare hex string of exactly `2*N` digits or the
same string prefixed with `\x` (matching the bytea hex format). Output
is always `\x` followed by lower-case hex.

```sql
SELECT '\xd41d8cd98f00b204e9800998ecf8427e'::md5hash;
--  \xd41d8cd98f00b204e9800998ecf8427e

SELECT 'd41d8cd98f00b204e9800998ecf8427e'::md5hash;
--  \xd41d8cd98f00b204e9800998ecf8427e
```

Invalid input is rejected with a clear error:

```
ERROR:  invalid input syntax for type md5hash: "short"
DETAIL:  Expected 32 hexadecimal digits.
```

### Binary I/O

`send` / `recv` transmit the raw N bytes. This is also the on-the-wire
format used by the binary COPY protocol and libpq's binary parameters.

---

## API

In the function lists below, `<T>` stands for any of `md5hash`,
`sha1hash`, `sha256hash`, with `LEN` equal to 16 / 20 / 32 respectively.

### Operators

For each type `<T>`:

| Operator | Returns   | Description           |
| -------- | --------- | --------------------- |
| `=`      | `boolean` | Equal                 |
| `<>`     | `boolean` | Not equal             |
| `<`      | `boolean` | Less (lex byte order) |
| `<=`     | `boolean` | Less or equal         |
| `>`      | `boolean` | Greater               |
| `>=`     | `boolean` | Greater or equal      |

All comparisons are unsigned, byte-wise, lexicographic — the same order
as `memcmp()` on the raw bytes.

### Constructors

```sql
md5hash_from_hex(text)    RETURNS md5hash
sha1hash_from_hex(text)   RETURNS sha1hash
sha256hash_from_hex(text) RETURNS sha256hash
```

The `_from_hex` suffix avoids a name clash with `pg_catalog.md5(text)`,
which already exists and returns `text`.

### Convenience: compute-and-wrap (pgcrypto wrappers)

```sql
calculate_md5hash(bytea)    RETURNS md5hash
calculate_sha1hash(bytea)   RETURNS sha1hash
calculate_sha256hash(bytea) RETURNS sha256hash
```

Each calls `pgcrypto`'s `digest()` and casts the result to the matching
fixed-length type:

```sql
SELECT calculate_sha256hash(convert_to('hello', 'UTF8'));
--  \x2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824
```

These three functions are the only place where the extension uses
`pgcrypto`. If you populate the columns from another source, you do not
need pgcrypto at runtime — but `CREATE EXTENSION` still requires it
because of the `requires = 'pgcrypto'` line in the control file.

### Bytea interoperability

Binary casts in both directions:

```sql
SELECT '\xd41d8cd98f00b204e9800998ecf8427e'::md5hash::bytea;
SELECT ('\xda39a3ee5e6b4b0d3255bfef95601890afd80709'::bytea)::sha1hash;
```

A bytea of the wrong length is rejected:

```
ERROR:  cannot cast bytea of length 17 to md5hash
```

---

## Indexing

Every type has default opclasses for all four general-purpose index AMs.
You can build any of them without specifying an opclass:

```sql
CREATE INDEX ON t USING btree  (h);
CREATE INDEX ON t USING hash   (h);
CREATE INDEX ON t USING gist   (h);
CREATE INDEX ON t USING spgist (h);
```

### btree

Standard `cmp` / `eq` support functions. Best choice for equality
lookups and ordered scans.

### hash

`hash` and `hash_extended` use the same in-server `hash_any` /
`hash_any_extended` as the rest of PostgreSQL, computed directly over
the raw N bytes (no length prefix). Suitable for hash joins and hash
indexes.

### GiST

The opclass stores a 2·N-byte bounding box `[lo, hi]` per inner key, in
lex byte order. Leaves are compressed from the indexed type by
replicating the value as `lo = hi`.

To keep index pages free of varlena overhead, each hash type has a
companion fixed-length shell type used as the GiST `STORAGE`:

| Hash type    | bbox type         | bbox length |
| ------------ | ----------------- | ----------- |
| `md5hash`    | `md5hash_bbox`    | 32 bytes    |
| `sha1hash`   | `sha1hash_bbox`   | 40 bytes    |
| `sha256hash` | `sha256hash_bbox` | 64 bytes    |

You should not need to construct bbox values directly. They are exposed
to SQL only because PostgreSQL requires a real type for `STORAGE`.

GiST is useful for range scans (`<`, `<=`, `>=`, `>`) on hash values.
For pure equality workloads, btree or hash will be faster.

### SP-GiST

Implemented as a 256-way **byte radix tree**: each inner node at depth
D discriminates on byte D of the value via an `int2` label (0..255).
Leaves store the full N-byte value. No prefix compression — random
hashes don't share prefixes worth exploiting, and skipping the prefix
machinery keeps each scan step branch-free.

Like GiST, SP-GiST leaves store the raw N bytes with no varlena header.

---

## Storage layout

For a SHA-256 column, every row stores exactly 32 bytes for the column
itself (plus the table's normal per-tuple overhead). Compare:

| Column type     | Bytes per value (on disk)             |
| --------------- | ------------------------------------- |
| `sha256hash`    | 32                                    |
| `bytea`         | 1 + 32 (short header)                 |
| `text` (64 hex) | 1 + 64                                |

Indexes on `sha256hash` store the same fixed 32 / 64 bytes (GiST bbox)
with no per-entry length word.

---

## Source layout

The C implementation is split across small translation units linked
together into a single `MODULE_big = pg_hashvalue`:

| File               | Purpose                                         |
| ------------------ | ----------------------------------------------- |
| `pg_hashvalue.h`   | Shared declarations                             |
| `pg_hashvalue.c`   | Module entry (`PG_MODULE_MAGIC`)                |
| `hex.c`            | Hex text I/O helpers (`parse_hex`/`format_hex`) |
| `hashtypes.c`      | `DEFINE_HASHTYPE` macro + the three types       |
| `gist_support.c`   | bbox shell types + shared GiST helpers          |
| `spgist_support.c` | Shared SP-GiST helpers                          |
| `index_support.c`  | Per-type GiST/SP-GiST opclass entry points      |

The macros `DEFINE_HASHTYPE`, `DEFINE_BBOX_TYPE` and
`DEFINE_HASHTYPE_INDEX_AM` keep each hash type's wiring isolated to a
single line in each file, so adding (for example) a `sha512hash` would
mean three new macro invocations in three files and a corresponding
block in `pg_hashvalue--1.0.sql`.

---

## Limitations and design notes

* The extension is intentionally narrow: it does **not** compute hashes
  in C, register CRC or non-cryptographic hash types, or provide
  HMAC / streaming digest APIs. Use pgcrypto, application code, or a
  dedicated extension for those.
* `ALIGNMENT = int` (4 bytes) is sufficient because all three lengths
  are multiples of 4. The bytes are otherwise treated as opaque, so
  alignment never has to be widened. `ALIGNMENT = double` would cost up
  to 7 bytes of leading padding per row (vs up to 3) while buying no
  real speed: `memcmp` / `hash_any` over 16–32 bytes handle unaligned
  access at full speed on every CPU PostgreSQL supports, and index
  tuples are already `MAXALIGN`'d at their start, so the first attribute
  is often 8-byte-aligned for free.
* Comparison and hashing operate directly on the raw bytes via
  `memcmp` / `hash_any`, so the cost is essentially that of a memory
  compare or a 32/64-bit hash of N bytes.
* The GiST penalty function approximates "width" by treating the first
  4 bytes of `lo` and `hi` as big-endian `uint32`. This is a heuristic
  and is fine for uniformly-distributed cryptographic hash values; it
  is not intended for adversarial or strongly-clustered inputs.

---

## License

See [LICENSE](LICENSE).
