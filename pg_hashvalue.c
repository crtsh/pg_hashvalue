/*
 * pg_hashvalue.c
 *
 * Module entry point for the pg_hashvalue extension. The implementation
 * is split across:
 *
 *   hex.c              text I/O helpers (\x-prefixed hex)
 *   hashtypes.c        DEFINE_HASHTYPE() -- md5hash / sha1hash / sha256hash
 *   gist_support.c     bbox shell types + shared GiST helpers
 *   spgist_support.c   shared SP-GiST helpers
 *   index_support.c    per-type GiST and SP-GiST opclass entry points
 *
 * See pg_hashvalue.h for the shared declarations.
 */
#include "pg_hashvalue.h"

PG_MODULE_MAGIC;
