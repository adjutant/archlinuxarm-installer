## `archlinuxarm-installer`
### Universal, automatic installer for `ArchLinux ARM`

`archlinuxARM-installer` is the tool to install `ArchLinuxARM` automatically 
on supported devices.  It was designed primarily to assist with the 
installation of `ARM clusters`.  

### Primary Features:
- Multiple instances of `archlinuxARM-installer` installing to multiple block devices with different board models are supported.
- If a file does not exist in image directory, the tool will download it *automatically* for you.

### Planned Features:
- Progress bar instead of boring logs.  
- Security improvements whenever sudo is involved.  
- Data validation to avoid oopsie moments like dd the root disk.
- Support the remaining board in res/

### Why Bash?
Bash isn't the brightest choice for this kind of programming. But this tool involves calling (the syscalls underneath of) fdisk & dd that don't really have any binding in any languages except for C. So Bash is the fastest way here.  
There is pyparted from RedHat. But it's ~3000 commits, 3 languages Python/C/C++, >10 years old without a single line of documentations or up-to-date comments.  


### DISCLAIMER: 
- BE **EXTRA CAREFUL** WHEN SPECIFIYING BLOCK DEVICE.
- SPECIFIYING THE WRONG BLOCK DEVICE SUCH AS YOUR LAPTOP'S ROOT DISK WILL BE **DISASTROUS**.
- **BE CAREFUL**.
- WHY DON'T I JUST BLOCK `/dev/sda`? Well, `systemd`.


### Usage: `archlinuxARM-installer` [OPTION]  
- This tool requires sudo to root privileges.  
- An image directory is supposed to looks exactly like http://os.archlinuxarm.org/os/ in order to be recognized. Just download any images you need and keep the same directory hierarchy.  
- To download and keep directory hierarchy, you can use this wget command like below
```
$     wget -q -xnH --cut-dirs=1 --show-progress --progress=bar \
        http://sg.mirror.archlinuxarm.org/os/sunxi/boot/cubieboard2/u-boot-sunxi-with-spl.bin\
        -P "${img_path}"
```  

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
