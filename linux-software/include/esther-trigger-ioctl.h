/**
 * IOCTL Definitions for the Linux Device Driver
 *
 *
 */

#ifndef _ESTHER_TRG_IOCTL_H_
#define _ESTHER_TRG_IOCTL_H_

//#include "atca-v2-pcie.h"

/*
 * IOCTL definitions
 */

#define ESTHER_TRG_IOC_MAGIC                                                   \
  'j' // /* Please use a different 8-bit number in your code */
      /*See  /Documentation/ioctl-number.txt*/

/* S means "Set": thru a pointer
 * T means "Tell": directly with the argument value
 * G menas "Get": reply by setting thru a pointer
 * Q means "Qry": response is on the return value
 * X means "eXchange": G and S atomically
 * H means "sHift": T and Q atomically
 */

/**********************************************************************
 *                         IOCTL FUNCTIONS                            *
 *********************************************************************/
#define ESTHER_TRG_IOCT_INT_ENABLE _IO(ESTHER_TRG_IOC_MAGIC, 1)
#define ESTHER_TRG_IOCT_INT_DISABLE _IO(ESTHER_TRG_IOC_MAGIC, 2)
#define ESTHER_TRG_IOCT_ACQ_ENABLE _IO(ESTHER_TRG_IOC_MAGIC, 3)
#define ESTHER_TRG_IOCT_ACQ_DISABLE _IO(ESTHER_TRG_IOC_MAGIC, 4)
#define ESTHER_TRG_IOCT_DMA_ENABLE _IO(ESTHER_TRG_IOC_MAGIC, 5)
#define ESTHER_TRG_IOCT_DMA_DISABLE _IO(ESTHER_TRG_IOC_MAGIC, 6)
#define ESTHER_TRG_IOCT_SOFT_TRIG _IO(ESTHER_TRG_IOC_MAGIC, 7)
#define ESTHER_TRG_IOCG_STATUS _IOR(ESTHER_TRG_IOC_MAGIC, 8, u_int32_t)
#define ESTHER_TRG_IOCS_RDTMOUT _IOW(ESTHER_TRG_IOC_MAGIC, 9, u_int32_t)
#define ESTHER_TRG_IOCS_DMA_SIZE _IOW(ESTHER_TRG_IOC_MAGIC, 10, u_int32_t)
#define ESTHER_TRG_IOCG_DMA_SIZE _IOR(ESTHER_TRG_IOC_MAGIC, 11, u_int32_t)
#define ESTHER_TRG_IOCT_DMA_RESET _IO(ESTHER_TRG_IOC_MAGIC, 12)
#define ESTHER_TRG_IOCT_STREAM_ENABLE _IO(ESTHER_TRG_IOC_MAGIC, 13)
#define ESTHER_TRG_IOCT_STREAM_DISABLE _IO(ESTHER_TRG_IOC_MAGIC, 14)
#define ESTHER_TRG_IOCS_TRIG_CONFIG                                            \
  _IOW(ESTHER_TRG_IOC_MAGIC, 15, struct esther_trig_config)
#define ESTHER_TRG_IOC_MAXNR 15

/*
 *#define ESTHER_TRG_IOCG_TMRGATE       _IOR(ESTHER_TRG_IOC_MAGIC, 13,
 *u_int32_t)
 *
 *#define ESTHER_TRG_IOCS_TMR0CTRL      _IOW(ESTHER_TRG_IOC_MAGIC, 14,
 *u_int32_t)
 *#define ATCA_PCIE_IOCG_TMR0CTRL      _IOR(ATCA_PCIE_IOC_MAGIC, 15,
 *u_int32_t)
 *#define ATCA_PCIE_IOCS_TMR0COUNT     _IOW(ATCA_PCIE_IOC_MAGIC, 16,
 *u_int32_t)
 *#define ATCA_PCIE_IOCG_TMR0COUNT     _IOR(ATCA_PCIE_IOC_MAGIC, 17,
 *u_int32_t)
 *
 *#define ATCA_PCIE_IOCG_TMR2COUNT     _IOR(ATCA_PCIE_IOC_MAGIC, 25,
 *u_int32_t)
 *
 *#define ATCA_PCIE_IOCS_TMR3CTRL      _IOW(ATCA_PCIE_IOC_MAGIC, 26,
 *u_int32_t)
 *#define ATCA_PCIE_IOCG_TMR3CTRL      _IOR(ATCA_PCIE_IOC_MAGIC, 27,
 *u_int32_t)
 *#define ATCA_PCIE_IOCS_TMR3COUNT     _IOW(ATCA_PCIE_IOC_MAGIC, 28,
 *u_int32_t)
 *#define ATCA_PCIE_IOCG_TMR3COUNT     _IOR(ATCA_PCIE_IOC_MAGIC, 29,
 *u_int32_t)
 *
 */

/*
#define ATCA_PCIE_IOCS_CONFIG_ACQ _IOW(ATCA_PCIE_IOC_MAGIC, 2, u_int32_t)
#define ATCA_PCIE_IOCT_DSP_HOLD _IO(ATCA_PCIE_IOC_MAGIC, 1)
#define ATCA_PCIE_IOCS_BAR1_WREG _IOW(ATCA_PCIE_IOC_MAGIC, 5, uint32_t)
#define ATCA_PCIE_IOCG_BAR1_RREG _IOR(ATCA_PCIE_IOC_MAGIC, 6, uint32_t)
#define ATCA_PCIE_IOCG_IRQ_CNT _IOR(ATCA_PCIE_IOC_MAGIC, 7, u_int32_t)
#define ATCA_PCIE_IOCT_SOFT_TRIG _IO(ATCA_PCIE_IOC_MAGIC, 8)
#define ATCA_PCIE_IOCS_TMOUT      _IOW(ATCA_PCIE_IOC_MAGIC, 11, u_int32_t)
#define ATCA_PCIE_IOCS_CHAN       _IOW(PCIE_ADC_IOC_MAGIC, 12, u_int32_t)
*/
#endif /* _ATCA_PCIE_IOCTL_H_ */
