################################################################################
#
# ESTHER TRIGGER   Linux driver
# This program is free software; you can redistribute it and/or modify it
# under the terms and conditions of the GNU General Public License,
# version 2, as published by the Free Software Foundation.
#
# This program is distributed in the hope it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along with
# this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin St - Fifth Floor, Boston, MA 02110-1301 USA.
#
# The full GNU General Public License is included in this distribution in
# the file called "COPYING".
#
# Contact Information:
#
# Instituto de Plasmas e Fusao Nuclear, Instituto Superior Tecnico,
# Universidade  de Lisboa, 1049-001 Lisboa, Portugal.
#
################################################################################

###########################################################################
# Driver files

# core driver files

DRIVER_NAME := esther_trg
#atca_ioc_w7x_intrlck

TARGET := $(DRIVER_NAME).ko
CFILES :=  esther-trigger-drv.c unlocked-ioctl.c

KVER = $(shell uname -r)
KDIR = /lib/modules/$(KVER)/build
PWD = $(shell pwd)
#DEST = /lib/modules/$(KVER)/kernel/$(MDIR)


$(DRIVER_NAME)-objs := $(CFILES:.c=.o)
obj-m := $(DRIVER_NAME).o

# set the install path
INSTDIR := /lib/modules/$(KVER)/kernel/drivers/pci/pcie

# Comment/uncomment the following line to disable/enable debugging
DEBUG = y

# Add your debugging flag (or not) to CFLAGS
ifeq ($(DEBUG),y)
  DEBFLAGS = -O -g -DESTHER_DEBUG # "-O" is needed to expand inlines
else
  DEBFLAGS = -O2
endif

EXTRA_CFLAGS += -I$(LDDINC)
EXTRA_CFLAGS += $(DEBFLAGS)

#all:
default:
	$(MAKE) -C $(KDIR) M=$(PWD) LDDINC=$(PWD)/../include modules
clean:
	rm -f *.o *.ko .*.cmd .*.flags *.mod.c

install: default #
#         # remove all old versions of the driver
	find /lib/modules/$(KVER) -name $(TARGET) -exec rm -f {} \; || true
	install -D -m 644 $(TARGET) $(INSTDIR)/$(TARGET)
	/sbin/depmod -a || true
	install -m 0644   esther_trg.rules /etc/udev/rules.d

uninstall: clean
	find /lib/modules/$(KVER) -name $(TARGET) -exec rm -f {} \; || true
	/sbin/depmod -a || true
	find /etc/udev/rules.d -name esther_trg -exec rm -f {} \; || true
