#!/bin/bash

if [[ $1 = help ]]; then
	echo "Command: sudo init.sh install <vm_name>"
	echo "         sudo init.sh boot <vm_name>"
	exit 1
fi


if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi


VM_NAME=$2
VM_RAM=$(yq [.] ./options.yaml | jq -r --arg VM_NAME "$VM_NAME" '.[0].vm | select(.[0].name ==  $VM_NAME ) | .[0].ram')
VM_IMAGE=$(yq [.] ./options.yaml | jq -r  --arg VM_NAME "$VM_NAME" '.[0].vm | select(.[0].name ==  $VM_NAME ) | .[0].image')
VM_DISK_NAME=$(yq [.] ./options.yaml | jq -r  --arg VM_NAME  "$VM_NAME" '.[0].vm | select(.[0].name == $VM_NAME) | .[0].disk')

VM_QEMU_BOOT_ARGUMENTS=$(yq [.] ./options.yaml | jq -r --arg VM_NAME "$VM_NAME" '.[0].vm | select(.[0].name == $VM_NAME) | .[0].additional_qemu_boot_arguments')
VM_QEMU_INSTALL_ARGUMENTS=$(yq [.] ./options.yaml | jq -r  --arg VM_NAME "$VM_NAME" '.[0].vm | select(.[0].name == $VM_NAME) | .[0].additional_qumu_install_arguments')

DISK_FORMAT=$(yq [.] ./options.yaml | jq  -r --arg VM_DISK_NAME "$VM_DISK_NAME" '.[0].disks | select(.[0].name == $VM_DISK_NAME) | .[0].format')
DISK_SIZE=$(yq [.] ./options.yaml | jq  -r --arg VM_DISK_NAME "$VM_DISK_NAME" '.[0].disks | select(.[0].name == $VM_DISK_NAME) | .[0].size')
DISK_DIRECTORY=$(yq [.] ./options.yaml | jq  -r --arg VM_DISK_NAME "$VM_DISK_NAME" '.[0].disks | select(.[0].name == $VM_DISK_NAME) | .[0].directory')

DISK_PATH=$(echo ${DISK_DIRECTORY}/${VM_DISK_NAME}.${DISK_FORMAT})


if [[ $1 =  install ]]; then
	if [ -f $DISK_PATH ]; then
		echo "Using existing disk"
	else
		echo "Creating disk $DISK_PATH"
		qemu-img create -f $DISK_FORMAT $DISK_PATH $DISK_SIZE
	fi
fi

if [[ $1 = boot ]]; then
	qemu-system-x86_64 -drive file=$DISK_PATH \
							 -m $VM_RAM \
							 -net nic,model=e1000 \
							 -enable-kvm \
							 -boot c 
fi

if [[ $1 = install ]]; then
	qemu-system-x86_64 -drive file=$DISK_PATH \
							 -cdrom $VM_IMAGE \
							 -m $VM_RAM \
							 -net nic,model=e1000 \
							 -enable-kvm \
							 -boot d
fi
