## `archlinuxarm-installer`
Universal, automatic installer for `ArchLinux ARM`

`archlinuxARM-installer` version 1.0 

`archlinuxARM-installer` is the tool to install `ArchLinuxARM` automatically 
on supported devices.  It was designed primarily to assist with the 
installation of `ARM clusters`.  

### Why Bash?
Bash isn't the brightest choice for this kind of programming.  But this tool involves calling (the syscalls underneath of) fdisk, dd that don't really have any binding except for C. So Bash is the fastest way here.

### Usage: `archlinuxARM-installer` [OPTION] 
This tool requires sudo to root privileges.

### Options:
 `-h`      print out this help message  
 `-l`      select log level (debug, info, warning, error)  
 `-d`      path to ArchLinuxARM image directory  
 `-b`      path to block device to be installed (/dev/sdX)  
 `-m`      board model name  

### Example:
```
$ sudo ./src/archlinuxARM-installer -d /home/stk/dwnl/imgs/ -b /dev/sdb -m odroid_xu4
```

### Supported devices:  

&nbsp;**notes**:  
*Device names are taken from their ArchLinuxARM.org page URL, with "-" replaced by "_"*  
*Please feel free to send PR or feature request for new board support*  

- a10_olinuxino_lime  
- a20_olinuxino_lime  
- a20_olinuxino_lime2  
- a20_olinuxino_micro  
- beagleboard  
- beagleboard_xm  
- beaglebone  
- beaglebone_black  
- beaglebone_black_wireless  
- beaglebone_green  
- beaglebone_green_wireless  
- clearfog  
- cubieboard  
- cubieboard_2  
- cubietruck  
- cubox_i  
- odroid_c1  
- odroid_c2  
- odroid_hc1  
- odroid_hc2  
- odroid_u2  
- odroid_u3  
- odroid_x  
- odroid_x2  
- odroid_xu  
- odroid_xu3  
- odroid_xu4  
- pandaboard  
- pcduino3  
- raspberry_pi  
- raspberry_pi_2  
- raspberry_pi_3  
