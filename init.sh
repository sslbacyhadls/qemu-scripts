#!/bin/bash

DEFAULT_RAM_SIZE=2G
DEFAULT_DISK_SIZE=20G

if [[ $1 = help ]]; then
	echo "Command: sudo init.sh install <image> <diskname>"
	echo "         sudo init.sh boot <diskname>"
	exit 1
fi


if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi



if [ ! -f $3 ]; then
	echo "Creating disk $3"
	exec qemu-img create -f qcow2 $3 $DEFAULT_DISK_SIZE
fi

if [[ $1 = boot ]]; then
	qemu-system-x86_64 -drive file=$2 \
							 -m $DEFAULT_RAM_SIZE \
							 -net nic,model=e1000 \
							 -enable-kvm \
							 -boot c 
fi

if [[ $1 = install ]]; then
	qemu-system-x86_64 -drive file=$3 \
							 -cdrom $2 \
							 -m $DEFAULT_RAM_SIZE \
							 -net nic,model=e1000 \
							 -enable-kvm \
							 -boot d
fi
