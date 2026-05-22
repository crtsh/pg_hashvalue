/*
 * hashtypes.c
 *
 * Per-type instantiation of the SQL-callable functions for the three
 * fixed-length cryptographic hash types: md5hash (16 bytes),
 * sha1hash (20 bytes), sha256hash (32 bytes).
 *
 * For each type `name` of LEN bytes, DEFINE_HASHTYPE() generates:
 *   - I/O (in/out/recv/send)
 *   - comparison operators (eq/ne/lt/le/gt/ge/cmp)
 *   - hash support (hash, hash_extended)
 *   - bytea casts (name_to_bytea, bytea_to_name)
 *
 * Each type is declared in SQL with:
 *     INTERNALLENGTH = <N>
 *     PASSEDBYVALUE  = false
 *     ALIGNMENT      = int     (4-byte; each length is a multiple of 4)
 *     STORAGE        = plain
 *
 * Because INTERNALLENGTH > 0 the type is fixed-length, so PostgreSQL stores
 * the raw bytes inline with no varlena length word and never considers it
 * for TOAST/compression. A Datum for the type is simply a pointer to those
 * bytes -- no PG_DETOAST_DATUM, no VARSIZE() decoding on access.
 */
#include "pg_hashvalue.h"

#include "common/hashfn.h"
#include "libpq/pqformat.h"
#include "utils/bytea.h"

#include <string.h>

#define DEFINE_HASHTYPE(name, LEN)											\
																			\
PG_FUNCTION_INFO_V1(name##_in);												\
Datum																		\
name##_in(PG_FUNCTION_ARGS)													\
{																			\
	char	   *src = PG_GETARG_CSTRING(0);									\
	uint8	   *result = (uint8 *) palloc(LEN);								\
	parse_hex(src, result, LEN, #name);										\
	PG_RETURN_POINTER(result);												\
}																			\
																			\
PG_FUNCTION_INFO_V1(name##_out);											\
Datum																		\
name##_out(PG_FUNCTION_ARGS)												\
{																			\
	uint8	   *v = (uint8 *) PG_GETARG_POINTER(0);							\
	PG_RETURN_CSTRING(format_hex(v, LEN));									\
}																			\
																			\
PG_FUNCTION_INFO_V1(name##_recv);											\
Datum																		\
name##_recv(PG_FUNCTION_ARGS)												\
{																			\
	StringInfo	buf = (StringInfo) PG_GETARG_POINTER(0);					\
	uint8	   *result = (uint8 *) palloc(LEN);								\
	pq_copymsgbytes(buf, (char *) result, LEN);								\
	PG_RETURN_POINTER(result);												\
}																			\
																			\
PG_FUNCTION_INFO_V1(name##_send);											\
Datum																		\
name##_send(PG_FUNCTION_ARGS)												\
{																			\
	uint8	   *v = (uint8 *) PG_GETARG_POINTER(0);							\
	StringInfoData buf;														\
	pq_begintypsend(&buf);													\
	pq_sendbytes(&buf, (const char *) v, LEN);								\
	PG_RETURN_BYTEA_P(pq_endtypsend(&buf));									\
}																			\
																			\
PG_FUNCTION_INFO_V1(name##_eq);												\
Datum																		\
name##_eq(PG_FUNCTION_ARGS)													\
{																			\
	uint8	   *a = (uint8 *) PG_GETARG_POINTER(0);							\
	uint8	   *b = (uint8 *) PG_GETARG_POINTER(1);							\
	PG_RETURN_BOOL(memcmp(a, b, LEN) == 0);									\
}																			\
																			\
PG_FUNCTION_INFO_V1(name##_ne);												\
Datum																		\
name##_ne(PG_FUNCTION_ARGS)													\
{																			\
	uint8	   *a = (uint8 *) PG_GETARG_POINTER(0);							\
	uint8	   *b = (uint8 *) PG_GETARG_POINTER(1);							\
	PG_RETURN_BOOL(memcmp(a, b, LEN) != 0);									\
}																			\
																			\
PG_FUNCTION_INFO_V1(name##_lt);												\
Datum																		\
name##_lt(PG_FUNCTION_ARGS)													\
{																			\
	uint8	   *a = (uint8 *) PG_GETARG_POINTER(0);							\
	uint8	   *b = (uint8 *) PG_GETARG_POINTER(1);							\
	PG_RETURN_BOOL(memcmp(a, b, LEN) < 0);									\
}																			\
																			\
PG_FUNCTION_INFO_V1(name##_le);												\
Datum																		\
name##_le(PG_FUNCTION_ARGS)													\
{																			\
	uint8	   *a = (uint8 *) PG_GETARG_POINTER(0);							\
	uint8	   *b = (uint8 *) PG_GETARG_POINTER(1);							\
	PG_RETURN_BOOL(memcmp(a, b, LEN) <= 0);									\
}																			\
																			\
PG_FUNCTION_INFO_V1(name##_gt);												\
Datum																		\
name##_gt(PG_FUNCTION_ARGS)													\
{																			\
	uint8	   *a = (uint8 *) PG_GETARG_POINTER(0);							\
	uint8	   *b = (uint8 *) PG_GETARG_POINTER(1);							\
	PG_RETURN_BOOL(memcmp(a, b, LEN) > 0);									\
}																			\
																			\
PG_FUNCTION_INFO_V1(name##_ge);												\
Datum																		\
name##_ge(PG_FUNCTION_ARGS)													\
{																			\
	uint8	   *a = (uint8 *) PG_GETARG_POINTER(0);							\
	uint8	   *b = (uint8 *) PG_GETARG_POINTER(1);							\
	PG_RETURN_BOOL(memcmp(a, b, LEN) >= 0);									\
}																			\
																			\
PG_FUNCTION_INFO_V1(name##_cmp);											\
Datum																		\
name##_cmp(PG_FUNCTION_ARGS)												\
{																			\
	uint8	   *a = (uint8 *) PG_GETARG_POINTER(0);							\
	uint8	   *b = (uint8 *) PG_GETARG_POINTER(1);							\
	PG_RETURN_INT32(memcmp(a, b, LEN));										\
}																			\
																			\
PG_FUNCTION_INFO_V1(name##_hash);											\
Datum																		\
name##_hash(PG_FUNCTION_ARGS)												\
{																			\
	uint8	   *v = (uint8 *) PG_GETARG_POINTER(0);							\
	PG_RETURN_DATUM(hash_any(v, LEN));										\
}																			\
																			\
PG_FUNCTION_INFO_V1(name##_hash_extended);									\
Datum																		\
name##_hash_extended(PG_FUNCTION_ARGS)										\
{																			\
	uint8	   *v = (uint8 *) PG_GETARG_POINTER(0);							\
	uint64		seed = PG_GETARG_INT64(1);									\
	PG_RETURN_DATUM(hash_any_extended(v, LEN, seed));						\
}																			\
																			\
PG_FUNCTION_INFO_V1(name##_to_bytea);										\
Datum																		\
name##_to_bytea(PG_FUNCTION_ARGS)											\
{																			\
	uint8	   *v = (uint8 *) PG_GETARG_POINTER(0);							\
	bytea	   *result = (bytea *) palloc(VARHDRSZ + LEN);					\
	SET_VARSIZE(result, VARHDRSZ + LEN);									\
	memcpy(VARDATA(result), v, LEN);										\
	PG_RETURN_BYTEA_P(result);												\
}																			\
																			\
PG_FUNCTION_INFO_V1(bytea_to_##name);										\
Datum																		\
bytea_to_##name(PG_FUNCTION_ARGS)											\
{																			\
	bytea	   *src = PG_GETARG_BYTEA_PP(0);								\
	uint8	   *result;														\
	if (VARSIZE_ANY_EXHDR(src) != LEN)										\
		ereport(ERROR,														\
				(errcode(ERRCODE_INVALID_BINARY_REPRESENTATION),			\
				 errmsg("cannot cast bytea of length %d to %s",				\
						(int) VARSIZE_ANY_EXHDR(src), #name)));				\
	result = (uint8 *) palloc(LEN);											\
	memcpy(result, VARDATA_ANY(src), LEN);									\
	PG_RETURN_POINTER(result);												\
}																			\
																			\
extern int name##_force_semicolon

DEFINE_HASHTYPE(md5hash,    16);
DEFINE_HASHTYPE(sha1hash,   20);
DEFINE_HASHTYPE(sha256hash, 32);
