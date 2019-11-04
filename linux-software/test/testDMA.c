/**
 * PCIe Vivado Project General  Test DMA
 * Project Name:
 * Design Name:
 * FW Version
 * working  with kernel 4.xx
 *
 *
 * Copyright 2014 - 2019 IPFN-Instituto Superior Tecnico, Portugal
 * Creation Date  2014-02-10
 *
 * Licensed under the EUPL, Version 1.1 or - as soon they
 * will be approved by the European Commission - subsequent
 * versions of the EUPL (the "Licence");
 * You may not use this work except in compliance with the
 * Licence.
 * You may obtain a copy of the Licence at:
 *
 * http://ec.europa.eu/idabc/eupl
 *
 * Unless required by applicable law or agreed to in
 * writing, software distributed under the Licence is
 * distributed on an "AS IS" basis,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
 * express or implied.
 * See the Licence for the specific language governing
 * permissions and limitations under the Licence.
 *
 */

#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <unistd.h>
//#include <sys/types.h>
//#include <sys/stat.h>
#include <fcntl.h>
#include <sys/ioctl.h>
//#include <linux/types.h>
/*#include <math.h>*/
//#include <signal.h>
#include "esther-trigger-ioctl.h"
#include "esther-trigger.h"
#include <string.h>

/*#define ACQ_SIZE (8 * 1024) // 2048*/

char DEVNAME[] = "/dev/esther_trg_0";
/*
   void get_data(int32_t *pAdcDataWr, void *dmaBuff) {
   DMA_PCKT *pdma = (DMA_PCKT *)dmaBuff;
   for (int s = 0; s < PCK_N_SAMPLES; s++) {
   for (int j = 0; j < ADC_CHANNELS; j++)
 *pAdcDataWr++ = pdma->samp[s].channel[j].adc_data;
 }
 }
 */

int main(int argc, char **argv) {

  int rc, fd, i;
  char *devn;
  int flags = 0;
  FILE *fdi;
  // for data
  /*unsigned int Npackets = 1;*/
  unsigned int noSave = 0;
  void *dmaBuff;
  /*int32_t *pAdcData;*/
  /*int32_t *pAdcDataWr;*/
  u_int32_t dStat;
  int32_t dmaSize;
  struct esther_trig_config esther_cfg;

  if (argc > 2)
    devn = argv[2];
  else
    devn = DEVNAME;

  if (argc > 1) {
    noSave = atoi(argv[1]);
  }
  /*printf("argc %d, noSave %d \n", argc, noSave);*/
  /*else {*/
  /*printf("%s  [nosave [dev_name]]\n", argv[0]);*/
  /*return -1;*/
  /*}*/
  flags |= O_RDONLY;
  printf("opening device\t");
  extern int errno;
  fd = open(devn, flags);

  if (fd < 0) {
    fprintf(stderr, "Error: cannot open device %s \n", devn);
    fprintf(stderr, " errno = %i\n", errno);
    printf("open error : %s\n", strerror(errno));
    exit(1);
  }
  printf("device opened: \n"); // /Opening the device
  dmaSize = 0;
  rc = ioctl(fd, ESTHER_TRG_IOCG_DMA_SIZE, &dmaSize);
  printf("dmaSize: %d \n", dmaSize); //

  for (i = 0; i < ADC_CHANNELS; i++)
    esther_cfg.trglevel[i] = 0;
  esther_cfg.trglevel[0] = 5000;
  esther_cfg.trglevel[1] = -6000;
  esther_cfg.trglevel[2] = 6000;
  rc = ioctl(fd, ESTHER_TRG_IOCS_TRIG_CONFIG, &esther_cfg);

  rc = ioctl(fd, ESTHER_TRG_IOCT_DMA_RESET);
  rc = ioctl(fd, ESTHER_TRG_IOCT_INT_ENABLE);

  dmaBuff = malloc(dmaSize);
  rc = ioctl(fd, ESTHER_TRG_IOCT_SOFT_TRIG);
  rc = ioctl(fd, ESTHER_TRG_IOCT_ACQ_ENABLE);
  rc = ioctl(fd, ESTHER_TRG_IOCT_DMA_ENABLE);

  usleep(1000);
  rc = read(fd, dmaBuff, dmaSize); //  one read.
  printf("read OK: %d \n", rc);

#ifdef NOCOMPILE
  rc = read(fd, dmaBuff, dmaSize); // loop read.
  /*memcpy(pAdcDataWr, dmaBuff, saveSize);*/
  /*pAdcDataWr += dmaSize / sizeof(int32_t);*/
  if (!noSave) {
    get_data(pAdcDataWr, dmaBuff);
    pAdcDataWr += saveSize;
  }

  /*
     for (ii=0; ii <  DMA_ACQ_SIZE/sizeof(int32_t); ii++) {
     if  ((dmaBuff[2*ii+1] & 0xFFF) != 0xA59)
     printf("NOK %d d:%X, ", ii, dmaBuff[2*ii+1]);
     }
     printf("\n");
     */
  /*    for (ii = 0; ii < 16; ii++) {
        printf("%d d:%X, ", ii, dmaBuff[ii]);
        }
        printf("\n");
        for (ii = 0; ii < 10; ii++) {
        printf("0x%08X, ", dmaBuff[32 * ii + 1]);
        }
        printf(" \n");*/
}

free(pAdcData);
//    printf("Acquired %d packets, %d samples, chanNumb: %d\n", Npackets,
//    SAMP_PER_PACKET * Npackets, chanNumb );
#endif

rc = ioctl(fd, ESTHER_TRG_IOCT_DMA_DISABLE);
usleep(20000);
rc = ioctl(fd, ESTHER_TRG_IOCG_STATUS, &dStat);
printf("dmaStatus: 0x%X, delay %u, %f us\n", dStat, dStat >> 16,
       (dStat >> 16) * 0.008 / 5.0);
rc = ioctl(fd, ESTHER_TRG_IOCT_ACQ_DISABLE);

if (noSave == 0) {
  fdi = fopen("dataDMA.bin", "wb");
  fwrite(dmaBuff, 1, dmaSize, fdi);
  fclose(fdi);
}
free(dmaBuff);
close(fd);

return 0;
}
