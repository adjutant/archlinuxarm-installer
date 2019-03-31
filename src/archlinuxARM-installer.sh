#!/bin/bash


### Sessions init and arguments capture.
# Very weird Bash structure here for getopts. Keep as-is. No touchy.
function session_init {
    session_id=$(< /dev/urandom tr -dc 0-9 | head -c6)
    mount_path="/mnt/.alARM_install_${session_id}"
}


function _print_help_and_exit {
    echo -e "archlinuxARM-installer version 0.2 \n
`           `archlinuxARM-installer is the tool to install ArchLinuxARM \
`           `automatically \non supported devices. It was designed primarily \
`           `to assist with the \ninstallation of ARM clusters. \n
`           `Usage: archlinuxARM-installer [OPTION] \n
`           `Options:
`           ` -h      print out this help message
`           ` -v      debug_modetivate debug log (true/false)
`           ` -d      path to ArchLinuxARM image directory
`           ` -b      path to block device to be installed (/dev/sdX)
`           ` -m      board model name"
    exit 2
}


function _empty_optarg_exit {
    if [ -z ${2} ]; then
        echo "Argument -${1} requires a value"; >&2
        _print_help_and_exit
    fi
}


while getopts "hvd:b:m:" opt; do
    case $opt in
        h)
            _print_help_and_exit
            ;;
        v)
            debug_mode="True"
            ;;
        d)
            _empty_optarg_exit "${opt}" "${OPTARG}"
            img_path="${OPTARG}"
            check[0]="d"
            ;;
        b)
            _empty_optarg_exit "${opt}" "${OPTARG}"
            install_disk="${OPTARG}"
            check[1]="b"
            ;;
        m)
            _empty_optarg_exit "${opt}" "${OPTARG}"
            board_model="${OPTARG}"
            check[2]="m"
            ;;
        \?)
            echo "Unsupported argument chosen: -${OPTARG}" >&2
            _print_help_and_exit
            ;;
    esac
done

if [ "${check[*]}" != "d b m" ]; then
    echo "All 3 arguments -b, -d, -m are required"
    exit 1;
fi

session_init
###


### Logging functions
function current_timestamp {
    $(which date) +"%d-%m-%Y, %H:%M:%S"
}


function _logging {
    ## Take 2 positional parameters.
    ## ${1} for loglevel: info, warning, error, debug
    ## ${2} for log messages
    ##
    ## ${1} ${2} MUST always be wrapped in double quotes.
    ## Env variable ${debug_mode} is checked for debug log printing.
    ## Loglevel ERROR will cause the program to exit.
    case ${1} in
        "info"|"INFO")
            echo "[$(current_timestamp)] INFO: ${2}"
            ;;
        "warning"|"WARNING")
            echo "[$(current_timestamp)] WARNING: ${2}"
            ;;
        "error"|"ERROR")
            echo "[$(current_timestamp)] ERROR: ${2}"
            exit 1
            ;;
        "debug"|"DEBUG")
            case "${debug_mode}" in
                "true"|"TRUE")
                    echo "[$(current_timestamp)] DEBUG: ${2}"
                    ;;
                *)
                    ;;
            esac
            ;;
    esac
}


function logging_info {
    ## Take 1 positional parameter.
    ## ${1} for log message.
    _logging "INFO" "${1}"
}


function logging_warning {
    ## Take 1 positional parameter.
    ## ${1} for log message.
    _logging "WARNING" ${1}
}


function logging_ERROR {
    ## Take 1 positional parameter.
    ## ${1} for log message.
    ##
    ## This function will cause the program to exit.
    _logging "ERROR" ${1}
}


function logging_DEBUG {
    ## Take 1 positional parameter.
    ## ${1} for log message.
    _logging "DEBUG" ${1}
}
###


### Templating functions.
function _disk_template_cubieboard2 {
    ## Take 1 positional parameter.
    ## ${1} for ${install_disk}
    ##
    ## NOTE: This function requires sudo.

    # This is an internal function. It should use positional parameter
    # instead of referring directly to a program-wide variable.

    # One partition for whole disk. Make it ext4.
    (echo o; \
     echo n; \
     echo p; \
     echo 1; \
     echo ; \
     echo ; \
     echo w) \
    | fdisk ${1} > /dev/null 2>&1
    logging_info "Formated ${1} using template for:"
    logging_info "cubieboard2 || xu4 "

    mkfs.ext4 -F "${1}1" > /dev/null 2>&1
    mkdir -p "${mount_path}/root"
    mount "${1}1" "${mount_path}/root"
    logging_info "Created filesystem & mounted ${1}1 to ${mount_path}/root"

}


function _disk_template_rpi {
    ## Take 1 positional parameter.
    ## ${1} for ${install_disk}
    ##
    ## NOTE: This function requires sudo.

    # Two partitions. Make one vfat for /boot, the other ext4 for /root
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
    | fdisk ${1} > /dev/null 2>&1
    logging_info "Formated ${1} using template for:"
    logging_info "rpi || rpi2"

    mkfs.vfat "${1}1" > /dev/null 2>&1
    mkdir -p "${mount_path}/boot"
    mount "${1}1" "${mount_path}/boot"
    logging_info "Created filesystem & mounted ${1}1 to ${mount_path}/boot"

    mkfs.ext4 -F "${1}2" > /dev/null 2>&1
    mkdir -p "${mount_path}/root"
    mount "${1}2" "${mount_path}/root"
    logging_info "Created filesystem & mounted ${1}2 to ${mount_path}/root"

}



function _post_install_template_cubieboard2 {

    logging_info "Setting up bootloader for ${board_model}"
    dd if="${img_path}/u-boot-sunxi-with-spl.bin" of="${install_disk}" bs=1024 seek=8 status=none
    cp "${img_path}/boot.scr" "${mount_path}/root/boot/boot.scr"

    sync

}


function _post_install_template_xu4 {
    cd "${mount_path}/root/boot"
    sh ./sd_fusing.sh "${install_disk}"
    cd
    sync
    logging_info "Set up bootloader for ${board_model}"
}

function _post_install_template_rpi {
    mv "${mount_path}/root/boot/*" "${mount_path}/boot/"
    sync
    logging_info "Set up bootloader for ${board_model}"
}

function wipe_disk {
    ## Take 1 positional parameter.
    ## ${1} for ${install_disk}
    ##
    ## NOTE: This function requires sudo.

    dd if=/dev/zero of=${1} bs=1M count=8 status=none
    logging_info "Wiped out ${1} with /dev/zero"
}


function create_disk_template {
    case ${1} in
        "cubieboard2")
            _disk_template_cubieboard2 ${2}
            ;;
        "rpi")
            _disk_template_rpi ${2}
    esac
}
###


### Main logic
function select_img {
    case ${board_model} in
        "cubieboard2")
            export img_name="ArchLinuxARM-armv7-latest.tar.gz"
            export disk_template="cubieboard2"
            ;;
        "xu4")
            export img_name="ArchLinuxARM-odroid-xu3-latest.tar.gz"
            export disk_template="cubieboard2"
            ;;
        "rpi2")
            export img_name="ArchLinuxARM-rpi-2-latest.tar.gz"
            export disk_template="rpi2"
            ;;
        "rpi")
            export img_name="ArchLinuxARM-rpi-latest.tar.gz"
            export disk_template="rpi"
            ;;
        *)
            logging_error "Board model ${board_model} not supported"
    esac
    export img="${img_path}/${img_name}"
}


function format_disk {
    wipe_disk ${install_disk}
    create_disk_template ${disk_template} ${install_disk}
}


function install_img {
    logging_info "Extracting ${img} to ${mount_path}/root"
    bsdtar -xpf "${img}" -C "${mount_path}/root"
    sync
    logging_info "Extracted ${img} to ${mount_path}/root"
}


function post_install {
    
    case ${board_model} in
        "cubieboard2")
            _post_install_template_cubieboard2
            ;;
        "xu4")
            _post_install_template_xu4
            ;;
        "rpi2")
            _post_install_template_rpi
            ;;
        "rpi")
            _post_install_template_rpi
            ;;
    esac

}


function clean_up {

    logging_info "Cleaning up ${mount_path}"
    umount "${mount_path}/boot" > /dev/null 2>&1
    umount "${mount_path}/root" > /dev/null 2>&1
    rmdir "${mount_path}/boot"
    rmdir "${mount_path}/root"
    rmdir "${mount_path}"

}


function main {
    select_img
    format_disk
    install_img
    post_install
    clean_up
}


main

exit 0
