CC=gcc
IDIR=../include

CFLAGS=-O2 -Wall
CFLAGS += -I$(IDIR)

#OBJ = atca-ioc-int-lib.o
DEPS = esther-trigger.h common.h
#DEPS = atca-v2-pcie-lib.h atca-v2-pci.h
LDFLAGS =    -lm
#COMMON_SRC := ./unlocked-ioct.c
#COMMON_OBJS := $(patsubst %.c, %.o, $(notdir $(COMMON_SRC)))

default: testDMA

%.o: %.c $(DEPS) Makefile
	$(CC)  -c -o $@ $< $(CFLAGS) -I$(IDIR)

get-acq-data: $(COMMON_OBJS) get-acq-data.o
	$(CC)  -pthread -o $@ $^ $(CFLAGS) -I$(IDIR)

reg_rw: reg_rw.o
	$(CC) -o $@ $<

testDMA: testDMA.o
	$(CC) -o $@ $^ $(CFLAGS) -I$(IDIR)

	#%.o: %.c
#$(CC) -c -std=c99 -o $@ $< -D_FILE_OFFSET_BITS=64 -D_GNU_SOURCE -D_LARGE_FILE_SOURCE

clean:
	rm -f  *.o *~
