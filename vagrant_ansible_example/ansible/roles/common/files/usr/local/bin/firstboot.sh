#!/bin/bash
#First boot script

#Attempt to autoconfigure network
/usr/local/bin/configure_network.sh auto

#Disable puppet 
systemctl stop puppet
systemctl disable puppet

#Disable first boot
systemctl disable kapsch_firstboot.service
