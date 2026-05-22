/*
 * hex.c
 *
 * Hexadecimal text I/O helpers for fixed-length byte values.
 *
 * Accepted text format: 2*LEN hex digits, optionally prefixed with "\x"
 * (matching the bytea hex format). Output is always "\xHH..HH" lower-case.
 */
#include "pg_hashvalue.h"

#include <string.h>

static inline int
hexval(char c)
{
	if (c >= '0' && c <= '9')
		return c - '0';
	if (c >= 'a' && c <= 'f')
		return c - 'a' + 10;
	if (c >= 'A' && c <= 'F')
		return c - 'A' + 10;
	return -1;
}

void
parse_hex(const char *src, uint8 *dst, int len, const char *typname)
{
	const char *p = src;
	int			i;

	/* Accept optional "\x" prefix (matches bytea hex format). */
	if (p[0] == '\\' && (p[1] == 'x' || p[1] == 'X'))
		p += 2;

	for (i = 0; i < len; i++)
	{
		int			hi = hexval(p[2 * i]);
		int			lo = hexval(p[2 * i + 1]);

		if (hi < 0 || lo < 0)
			ereport(ERROR,
					(errcode(ERRCODE_INVALID_TEXT_REPRESENTATION),
					 errmsg("invalid input syntax for type %s: \"%s\"",
							typname, src),
					 errdetail("Expected %d hexadecimal digits.", 2 * len)));

		dst[i] = (uint8) ((hi << 4) | lo);
	}

	if (p[2 * len] != '\0')
		ereport(ERROR,
				(errcode(ERRCODE_INVALID_TEXT_REPRESENTATION),
				 errmsg("invalid input syntax for type %s: \"%s\"",
						typname, src),
				 errdetail("Value must be exactly %d hexadecimal digits "
						   "(%s is %d bytes).", 2 * len, typname, len)));
}

char *
format_hex(const uint8 *src, int len)
{
	static const char hex[] = "0123456789abcdef";
	char	   *out = (char *) palloc(2 * len + 3);
	char	   *p = out;
	int			i;

	*p++ = '\\';
	*p++ = 'x';
	for (i = 0; i < len; i++)
	{
		*p++ = hex[(src[i] >> 4) & 0xF];
		*p++ = hex[src[i] & 0xF];
	}
	*p = '\0';
	return out;
}
