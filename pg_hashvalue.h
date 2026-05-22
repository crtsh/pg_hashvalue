/*
 * pg_hashvalue.h
 *
 * Shared declarations for the pg_hashvalue extension.
 *
 * Fixed-length cryptographic hash types and their index AM support code
 * are spread across several translation units; helpers that are reused by
 * the per-type macros live here.
 */
#ifndef PG_HASHVALUE_H
#define PG_HASHVALUE_H

#include "postgres.h"

#include "access/gist.h"
#include "access/spgist.h"
#include "access/stratnum.h"
#include "fmgr.h"

/* hex.c -- text I/O helpers ------------------------------------------- */

extern void parse_hex(const char *src, uint8 *dst, int len,
					  const char *typname);
extern char *format_hex(const uint8 *src, int len);

/* gist_support.c -- shared GiST helpers -------------------------------
 *
 * GiST index keys are fixed-length 2*LEN byte bounding boxes [lo, hi] in
 * lex byte order, stored via a per-type bbox shell type so that index
 * pages hold raw bytes with no varlena header.
 */

extern GISTENTRY *gist_h_compress(GISTENTRY *entry, int len);
extern bool gist_h_consistent(const uint8 *bbox, const uint8 *q,
							  StrategyNumber sn, int len);
extern uint8 *gist_h_union(GistEntryVector *ev, int len);
extern float gist_h_penalty(const uint8 *o_bbox, const uint8 *n_bbox,
							int len);
extern void gist_h_picksplit(GistEntryVector *ev, GIST_SPLITVEC *v, int len);

/* spgist_support.c -- shared SP-GiST helpers -------------------------- */

extern bool spg_h_label_consistent(uint8 lb, uint8 qb, StrategyNumber sn);
extern bool spg_h_leaf_consistent(const uint8 *leaf, const uint8 *q,
								  StrategyNumber sn, int len);

#endif							/* PG_HASHVALUE_H */
