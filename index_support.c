/*
 * index_support.c
 *
 * Per-type entry points for the GiST and SP-GiST opclasses.
 *
 * For each hash type `name` of LEN bytes, DEFINE_HASHTYPE_INDEX_AM()
 * generates the SQL-callable C functions registered in the opclasses:
 *
 *   GiST:    name_gist_compress / consistent / union / penalty /
 *            picksplit / same
 *   SP-GiST: name_spg_config / choose / picksplit / inner_consistent /
 *            leaf_consistent
 *
 * These are thin wrappers; the actual logic lives in gist_support.c and
 * spgist_support.c.
 */
#include "pg_hashvalue.h"

#include <string.h>

#define DEFINE_HASHTYPE_INDEX_AM(name, LEN)									\
																			\
/* ---------- GiST ---------- */											\
																			\
PG_FUNCTION_INFO_V1(name##_gist_compress);									\
Datum																		\
name##_gist_compress(PG_FUNCTION_ARGS)										\
{																			\
	GISTENTRY  *e = (GISTENTRY *) PG_GETARG_POINTER(0);						\
	PG_RETURN_POINTER(gist_h_compress(e, LEN));								\
}																			\
																			\
PG_FUNCTION_INFO_V1(name##_gist_consistent);								\
Datum																		\
name##_gist_consistent(PG_FUNCTION_ARGS)									\
{																			\
	GISTENTRY  *entry = (GISTENTRY *) PG_GETARG_POINTER(0);					\
	uint8	   *q = (uint8 *) PG_GETARG_POINTER(1);							\
	StrategyNumber sn = (StrategyNumber) PG_GETARG_UINT16(2);				\
	bool	   *recheck = (bool *) PG_GETARG_POINTER(4);					\
	uint8	   *bk = (uint8 *) DatumGetPointer(entry->key);					\
	*recheck = false;														\
	PG_RETURN_BOOL(gist_h_consistent(bk, q, sn, LEN));						\
}																			\
																			\
PG_FUNCTION_INFO_V1(name##_gist_union);										\
Datum																		\
name##_gist_union(PG_FUNCTION_ARGS)											\
{																			\
	GistEntryVector *ev = (GistEntryVector *) PG_GETARG_POINTER(0);			\
	int		   *size = (int *) PG_GETARG_POINTER(1);						\
	uint8	   *out = gist_h_union(ev, LEN);								\
	*size = 2 * LEN;														\
	PG_RETURN_POINTER(out);													\
}																			\
																			\
PG_FUNCTION_INFO_V1(name##_gist_penalty);									\
Datum																		\
name##_gist_penalty(PG_FUNCTION_ARGS)										\
{																			\
	GISTENTRY  *orig = (GISTENTRY *) PG_GETARG_POINTER(0);					\
	GISTENTRY  *new_ = (GISTENTRY *) PG_GETARG_POINTER(1);					\
	float	   *result = (float *) PG_GETARG_POINTER(2);					\
	uint8	   *bo = (uint8 *) DatumGetPointer(orig->key);					\
	uint8	   *bn = (uint8 *) DatumGetPointer(new_->key);					\
	*result = gist_h_penalty(bo, bn, LEN);									\
	PG_RETURN_POINTER(result);												\
}																			\
																			\
PG_FUNCTION_INFO_V1(name##_gist_picksplit);									\
Datum																		\
name##_gist_picksplit(PG_FUNCTION_ARGS)										\
{																			\
	GistEntryVector *ev = (GistEntryVector *) PG_GETARG_POINTER(0);			\
	GIST_SPLITVEC *v = (GIST_SPLITVEC *) PG_GETARG_POINTER(1);				\
	gist_h_picksplit(ev, v, LEN);											\
	PG_RETURN_POINTER(v);													\
}																			\
																			\
PG_FUNCTION_INFO_V1(name##_gist_same);										\
Datum																		\
name##_gist_same(PG_FUNCTION_ARGS)											\
{																			\
	uint8	   *a = (uint8 *) PG_GETARG_POINTER(0);							\
	uint8	   *b = (uint8 *) PG_GETARG_POINTER(1);							\
	bool	   *result = (bool *) PG_GETARG_POINTER(2);						\
	*result = (memcmp(a, b, 2 * LEN) == 0);									\
	PG_RETURN_POINTER(result);												\
}																			\
																			\
/* ---------- SP-GiST ---------- */											\
																			\
PG_FUNCTION_INFO_V1(name##_spg_config);										\
Datum																		\
name##_spg_config(PG_FUNCTION_ARGS)											\
{																			\
	spgConfigOut *cfg = (spgConfigOut *) PG_GETARG_POINTER(1);				\
	cfg->prefixType = VOIDOID;												\
	cfg->labelType = INT2OID;												\
	cfg->canReturnData = true;												\
	cfg->longValuesOK = false;												\
	PG_RETURN_VOID();														\
}																			\
																			\
PG_FUNCTION_INFO_V1(name##_spg_choose);										\
Datum																		\
name##_spg_choose(PG_FUNCTION_ARGS)											\
{																			\
	spgChooseIn *in = (spgChooseIn *) PG_GETARG_POINTER(0);					\
	spgChooseOut *out = (spgChooseOut *) PG_GETARG_POINTER(1);				\
	uint8	   *v = (uint8 *) DatumGetPointer(in->datum);					\
	int			d = in->level;												\
	uint8		b;															\
	int			i;															\
	if (d >= LEN)															\
	{																		\
		/* All bytes consumed; descend into first child as fallback. */		\
		out->resultType = spgMatchNode;										\
		out->result.matchNode.nodeN = 0;									\
		out->result.matchNode.levelAdd = 0;									\
		out->result.matchNode.restDatum = in->datum;						\
		PG_RETURN_VOID();													\
	}																		\
	b = v[d];																\
	for (i = 0; i < in->nNodes; i++)										\
	{																		\
		if ((uint8) DatumGetInt16(in->nodeLabels[i]) == b)					\
		{																	\
			out->resultType = spgMatchNode;									\
			out->result.matchNode.nodeN = i;								\
			out->result.matchNode.levelAdd = 1;								\
			out->result.matchNode.restDatum = in->datum;					\
			PG_RETURN_VOID();												\
		}																	\
	}																		\
	out->resultType = spgAddNode;											\
	out->result.addNode.nodeLabel = Int16GetDatum((int16) b);				\
	out->result.addNode.nodeN = in->nNodes;									\
	PG_RETURN_VOID();														\
}																			\
																			\
PG_FUNCTION_INFO_V1(name##_spg_picksplit);									\
Datum																		\
name##_spg_picksplit(PG_FUNCTION_ARGS)										\
{																			\
	spgPickSplitIn *in = (spgPickSplitIn *) PG_GETARG_POINTER(0);			\
	spgPickSplitOut *out = (spgPickSplitOut *) PG_GETARG_POINTER(1);		\
	int			d = in->level;												\
	int			n = in->nTuples;											\
	int			nodemap[256];												\
	int16		labels[256];												\
	int			nnodes = 0;													\
	int			i;															\
	out->hasPrefix = false;													\
	out->mapTuplesToNodes = (int *) palloc(n * sizeof(int));				\
	out->leafTupleDatums = (Datum *) palloc(n * sizeof(Datum));				\
	for (i = 0; i < 256; i++)												\
		nodemap[i] = -1;													\
	for (i = 0; i < n; i++)													\
	{																		\
		uint8	   *v = (uint8 *) DatumGetPointer(in->datums[i]);			\
		uint8		b = (d < LEN) ? v[d] : 0;								\
		if (nodemap[b] < 0)													\
		{																	\
			nodemap[b] = nnodes;											\
			labels[nnodes] = (int16) b;										\
			nnodes++;														\
		}																	\
		out->mapTuplesToNodes[i] = nodemap[b];								\
		out->leafTupleDatums[i] = in->datums[i];							\
	}																		\
	out->nNodes = nnodes;													\
	out->nodeLabels = (Datum *) palloc(nnodes * sizeof(Datum));				\
	for (i = 0; i < nnodes; i++)											\
		out->nodeLabels[i] = Int16GetDatum(labels[i]);						\
	PG_RETURN_VOID();														\
}																			\
																			\
PG_FUNCTION_INFO_V1(name##_spg_inner_consistent);							\
Datum																		\
name##_spg_inner_consistent(PG_FUNCTION_ARGS)								\
{																			\
	spgInnerConsistentIn *in = (spgInnerConsistentIn *) PG_GETARG_POINTER(0); \
	spgInnerConsistentOut *out = (spgInnerConsistentOut *) PG_GETARG_POINTER(1); \
	int			d = in->level;												\
	int			i,															\
				j;															\
	out->nNodes = 0;														\
	out->nodeNumbers = (int *) palloc(in->nNodes * sizeof(int));			\
	out->levelAdds = (int *) palloc(in->nNodes * sizeof(int));				\
	for (i = 0; i < in->nNodes; i++)										\
	{																		\
		uint8		lb = (uint8) DatumGetInt16(in->nodeLabels[i]);			\
		bool		ok = true;												\
		for (j = 0; j < in->nkeys; j++)										\
		{																	\
			ScanKey		k = &in->scankeys[j];								\
			uint8	   *q = (uint8 *) DatumGetPointer(k->sk_argument);		\
			uint8		qb = (d < LEN) ? q[d] : 0;							\
			if (!spg_h_label_consistent(lb, qb, k->sk_strategy))			\
			{																\
				ok = false;													\
				break;														\
			}																\
		}																	\
		if (ok)																\
		{																	\
			out->nodeNumbers[out->nNodes] = i;								\
			out->levelAdds[out->nNodes] = 1;								\
			out->nNodes++;													\
		}																	\
	}																		\
	PG_RETURN_VOID();														\
}																			\
																			\
PG_FUNCTION_INFO_V1(name##_spg_leaf_consistent);							\
Datum																		\
name##_spg_leaf_consistent(PG_FUNCTION_ARGS)								\
{																			\
	spgLeafConsistentIn *in = (spgLeafConsistentIn *) PG_GETARG_POINTER(0); \
	spgLeafConsistentOut *out = (spgLeafConsistentOut *) PG_GETARG_POINTER(1); \
	uint8	   *leaf = (uint8 *) DatumGetPointer(in->leafDatum);			\
	int			j;															\
	out->recheck = false;													\
	out->leafValue = in->leafDatum;											\
	for (j = 0; j < in->nkeys; j++)											\
	{																		\
		ScanKey		k = &in->scankeys[j];									\
		uint8	   *q = (uint8 *) DatumGetPointer(k->sk_argument);			\
		if (!spg_h_leaf_consistent(leaf, q, k->sk_strategy, LEN))			\
			PG_RETURN_BOOL(false);											\
	}																		\
	PG_RETURN_BOOL(true);													\
}																			\
																			\
extern int name##_idx_force_semicolon

DEFINE_HASHTYPE_INDEX_AM(md5hash,    16);
DEFINE_HASHTYPE_INDEX_AM(sha1hash,   20);
DEFINE_HASHTYPE_INDEX_AM(sha256hash, 32);
