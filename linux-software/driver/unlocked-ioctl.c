/**
 *
 * @file unlocked-ioctl.c
 * @author Bernardo Carvalho
 * @date 2014-06-27
 * @brief Contains the functions handling the different ioctl calls.
 *
 * Copyright 2014 - 2019 IPFN-Instituto Superior Tecnico, Portugal
 * Creation Date  2014-06-27
 *
 * Licensed under the EUPL, Version 1.2 only (the "Licence");
 * You may not use this work except in compliance with the Licence.
 * You may obtain a copy of the Licence, available in 23 official languages of
 * the European Union, at:
 * https://joinup.ec.europa.eu/community/eupl/og_page/eupl-text-11-12
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the Licence is distributed on an "AS IS" basis,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the Licence for the specific language governing permissions and
 * limitations under the Licence.
 *
 */

/* Configuration for the driver (what should be compiled in, module name,
 * etc...) */
#include "config.h"

/* Internal definitions for all parts (includes, prototypes, data, macros) */
#include "common.h"

#include "../include/esther-trigger-ioctl.h"

/**
 * _unlocked_ioctl
 */
long _unlocked_ioctl(struct file *filp, unsigned int cmd, unsigned long arg) {

  int err = 0, retval = 0;
  unsigned long flags = 0;
  u32 tmp, i;
  int32_t ival;
  COMMAND_REG cReg;
  STATUS_REG sReg;
  PCIE_DEV *pciDev; /* for device information */
  struct esther_trig_config trg_obj;

  u32 byteSize;

  /* retrieve the device information  */
  pciDev = (PCIE_DEV *)filp->private_data;

  sReg.reg32 = ioread32((void *)&pciDev->pModDmaHregs->dmaStatus);
  if (sReg.reg32 == 0xFFFFFFFF)
    PDEBUG("ioctl status Reg:0x%X, cmd: 0x%X\n", sReg.reg32, cmd);

  /**
   * extract the type and number bitfields, and don't decode
   * wrong cmds: return ENOTTY (inappropriate ioctl) before access_ok()
   */
  if (_IOC_TYPE(cmd) != ESTHER_TRG_IOC_MAGIC)
    return -ENOTTY;
  if (_IOC_NR(cmd) > ESTHER_TRG_IOC_MAXNR)
    return -ENOTTY;

  /*
   * the direction is a bitmask, and VERIFY_WRITE catches R/W
   * transfers. `Type' is user-oriented, while
   * access_ok is kernel-oriented, so the concept of "read" and
   * "write" is reversed
   */
  if (_IOC_DIR(cmd) & _IOC_READ)
    err = !access_ok(VERIFY_WRITE, (void __user *)arg, _IOC_SIZE(cmd));
  else if (_IOC_DIR(cmd) & _IOC_WRITE)
    err = !access_ok(VERIFY_READ, (void __user *)arg, _IOC_SIZE(cmd));
  if (err)
    return -EFAULT;
  switch (cmd) {

  case ESTHER_TRG_IOCG_STATUS:
    spin_lock_irqsave(&pciDev->irq_lock, flags);
    //  ----- ----- ----- ----- ----- DEVICE SPECIFIC CODE ----- ----- -----
    tmp = PCIE_READ32((void *)&pciDev->pModDmaHregs->dmaStatus);
    //  ----- ----- ----- ----- ----- DEVICE SPECIFIC CODE ----- ----- -----
    spin_unlock_irqrestore(&pciDev->irq_lock, flags);

    if (copy_to_user((void __user *)arg, &tmp, sizeof(u32)))
      return -EFAULT;
    break;

  case ESTHER_TRG_IOCT_INT_ENABLE:
    spin_lock_irqsave(&pciDev->irq_lock, flags);
    // ----- ----- ----- ----- ----- ----- DEVICE SPECIFIC CODE ----- -----
    cReg.reg32 = PCIE_READ32((void *)&pciDev->pModDmaHregs->dmaControl);
    cReg.cmdFlds.DmaIntE = 1;
    PCIE_WRITE32(cReg.reg32, (void *)&pciDev->pModDmaHregs->dmaControl);
    // ----- ----- ----- ----- ----- ----- DEVICE SPECIFIC CODE ----- -----
    // ----- ----- ----- -----
    spin_unlock_irqrestore(&pciDev->irq_lock, flags);
    break;

  case ESTHER_TRG_IOCT_INT_DISABLE:
    spin_lock_irqsave(&pciDev->irq_lock, flags);
    // ----- ----- ----- ----- ----- ----- DEVICE SPECIFIC CODE ----- -----
    cReg.reg32 = PCIE_READ32((void *)&pciDev->pModDmaHregs->dmaControl);
    cReg.cmdFlds.DmaIntE = 0;
    PCIE_WRITE32(cReg.reg32, (void *)&pciDev->pModDmaHregs->dmaControl);
    // ----- ----- ----- ----- ----- ----- DEVICE SPECIFIC CODE ----- -----
    // ----- ----- ----- -----
    spin_unlock_irqrestore(&pciDev->irq_lock, flags);
    break;

  case ESTHER_TRG_IOCT_ACQ_ENABLE:
    spin_lock_irqsave(&pciDev->irq_lock, flags);
    cReg.reg32 = PCIE_READ32((void *)&pciDev->pModDmaHregs->dmaControl);
    pciDev->mismatches = 0;
    /*pciDev->curr_buf = 0;*/
    pciDev->max_buffer_count = 0;
    atomic_set(&pciDev->rd_condition, 0);
    cReg.cmdFlds.AcqE = 1;
    /*cReg.cmdFlds.STrg = 0;*/
    PCIE_WRITE32(cReg.reg32, (void *)&pciDev->pModDmaHregs->dmaControl);
    spin_unlock_irqrestore(&pciDev->irq_lock, flags);
    break;

  case ESTHER_TRG_IOCT_ACQ_DISABLE:
    retval = pciDev->max_buffer_count;
    spin_lock_irqsave(&pciDev->irq_lock, flags);
    // ----- ----- ----- ----- ----- ----- DEVICE SPECIFIC CODE ----- -----
    // ----- ----- ----- -----
    cReg.reg32 = PCIE_READ32((void *)&pciDev->pModDmaHregs->dmaControl);
    cReg.cmdFlds.AcqE = 0;
    cReg.cmdFlds.STrg = 0;
    PCIE_WRITE32(cReg.reg32, (void *)&pciDev->pModDmaHregs->dmaControl);
    // ----- ----- ----- ----- ----- ----- DEVICE SPECIFIC CODE ----- -----
    // ----- ----- ----- -----
    spin_unlock_irqrestore(&pciDev->irq_lock, flags);

    break;
  case ESTHER_TRG_IOCT_DMA_ENABLE:
    spin_lock_irqsave(&pciDev->irq_lock, flags);
    // ----- ----- ----- ----- ----- ----- DEVICE SPECIFIC CODE ----- -----
    // ----- ----- ----- -----
    cReg.reg32 = PCIE_READ32((void *)&pciDev->pModDmaHregs->dmaControl);
    cReg.cmdFlds.DmaE = 1;
    PCIE_WRITE32(cReg.reg32, (void *)&pciDev->pModDmaHregs->dmaControl);
    // ----- ----- ----- ----- ----- ----- DEVICE SPECIFIC CODE ----- -----
    // ----- ----- ----- -----
    spin_unlock_irqrestore(&pciDev->irq_lock, flags);

    break;
  case ESTHER_TRG_IOCT_DMA_DISABLE:
    spin_lock_irqsave(&pciDev->irq_lock, flags);
    // ----- ----- ----- ----- ----- ----- DEVICE SPECIFIC CODE ----- -----
    // ----- ----- ----- -----
    cReg.reg32 = PCIE_READ32((void *)&pciDev->pModDmaHregs->dmaControl);
    cReg.cmdFlds.DmaE = 0;
    PCIE_WRITE32(cReg.reg32, (void *)&pciDev->pModDmaHregs->dmaControl);
    // ----- ----- ----- ----- ----- ----- DEVICE SPECIFIC CODE ----- -----
    // ----- ----- ----- -----
    spin_unlock_irqrestore(&pciDev->irq_lock, flags);

    break;
  case ESTHER_TRG_IOCT_DMA_RESET:
    spin_lock_irqsave(&pciDev->irq_lock, flags);
    // ----- ----- DEVICE SPECIFIC CODE ----- -----
    cReg.reg32 = PCIE_READ32((void *)&pciDev->pModDmaHregs->dmaControl);
    cReg.cmdFlds.DmaRst = 1;
    PCIE_WRITE32(cReg.reg32, (void *)&pciDev->pModDmaHregs->dmaControl);
    byteSize = ioread32((void *)&pciDev->pModDmaHregs->dmaByteSize);
    // clear DMA buffer
    memset(pciDev->dmaIO.buf[0].addr_v, 0, byteSize * DMA_BUFFS);
    //    udelay(10);
    cReg.cmdFlds.DmaRst = 0;
    PCIE_WRITE32(cReg.reg32, (void *)&pciDev->pModDmaHregs->dmaControl);

    // ----- ----- DEVICE SPECIFIC CODE ----- -----
    spin_unlock_irqrestore(&pciDev->irq_lock, flags);
    udelay(20);
    break;
  /*
case ESTHER_TRG_IOCG_COUNTER:
  spin_lock_irqsave(&pciDev->irq_lock, flags);
  tmp = PCIE_READ32((void*) &pciDev->pHregs->hwcounter);
  spin_unlock_irqrestore(&pciDev->irq_lock, flags);
  if(copy_to_user((void __user *)arg, &tmp, sizeof(u32)))
    return -EFAULT;
  break;
  */
  case ESTHER_TRG_IOCS_RDTMOUT:
    retval = __get_user(tmp, (int __user *)arg);
    if (!retval)
      pciDev->wt_tmout = tmp * HZ;
    break;

  case ESTHER_TRG_IOCT_SOFT_TRIG:
    spin_lock_irqsave(&pciDev->irq_lock, flags);
    // ---- ----- -----  DEVICE SPECIFIC CODE -----  ----- -----
    cReg.reg32 = PCIE_READ32((void *)&pciDev->pModDmaHregs->dmaControl);
    cReg.cmdFlds.STrg = 1;
    PCIE_WRITE32(cReg.reg32, (void *)&pciDev->pModDmaHregs->dmaControl);
    // ----- ----- ----- DEVICE SPECIFIC CODE ----- -----
    spin_unlock_irqrestore(&pciDev->irq_lock, flags);
    break;

  case ESTHER_TRG_IOCS_DMA_SIZE:
    retval = __get_user(tmp, (int __user *)arg);
    if (!retval) {
      spin_lock_irqsave(&pciDev->irq_lock, flags);
      iowrite32(tmp, (void *)&pciDev->pModDmaHregs
                         ->dmaByteSize); // write the buffer size to the FPGA
      spin_unlock_irqrestore(&pciDev->irq_lock, flags);
    }
    break;

  case ESTHER_TRG_IOCG_DMA_SIZE:
    spin_lock_irqsave(&pciDev->irq_lock, flags);
    tmp = ioread32((void *)&pciDev->pModDmaHregs->dmaByteSize);
    spin_unlock_irqrestore(&pciDev->irq_lock, flags);
    if (copy_to_user((void __user *)arg, &tmp, sizeof(u32)))
      return -EFAULT;
    break;
    /*
      case ESTHER_TRG_IOCT_STREAM_ENABLE:
        spin_lock_irqsave(&pciDev->irq_lock, flags);
        // ----- ----- DEVICE SPECIFIC CODE ----- -----
        cReg.reg32 = PCIE_READ32((void *)&pciDev->pModDmaHregs->dmaControl);
        cReg.cmdFlds.StreamE = 1;
        PCIE_WRITE32(cReg.reg32, (void *)&pciDev->pModDmaHregs->dmaControl);
        // ----- ----- DEVICE SPECIFIC CODE ----- -----
        spin_unlock_irqrestore(&pciDev->irq_lock, flags);
        break;
  case ESTHER_TRG_IOCT_STREAM_DISABLE:
    spin_lock_irqsave(&pciDev->irq_lock, flags);
    // ----- ----- DEVICE SPECIFIC CODE ----- -----
    cReg.reg32 = PCIE_READ32((void *)&pciDev->pModDmaHregs->dmaControl);
    cReg.cmdFlds.StreamE = 0;
    PCIE_WRITE32(cReg.reg32, (void *)&pciDev->pModDmaHregs->dmaControl);
    // ----- ----- DEVICE SPECIFIC CODE ----- -----
    spin_unlock_irqrestore(&pciDev->irq_lock, flags);
    break;
    */

  case ESTHER_TRG_IOCS_TRIG_CONFIG:
    if (copy_from_user((void *)&trg_obj, (void *)arg,
                       sizeof(struct esther_trig_config))) {
      /*pr_err("copy_from_user failed.\n");*/
      return -EFAULT;
    }
    spin_lock_irqsave(&pciDev->irq_lock, flags);
    // ----- ----- DEVICE SPECIFIC CODE ----- -----
    for (i = 0; i < ADC_CHANNELS; i++) {
      ival = trg_obj.trglevel[i];
      PDEBUG("ioctl trig_level Reg:%d, off: %d", i, ival);
      PCIE_WRITE32(ival, (void *)&pciDev->pModDmaHregs->trigConfig[i]);
    }
    // ----- ----- DEVICE SPECIFIC CODE ----- -----
    spin_unlock_irqrestore(&pciDev->irq_lock, flags);
    break;

  default: /* redundant, as cmd was checked against MAXNR */
    return -ENOTTY;
  }
  return retval;
}
