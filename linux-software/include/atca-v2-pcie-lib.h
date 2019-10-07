/**
 * PCIe Vivado Project General
 * Project Name:
 * Design Name:
 * FW Version
 *
 *
 * Copyright 2014 - 2019 IPFN-Instituto Superior Tecnico, Portugal
 * Creation Date  2019-07-26
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
#ifndef _ATCA_PCI_V2_LIB_H_
#define _ATCA_PCI_V2_LIB_H_
#include "atca-v2-pcie.h"
int bind_to_cpu(int core_id);
void get_pckt_adc_data(int32_t *pAdcData, DMA_PCKT *pPckDma);
void get_rt_pckt_adc_data(int32_t *pAdcData, DMACH1_PCKT *pPckDma);
unsigned int get_pckt_head_magic(DMA_PCKT *pPdma);
unsigned int get_pckt_foot_magic(DMA_PCKT *pPdma);
uint64_t get_sample_cnt(SAMPLE *pSamp);
int atca_mimo_v2_stop_acq(int fd);
unsigned long int time_interval_us(struct timeval *tstart,
                                   struct timeval *tend);
#endif /* _ATCA_PCI_V2_LIB_H_ */
