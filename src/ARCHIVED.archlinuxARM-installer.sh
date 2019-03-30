#!/bin/bash

export session_id=$(< /dev/urandom tr -dc 0-9 | head -c6)
export install_path="/mnt/.ARMInstall_${session_id}"
export img_path="/mnt/local/static/imgs/arm"

export board_model="${1}"
export install_disk="${2}"


function logic_check {

    case ${board_model} in
        "cubieboard2"|"xu4"|"rpi2"|"rpi")
            ;;
        *)
            echo "ERROR: Must choose a supported board model"
            exit 1
            ;;
    esac

    case ${install_disk} in
        "/dev/sd"[a-z]|"/dev/mmcblk"[0-9])
            ;;
        *)
            echo "ERROR: Must choose a valid device path"
            exit 1
            ;;
    esac

}


function select_img {

    case ${board_model} in
        "cubieboard2")
            export img_name="ArchLinuxARM-armv7-latest.tar.gz"
            ;;
        "xu4")
            export img_name="ArchLinuxARM-odroid-xu3-latest.tar.gz"
            ;;
        "rpi2")
            export img_name="ArchLinuxARM-rpi-2-latest.tar.gz"
            ;;
        "rpi")
            export img_name="ArchLinuxARM-rpi-latest.tar.gz"
            ;;
    esac

    export img="${img_path}/${img_name}"

}


function format_disk {

    echo "=== Wiping out ${install_disk} with /dev/zero"
    dd if=/dev/zero of=${install_disk} bs=1M count=8 status=none
    
    echo "=== Formatting ${install_disk} with ${board_model} layout"
    if [ "${board_model}" == "xu4" ] || \
       [ "${board_model}" == "cubieboard2" ]; then

        (echo o; \
         echo n; \
         echo p; \
         echo 1; \
         echo ; \
         echo ; \
         echo w) \
        | fdisk ${install_disk} > /dev/null 2>&1

    elif [ "${board_model}" == "rpi2" ] || \
         [ "${board_model}" == "rpi" ]; then

        (echo o; \
         echo n; \
         echo p; \
         echo 1; \
         echo ; \
         echo "+100M"; \
         echo t; \
         echo c; \
         echo n; \
         echo p; \
         echo 2; \
         echo ; \
         echo ; \
         echo w) \
        | fdisk ${install_disk} > /dev/null 2>&1

    fi

}


function format_partition {

    echo "=== Creating installation path at ${install_path}"
    mkdir -p "${install_path}/"{boot,root}

    if [ "${board_model}" == "xu4" ] || \
       [ "${board_model}" == "cubieboard2" ]; then

        echo "=== Formatting ${install_disk}1 with ext4"
        mkfs.ext4 -F "${install_disk}1" > /dev/null 2>&1

        echo "=== Mounting ${install_disk}1 to ${install_path}/root"
        mount "${install_disk}1" "${install_path}/root"

    elif [ "${board_model}" == "rpi2" ] || \
         [ "${board_model}" == "rpi" ]; then

        echo "=== Formatting ${install_disk}1 with vfat"
        mkfs.vfat "${install_disk}1" > /dev/null 2>&1

        echo "=== Formatting ${install_disk}2 with ext4"
        mkfs.ext4 -F "${install_disk}2" > /dev/null 2>&1

        echo "=== Mounting ${install_disk}1 to ${install_path}/boot"
        mount "${install_disk}1" "${install_path}/boot"

        echo "=== Mounting ${install_disk}2 to ${install_path}/root"
        mount "${install_disk}2" "${install_path}/root"

    fi

    echo "=== Extracting ${img} to ${install_path}/root"
    bsdtar -xpf "${img}" -C "${install_path}/root"

    echo "=== Syncing from RAM to disk"
    sync

}


function boot_loader {

    echo "=== Setting up bootloader for ${board_model}"
    if [ "${board_model}" == "cubieboard2" ]; then

        dd if="${img_path}/u-boot-sunxi-with-spl.bin" \
           of="${install_disk}" bs=1024 seek=8 status=none
        cp "${img_path}/boot.scr" \
              "${install_path}/root/boot/boot.scr"

    elif [ "${board_model}" == "xu4" ]; then

        cd "${install_path}/root/boot"
        sh ./sd_fusing.sh "${install_disk}"
        cd

    elif [ "${board_model}" == "rpi2" ] || \
         [ "${board_model}" == "rpi" ]; then

        ls -lah ${install_path}/*
        mv "${install_path}/root/boot/*" "${install_path}/boot/"

    fi

    sync

}


function clean_up {

    echo "=== Cleaning up ${install_path}"
    umount "${install_path}/boot" > /dev/null 2>&1
    umount "${install_path}/root" > /dev/null 2>&1
    rmdir "${install_path}/boot"
    rmdir "${install_path}/root"
    rmdir "${install_path}"

}


function main {

    logic_check
    select_img
    format_disk
    format_partition
    boot_loader
    clean_up

}


main

exit 0
