/*
 * spgist_support.c
 *
 * Shared SP-GiST helpers for the fixed-length hash types.
 *
 * 256-way byte radix tree. Each inner node at depth D discriminates on
 * byte D of the value via an int2 label (0..255). Leaves store the full
 * LEN-byte value. No prefix compression (random hashes share no prefixes
 * worth exploiting).
 */
#include "pg_hashvalue.h"

#include <string.h>

bool
spg_h_label_consistent(uint8 lb, uint8 qb, StrategyNumber sn)
{
	switch (sn)
	{
		case BTLessStrategyNumber:
		case BTLessEqualStrategyNumber:
			return lb <= qb;
		case BTEqualStrategyNumber:
			return lb == qb;
		case BTGreaterEqualStrategyNumber:
		case BTGreaterStrategyNumber:
			return lb >= qb;
	}
	return false;
}

bool
spg_h_leaf_consistent(const uint8 *leaf, const uint8 *q,
					  StrategyNumber sn, int len)
{
	int			cmp = memcmp(leaf, q, len);

	switch (sn)
	{
		case BTLessStrategyNumber:
			return cmp < 0;
		case BTLessEqualStrategyNumber:
			return cmp <= 0;
		case BTEqualStrategyNumber:
			return cmp == 0;
		case BTGreaterEqualStrategyNumber:
			return cmp >= 0;
		case BTGreaterStrategyNumber:
			return cmp > 0;
	}
	return false;
}
