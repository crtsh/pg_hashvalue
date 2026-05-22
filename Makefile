MODULE_big = pg_hashvalue
OBJS = \
	pg_hashvalue.o \
	hex.o \
	hashtypes.o \
	gist_support.o \
	spgist_support.o \
	index_support.o

EXTENSION = pg_hashvalue
DATA = pg_hashvalue--1.0.sql
PGFILEDESC = "pg_hashvalue - fixed-length SHA-256 hash type"

REGRESS = pg_hashvalue

PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)
