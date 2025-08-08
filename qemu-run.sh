#!/bin/bash

if [[ $1 = help ]]; then
	echo "Command: sudo qemu-run.sh install <vm_name>"
	echo "         sudo qemu-run.sh boot <vm_name>"
	exit 1
fi

if ! yq --help > /dev/null; then 
	echo "No yq found :("
fi


if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

if [[ $1 = "" ]] || [[ $2 = "" ]]; then
	echo "Not enough arguments"
	exit 1
fi
	

VM_NAME=$2
VM_RAM=$(yq [.] ./options.yaml | jq -r --arg VM_NAME "$VM_NAME" '.[].vm[]| select(.name == $VM_NAME) | .ram // empty')
VM_IMAGE=$(yq [.] ./options.yaml | jq -r --arg VM_NAME "$VM_NAME" '.[].vm[]| select(.name == $VM_NAME) | .image // empty')
VM_DISK_NAME=$(yq [.] ./options.yaml | jq -r --arg VM_NAME "$VM_NAME" '.[].vm[]| select(.name == $VM_NAME) | .disk // empty')
VM_NETWORK_NAME=$(yq [.] ./options.yaml | jq -r --arg VM_NAME "$VM_NAME" '.[].vm[]| select(.name == $VM_NAME) | .network // empty')

VM_QEMU_BOOT_ARGUMENTS=$(yq [.] ./options.yaml | jq -r --arg VM_NAME "$VM_NAME" '.[].vm[]| select(.name == $VM_NAME) | .additional_qemu_boot_arguments // empty')
VM_QEMU_INSTALL_ARGUMENTS=$(yq [.] ./options.yaml | jq -r --arg VM_NAME "$VM_NAME" '.[].vm[]| select(.name == $VM_NAME) | .additional_qumu_install_arguments // empty')

DISK_FORMAT=$(yq [.] ./options.yaml | jq -r --arg VM_DISK_NAME "$VM_DISK_NAME" '.[].disks[] | select(.name == $VM_DISK_NAME) | .format // empty')
DISK_SIZE=$(yq [.] ./options.yaml | jq -r --arg VM_DISK_NAME "$VM_DISK_NAME" '.[].disks[] | select(.name == $VM_DISK_NAME) | .size // empty')
DISK_DIRECTORY=$(yq [.] ./options.yaml | jq -r --arg VM_DISK_NAME "$VM_DISK_NAME" '.[].disks[] | select(.name == $VM_DISK_NAME) | .directory // empty')

if [[ $DISK_FORMAT = raw ]]; then
	DISK_RAW_PATH=$(yq [.] ./options.yaml | jq  -r --arg VM_DISK_NAME "$VM_DISK_NAME" '.[].disks[] | select(.name == $VM_DISK_NAME) | .path')
fi

 
if [[ !($DISK_FORMAT == raw) ]]; then
	DISK_ARG="-drive $(echo ${DISK_DIRECTORY}/${VM_DISK_NAME}.${DISK_FORMAT})"

	if [[ $1 =  install ]]; then
		if [ -f $DISK_PATH ]; then
			echo "Using existing disk"
		else
			echo "Creating disk $DISK_PATH"
			qemu-img create -f $DISK_FORMAT $DISK_PATH $DISK_SIZE
		fi
	fi
else

DISK_ARG="-hda ${DISK_RAW_PATH}"

fi 

if [[ $1 = boot ]]; then
	qemu-system-x86_64 $DISK_ARG \
							 -m $VM_RAM \
							 -enable-kvm \
							 -boot c 
fi

if [[ $1 = install ]]; then
	qemu-system-x86_64 $DISK_ARG \
							 -cdrom $VM_IMAGE \
							 -m $VM_RAM \
							 -enable-kvm \
							 -boot d
fi
