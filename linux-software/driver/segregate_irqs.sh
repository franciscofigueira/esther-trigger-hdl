#!/bin/bash
#########################################################
# Segregate IRQs to specific CPUS						#
# PDL, IPFN-IST 2017	(contribution from J. Santos)	#
# segregate_irqs_rev1.sh								#
# # segregate_irqs_rev0.sh								#
#########################################################

#default parameters
cpumask=1 #send all irqs o CPU 0

##Stop and Disable irqbalance service
#service irqbalance status
#service irqbalance stop
systemctl status irqbalance
systemctl stop irqbalance
#echo "Service 'irqbalance' stoped."
#systemctl disable irqbalance
#systemctl status irqbalance
#echo "Service 'irqbalance' stoped and disabled."

##Disbale NMI Watchdog
echo "Register 'nmi_watchdog' was set to $(cat /proc/sys/kernel/nmi_watchdog)"
echo 0 > /proc/sys/kernel/nmi_watchdog
echo "Register 'nmi_watchdog' is set to $(cat /proc/sys/kernel/nmi_watchdog)"

echo "Register 'nmi_watchdog' was set to $(cat /proc/irq/default_smp_affinity)"
echo 1 > /proc/irq/default_smp_affinity
echo "Register 'default_smp_affinity' is set to $(cat /proc/irq/default_smp_affinity)"

##Change IRQ CPU affinity mask
for irq in $(ls /proc/irq); do 
	if [[ $irq =~ ^[0-9]+$ ]]; then
		if [ $irq -ne 0 ] && [ $irq -ne 2 ]; then 
			echo ${cpumask} > /proc/irq/$irq/smp_affinity
			value=$(cat /proc/irq/$irq/smp_affinity)
			echo "IRQ ${irq} CPU mask set to ${value}"
		fi 
	fi 
done

# echo 8 > /proc/irq/41/smp_affinity
#cpupower frequency-info
									
# cpupower frequency-set -g  performance

