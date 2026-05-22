/*
 * gist_support.c
 *
 * GiST opclass support for the fixed-length hash types.
 *
 * Bounding-box shell types
 * ------------------------
 * For each hash type `T` of LEN bytes, this file also defines a companion
 * type `T_bbox` of 2*LEN bytes (the [lo, hi] index key) declared in SQL
 * with INTERNALLENGTH = 2*LEN, PASSEDBYVALUE = false, ALIGNMENT = int,
 * STORAGE = plain, so GiST index pages store the key as raw bytes -- no
 * varlena header, no TOAST consideration.
 *
 * Users won't normally construct bbox values directly; the I/O functions
 * exist because CREATE TYPE requires them. Text format is 4*LEN hex
 * digits (with optional "\x" prefix).
 *
 * Shared GiST helpers
 * -------------------
 * gist_h_compress / gist_h_consistent / gist_h_union / gist_h_penalty /
 * gist_h_picksplit operate on raw uint8 pointers (LEN-byte values for
 * leaves on input, 2*LEN-byte bboxes for inner keys). The per-type entry
 * points generated in index_support.c are thin wrappers around these.
 */
#include "pg_hashvalue.h"

#include "libpq/pqformat.h"

#include <string.h>

/* =========================================================================
 * Bounding-box shell types
 * =========================================================================
 */
#define DEFINE_BBOX_TYPE(name, LEN)											\
																			\
PG_FUNCTION_INFO_V1(name##_bbox_in);										\
Datum																		\
name##_bbox_in(PG_FUNCTION_ARGS)											\
{																			\
	char	   *src = PG_GETARG_CSTRING(0);									\
	uint8	   *result = (uint8 *) palloc(2 * LEN);							\
	parse_hex(src, result, 2 * LEN, #name "_bbox");							\
	PG_RETURN_POINTER(result);												\
}																			\
																			\
PG_FUNCTION_INFO_V1(name##_bbox_out);										\
Datum																		\
name##_bbox_out(PG_FUNCTION_ARGS)											\
{																			\
	uint8	   *v = (uint8 *) PG_GETARG_POINTER(0);							\
	PG_RETURN_CSTRING(format_hex(v, 2 * LEN));								\
}																			\
																			\
PG_FUNCTION_INFO_V1(name##_bbox_recv);										\
Datum																		\
name##_bbox_recv(PG_FUNCTION_ARGS)											\
{																			\
	StringInfo	buf = (StringInfo) PG_GETARG_POINTER(0);					\
	uint8	   *result = (uint8 *) palloc(2 * LEN);							\
	pq_copymsgbytes(buf, (char *) result, 2 * LEN);							\
	PG_RETURN_POINTER(result);												\
}																			\
																			\
PG_FUNCTION_INFO_V1(name##_bbox_send);										\
Datum																		\
name##_bbox_send(PG_FUNCTION_ARGS)											\
{																			\
	uint8	   *v = (uint8 *) PG_GETARG_POINTER(0);							\
	StringInfoData buf;														\
	pq_begintypsend(&buf);													\
	pq_sendbytes(&buf, (const char *) v, 2 * LEN);							\
	PG_RETURN_BYTEA_P(pq_endtypsend(&buf));									\
}																			\
																			\
extern int name##_bbox_force_semicolon

DEFINE_BBOX_TYPE(md5hash,    16);
DEFINE_BBOX_TYPE(sha1hash,   20);
DEFINE_BBOX_TYPE(sha256hash, 32);

/* =========================================================================
 * Shared GiST helpers
 *
 * Index key is a fixed-length 2*LEN byte bounding box [lo, hi] in lex byte
 * order. Leaves are compressed from the indexed type (LEN bytes) by
 * replicating the value as lo = hi.
 * =========================================================================
 */

typedef struct
{
	OffsetNumber off;
	const uint8 *bbox;
} gist_pickitem;

static int
gist_pickcmp(const void *a, const void *b, void *arg)
{
	int			len = *(const int *) arg;
	const gist_pickitem *pa = (const gist_pickitem *) a;
	const gist_pickitem *pb = (const gist_pickitem *) b;

	return memcmp(pa->bbox, pb->bbox, len);
}

GISTENTRY *
gist_h_compress(GISTENTRY *entry, int len)
{
	GISTENTRY  *retval;

	if (entry->leafkey)
	{
		uint8	   *v = (uint8 *) DatumGetPointer(entry->key);
		uint8	   *key = (uint8 *) palloc(2 * len);

		memcpy(key, v, len);
		memcpy(key + len, v, len);

		retval = (GISTENTRY *) palloc(sizeof(GISTENTRY));
		gistentryinit(*retval, PointerGetDatum(key),
					  entry->rel, entry->page, entry->offset, false);
		return retval;
	}
	return entry;
}

bool
gist_h_consistent(const uint8 *bbox, const uint8 *q,
				  StrategyNumber sn, int len)
{
	const uint8 *lo = bbox;
	const uint8 *hi = bbox + len;

	switch (sn)
	{
		case BTLessStrategyNumber:
			return memcmp(lo, q, len) < 0;
		case BTLessEqualStrategyNumber:
			return memcmp(lo, q, len) <= 0;
		case BTEqualStrategyNumber:
			return memcmp(lo, q, len) <= 0 && memcmp(q, hi, len) <= 0;
		case BTGreaterEqualStrategyNumber:
			return memcmp(hi, q, len) >= 0;
		case BTGreaterStrategyNumber:
			return memcmp(hi, q, len) > 0;
	}
	return false;
}

uint8 *
gist_h_union(GistEntryVector *ev, int len)
{
	uint8	   *out = (uint8 *) palloc(2 * len);
	uint8	   *first = (uint8 *) DatumGetPointer(ev->vector[0].key);
	int			i;

	memcpy(out, first, 2 * len);
	for (i = 1; i < ev->n; i++)
	{
		uint8	   *k = (uint8 *) DatumGetPointer(ev->vector[i].key);

		if (memcmp(k, out, len) < 0)
			memcpy(out, k, len);
		if (memcmp(k + len, out + len, len) > 0)
			memcpy(out + len, k + len, len);
	}
	return out;
}

static inline uint32
read_u32_be(const uint8 *p)
{
	return ((uint32) p[0] << 24) | ((uint32) p[1] << 16) |
		((uint32) p[2] << 8) | (uint32) p[3];
}

float
gist_h_penalty(const uint8 *o_bbox, const uint8 *n_bbox, int len)
{
	/* Approximate "width" using the first 4 bytes of lo/hi as uint32 BE. */
	uint32		olo = read_u32_be(o_bbox);
	uint32		ohi = read_u32_be(o_bbox + len);
	uint32		nlo = read_u32_be(n_bbox);
	uint32		nhi = read_u32_be(n_bbox + len);
	uint32		ulo = Min(olo, nlo);
	uint32		uhi = Max(ohi, nhi);

	return (float) ((double) uhi - (double) ulo) -
		(float) ((double) ohi - (double) olo);
}

void
gist_h_picksplit(GistEntryVector *ev, GIST_SPLITVEC *v, int len)
{
	OffsetNumber maxoff = ev->n - 1;
	int			n = (int) maxoff;
	int			i,
				mid;
	gist_pickitem *items;
	uint8	   *l_bbox,
			   *r_bbox;

	if (n <= 0)
		elog(ERROR, "pg_hashvalue: picksplit called with no entries");

	items = (gist_pickitem *) palloc(n * sizeof(gist_pickitem));
	for (i = 0; i < n; i++)
	{
		OffsetNumber off = (OffsetNumber) (i + FirstOffsetNumber);

		items[i].off = off;
		items[i].bbox = (const uint8 *) DatumGetPointer(ev->vector[off].key);
	}
	qsort_arg(items, n, sizeof(gist_pickitem), gist_pickcmp, &len);

	mid = n / 2;
	if (mid == 0)
		mid = 1;

	v->spl_left = (OffsetNumber *) palloc((n + 1) * sizeof(OffsetNumber));
	v->spl_right = (OffsetNumber *) palloc((n + 1) * sizeof(OffsetNumber));
	v->spl_nleft = 0;
	v->spl_nright = 0;

	l_bbox = (uint8 *) palloc(2 * len);
	r_bbox = (uint8 *) palloc(2 * len);

	memcpy(l_bbox, items[0].bbox, 2 * len);
	for (i = 0; i < mid; i++)
	{
		const uint8 *k = items[i].bbox;

		if (memcmp(k, l_bbox, len) < 0)
			memcpy(l_bbox, k, len);
		if (memcmp(k + len, l_bbox + len, len) > 0)
			memcpy(l_bbox + len, k + len, len);
		v->spl_left[v->spl_nleft++] = items[i].off;
	}
	memcpy(r_bbox, items[mid].bbox, 2 * len);
	for (i = mid; i < n; i++)
	{
		const uint8 *k = items[i].bbox;

		if (memcmp(k, r_bbox, len) < 0)
			memcpy(r_bbox, k, len);
		if (memcmp(k + len, r_bbox + len, len) > 0)
			memcpy(r_bbox + len, k + len, len);
		v->spl_right[v->spl_nright++] = items[i].off;
	}

	v->spl_ldatum = PointerGetDatum(l_bbox);
	v->spl_rdatum = PointerGetDatum(r_bbox);
}
