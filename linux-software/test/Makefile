CC=gcc
IDIR=../include

CFLAGS=-O2 -Wall
CFLAGS += -I$(IDIR)

#OBJ = atca-ioc-int-lib.o
#DEPS = atca-ioc-int-lib.h common.h
DEPS = atca-v2-pcie-lib.h atca-v2-pci.h
LDFLAGS =    -lm
COMMON_SRC := ./atca-v2-pcie-lib.c
COMMON_OBJS := $(patsubst %.c, %.o, $(notdir $(COMMON_SRC)))

default: testDMAirq

%.o: %.c $(DEPS) Makefile
	$(CC) -pthread -c -o $@ $< $(CFLAGS) -I$(IDIR)

get-acq-data: $(COMMON_OBJS) get-acq-data.o
	$(CC)  -pthread -o $@ $^ $(CFLAGS) -I$(IDIR)

testDMAirq: $(COMMON_OBJS) testDMAirq.o
	$(CC) -pthread -o $@ $^ $(CFLAGS) -I$(IDIR)

testSTREAM: $(COMMON_OBJS) testSTREAM.o
	$(CC) -o $@ $^ $(CFLAGS) -I$(IDIR)

testPolling: $(COMMON_OBJS) testPolling.o
	$(CC) -pthread -o $@ $^ $(CFLAGS) -I$(IDIR)

#testTimers: $(OBJ) testTimers.o
#	$(CC) -o $@ $^ $(CFLAGS) -I$(IDIR)

#pcimem: $(OBJ) pcimem.o
#	$(CC) -o $@ $^ $(CFLAGS) -I$(IDIR)

reg_rw: reg_rw.o
	$(CC) -o $@ $<
#%.o: %.c
#$(CC) -c -std=c99 -o $@ $< -D_FILE_OFFSET_BITS=64 -D_GNU_SOURCE -D_LARGE_FILE_SOURCE

clean:
	rm -f  *.o *~
