# Security-Enhanced Arch Linux Install Guide

Before contributing see: [**Contributing.md**](./Contributing.md).

<details>
  <summary markdown="span">Table of Contents</summary> <br />

1. [Description and usage](#description-and-usage)
   1. [Preview of the setup](#preview-of-the-setup)
   2. [External drive partitions](#external-drive-partitions)
   3. [Internal drive LVM configuration](#internal-drive-lvm-configuration)
   4. [Boot procedures](#boot-procedures)

2. [Before you begin](#before-you-begin)
   1. [Make backups](#make-backups)
   2. [UEFI Secure Boot](#uefi-secure-boot)
   3. [Comments](#comments)
   4. [Pacman mirrorlist](#pacman-mirrorlist)
   5. [Drive naming scheme](#drive-naming-scheme)
   6. [Partition naming scheme](#partition-naming-scheme)

3. [Pre-installation](#pre-installation)
   1. [Prepare the external drive for encryption](#prepare-the-external-drive-for-encryption)
   2. [Encrypt the external drive](#encrypt-the-external-drive)
      1. [Create and encrypt the key in the external drive](#create-and-encrypt-the-key-in-the-external-drive)
   3. [Prepare the internal drive for encryption](#prepare-the-internal-drive-for-encryption)
   4. [Encrypt the internal drive](#encrypt-the-internal-drive)
   5. [Configure LVM](#configure-lvm)

4. [Install Arch Linux](#install-arch-linux)
   1. [Pacman setup](#pacman-setup)
   2. [Additional storage management](#additional-storage-management)
   3. [Configure FSTAB](#configure-fstab)
   4. [Set the time zone](#set-the-time-zone)
   5. [Locale](#locale)
   6. [Network](#network)
   7. [`mkinitcpio`](#mkinitcpio)
   8. [User Management](#user-management)
   9. [UEFI secure boot](#uefi-secure-boot)
      1. [Enable secure boot](#enable-secure-boot)
      2. [Enable Password On Boot (Optional)](#enable-password-on-boot-optional)
      3. [Lock the UEFI (Optional)](#lock-the-uefi-optional)

5. [System Hardening](#system-hardening)
   1. [Encrypt the swap partition](#encrypt-the-swap-partition)
   2. [Restricting `umask`](#restricting-umask)
   3. [Make access to `/boot` very strict](#make-access-to-boot-very-strict)
   4. [Apply some Linux PAM rules](#apply-some-linux-pam-rules)
   5. [“Disable” Core Dumps](#disable-core-dumps)
   6. [Refresh `pacman` PGP keyring keys](#refresh-pacman-pgp-keyring-keys)

6. [Advanced System Hardening](#advanced-system-hardening)
   1. [SysRq — reboot/power off](#sysrq--rebootpower-off)
   2. [File and directory access control](#file-and-directory-access-control)
      1. [SUID](#suid)
      2. [Unowned files](#unowned-files)
      3. [World-writable files](#world-writable-files)
      4. [Sticky bit](#sticky-bit)
   3. [Network Hardening](#network-hardening)
      1. [TCP security parameters](#apply-some-tcp-security-parameters)
         1. [Firewall](#firewall)
         2. [Arno's Firewall](#arnos-firewall)
         3. [Uncomplicated Firewall (`ufw`)](#uncomplicated-firewall-ufw)
   4. [Auditing and IDS](#auditing-and-ids)
      1. [CHKRootkit](#chkrootkit)
      2. [RKHunter](#rkhunter)
      3. [Afick](#afick)
      4. [Lynis](#lynis)
      5. [Tiger](#tiger)
      6. [ClamAV](#clamav)
   5. [USBGuard](#usbguard)
   6. [AppArmor](#apparmor)
   7. [Sandboxing — Bubblewrap](#sandboxing--bubblewrap)
   8. [Bleachbit](#bleachbit)
   9. [Neovim (Text Editor)](#neovim-text-editor)
      1.  [Awesome Neovim](#awesome-neovim)
   10. [Tomb (Encryption)](#tomb-encryption)

7. [Resources](#resources)

</details>

---

## Description and usage

This guide contains information that may be found in books, articles, reports, etc. \
It's partially a compilation of that information.

It is **strongly focused on privacy and security**.

You will need a second device with access to the internet, this is because some sections point to external content which you are going to need.

The text editor will be `nano` as it is beginner-friendly and requires (almost) no prior knowledge. \
Every line written in `nano` will be indented a total of 8 spaces from the left side.

This guide is not intended for everybody, you'll most likely need to modify it to your own needs.

Originally based on and inspired by [the guide](https://www.reddit.com/r/archlinux/comments/7np36m/detached_luks_header_full_disk_encryption_with/) written by [wincraft71](https://www.reddit.com/user/wincraft71).

I encourage you to look at the [ArchWiki](https://wiki.archlinux.org) and all the files in this repository before following the guide.

If you have **any** questions open an issue on GitHub, and add the `question` label. \
Just know that I may not respond to any issues, that said, I'm going to try my best.

### Preview of the setup

The external drive will have a GPT and 2 partitions.

> The external drive _should_ be something small and easy to carry around. \
> Something like a USB drive or an SD card will suffice.

> The availability of the external drive to your computer should be limited. \
> Otherwise, the purpose of using the external drive as an authentication factor is defeated.

The internal drive will have one GPT partition. \
This partition will be the LVM physical volume and inside it there will be a volume group which will contain 6 logical volumes.

The configuration shown in this guide allows for a total of 4 passwords to be used at boot.\
The first being optional, the second and third for the decryption of the internal drive, and the fourth for the user login.

### External drive partitions

1. EFI system partition (ESP)

2. LUKS2 partition
   - Detached LUKS Header (`header.img`)
   - Encrypted pseudo-random key (`key.img`)

### Internal drive LVM configuration

- Physical volume (`arch--pv`)
  - Volume group (`arch--vg`)
    - ROOT \[EXT4] (Where Arch Linux is going to be installed)
    - HOME \[EXT4] (Unprivileged user home directory)
    - SWAP \[LINUX SWAP]
    - VAR \[EXT4] (Mounted as `/var`)
    - TMP \[XFS] (Mounted as `/tmp`)

### Boot procedures

These are the steps you are going to go through when booting your computer.

1.  Plug in the external drive
2.  Power on the computer (with the internal drive)
3.  Password0 (Password on Boot — optional)
4.  Password1 (Decrypt the external drive's second partition)
5.  Password2 (Decrypt `key.img` — inside the external drive's second partition)
6.  Boot Arch Linux
7.  Remove the external drive
8.  Password3 (Login)

## Before you begin

### Make backups

We are going to shred (erase data from) the internal and external drives, so make sure you have a backup of the most important things.

### UEFI Secure Boot

If your machine doesn't have support for UEFI secure boot, you may still use _some_ parts of this guide. \
Albeit, you will need to install a bootloader (as opposed to booting Linux using the EFI STUB). \
If you want to retain a similar level of security as the UEFI secure boot configuration you will need to implement a similar security measure.

Secure boot should be disabled/off.

To check the secure boot status on a Linux machine:

```bash
    bootctl status
```

The output should be the following:

> `Secure Boot: disabled`

If it is enabled refer to you motherboard's manual for instructions on how to disable it.

> The status of Secure Boot can be checked from the UEFI itself.

### Comments

Most of the commands will have a comment next to, above, or beneath them.

Comments always begin with:

> `#`

This also applies when using `nano` to edit files.

### Pacman mirrorlist

Go to [https://www.archlinux.org/mirrorlist/](https://www.archlinux.org/mirrorlist/), select your country, uncheck 'http', and select the desired internet protocol.

Click on “Generate list”, and note down the results on something other than the machine you are (hopefully) going to install Arch Linux on.

### Drive naming scheme

“Internal drive” refers to the main drive on which we're going to install Arch Linux.

“External drive” is the drive which contains the EFI ESP along with the needed files for decrypting the internal drive.

/dev/SD\[Type of drive][partition]

Internal = \[(SD)A], e.g. `/dev/sda`, `/dev/sdb`

> The internal drive will be represented as `/dev/SDA`.

External = \[(SD)B], e.g. `/dev/sdc`, `/dev/sdb`

> The external drive will be represented as `/dev/SDB`.

### Partition naming scheme

The partition number will be appended to the name of the drive.
It will be an integer.

Examples:

`/dev/SDA3`

A = internal drive, e.g. `/dev/sda` \
3 = Third partition, e.g. `/dev/sda3`

`/dev/SDB1`

B = external drive, e.g. `/dev/mmcblk0` \
1 = First Partition, e.g. `/dev/mmcblk0p1`

`/dev/SDB3`

C = external drive, e.g. `/dev/sdc` \
3 = Second Partition, e.g. `/dev/sdc3`

## Pre-installation

Follow the [Arch Linux Installation guide](https://wiki.archlinux.org/index.php/Installation_guide) from [Acquire an installation image](https://wiki.archlinux.org/title/Installation_guideAcquire_an_installation_image) until [Partition the disks](https://wiki.archlinux.org/title/Installation_guidePartition_the_disks).

“[Partition the disks](https://wiki.archlinux.org/title/Installation_guidePartition_the_disks)” should not be followed.

### Prepare the external drive for encryption

Make the directories we're going to make use of in the future:

```bash
    mkdir /mnt/root/ /mnt/storage
```

**Warning!** This operation _may_ take **hours** to complete! \
For minimizing the time, try to change the number of iterations from 10 to something like 5 or 3.

For more information see: `man shred`

```bash
    lsblk # List block devices, e.g. `/dev/sdb2`

    # Shreds the drive 10 times with pseudo-random data (from `/dev/urandom`)

    shred -f -n 10 --random-source=/dev/urandom /dev/SDB

    ## -f (--force)      = If the permissions don't allow writing, it changes them to do so
    ## -n (--iterations) = Number of iterations
```

We will be creating 2 GPT partitions on an example ~8 GiB external drive. \
I recommend the minimum storage space to be around 1 GiB.

You may want to see why using the newer “Advanced Format” (AF) disk sector format might be better.
[Wikipedia](https://en.wikipedia.org/wiki/Advanced_Format#4K_native_(4Kn))
TL;DR: Drives that support the Advanced Format should use it, otherwise the drive will experience performance issues.

For more information see: `man gdisk`

```bash
    gdisk /dev/SDB
    o # Make the GPT
    y # Confirm making the GPT

    ## If you are going to use the AF, enter `x` (experts' menu), and from there change the sector alignment value using `l`
    ## More information can be found in `man 8 gdisk`

    n # Make first partition (ESP)
    ENTER  1
    ENTER # Auto
    512M
    EF00  # EFI system partition
    n     # 2nd partition
    ENTER # 2
    ENTER # Auto
    +256M # Personal preference, I think 256 MiB should suffice (LUKS header + key will be stored here)
    8309  # Linux LUKS
    w     # Write the changes to drive
    y     # Confirm writing
```

Make the OS aware of the newly partitioned external drive (if it isn't already):

```bash
    lsblk
    partprobe /dev/SDB
```

### Encrypt the external drive

The actual encryption is achieved using:

- SHA512 as the hashing algorithm
- Twofish as the block cipher
- XTS as the AES mode of operation

```bash
    lsblk

    mkfs.fat -F32 /dev/SDB1  Format the 1st partition as FAT32

    cryptsetup -h=sha512 -c=twofish-xts-plain64 -s=512 -i 30000 luksFormat /dev/SDB2

    ## -h (--hash)      = Hashing Algorithm used
    ## -c (--cipher)    = Cipher used
    ## -s (--key-size)  = Size of key (in bits)
    ## -i (--iter-time) = Time it takes to run through PBKDF password processing (in milliseconds)
    ## The higher the better, set it as high as you can tolerate

    # The size of the key is 512 bits, because that's the maximum a mode like XTS allows for

    YES       # Agree to the cryptsetup setup of the 2nd partition
    PASSWORD1 # Enter the desired password for the 2nd partition
```

#### Create and encrypt the key in the external drive

```bash
    cryptsetup open /dev/SDB2 external # Open the 2nd partition as `/dev/mapper/external`
    PASSWORD1                          # Enter the password for the 2nd partition

    mkfs.ext2 /dev/mapper/external # Format `/dev/mapper/external` as EXT2, so that we can mount it
    # EXT2 is used as we do not require journaling

    ## Yes, we could've just formatted it as EXT4, then removed journaling using `tune2fs`, but it would overcomplicate things, and you wouldn't really get an advantage

    mount /dev/mapper/external /mnt/storage # Mount `/dev/mapper/external` as `/mnt/storage`

    cd /mnt/storage

    ## Create the pseudo-random key (key.img)

    ## Remember that we will only need 8192 bytes of the key, making the keyfile bigger can make the attack surface of the key bigger as well
    ## But it wouldn't matter as the position of the key and its size could theoretically be bruteforced

    ## 20 Mibibytes is more than enough
    dd if=/dev/urandom of=key.img bs=20M count=1

    # As I have come to notice, if the file is smaller than it needs to be, `cryptsetup` automatically scales it

    ## Encrypt key.img using cryptsetup and "--align-payload=1"
    ## Cipher shuffling is not required (Twofish/Serpent)
    ## It's debatable if cipher shuffling would actually make a difference (my theory is that it doesn't)
    ## But I still like to do it anyways
    ## I have the same opinion as the author of the original guide, I am not copying his words

    ## Serpent, albeit slightly slower, might be the most secure AES finalist
    ## This is, of course, arguable

    cryptsetup --align-payload=1 -h=sha512 -c=serpent-xts-plain64 -s=512 -i 15000 luksFormat key.img

    YES
    PASSWORD2 # Enter the desired password for key.img

    cryptsetup open key.img lukskey # Open `key.img` as lukskey
    PASSWORD2                       # Enter the password for key.img
```

### Prepare the internal drive for encryption

```bash
    lsblk
```

Shreds the drive 10 times with pseudo-random data. \
**Warning!** This operation _may_ take **a very long time** to complete!

```bash
    shred -f -n 10 --random-source=/dev/urandom /dev/SDA
```

We will create 1 GPT partition on an example ~500 GiB internal drive.

For more information see: `man gdisk`

Do not forget to set the file system type to `8303` (`Linux x86 root (/)`) as a future script will need it to identify the drive (`fstab.sh`).

As with the external drive, if the drive you're using supports AF, do use it.

```bash
    gdisk /dev/SDA
    o # Make the GPT
    y # Confirm making the GPT

    ## Change the selector alignment value here (for using the Advanced Format)

    n # Make the only partition
    ENTER # 1
    ENTER # Auto
    ENTER # Auto
    8303  # Linux x86 root (/)
    w # Write changes to drive
    y # Confirm writing
```

Make the OS aware of the newly partitioned internal drive.

For more information see: `man partprobe`

```bash
    lsblk
    partprobe /dev/SDA
```

Generate the `header.img` file which will act as the detached LUKS header:

```bash
    # The header.img needs to be at least ~2 MiB big, if not, the LUKS2 header might not fit
    dd if=/dev/zero of=header.img bs=2M count=1 # Generate the `header.img`
```

### Encrypt the internal drive

This will encrypt the internal drive using `header.img` as the LUKS2 header and **a portion** of `key.img` as the key.

```bash
    cryptsetup -h=sha512 -c=serpent-xts-plain64 -s=512 -d=/dev/mapper/lukskey --keyfile-offset=X -l=8192 luksFormat /dev/SDA1 --header header.img

    ## -d (--key-file)     = Use a file as a passphrase
    ## -l (--keyfile-size) = Read a maximum of bytes from the keyfile
    ## --header            = Store the header to a file (called a detached header)

    ## Replace the X in the --keyfile-offset with the desired value (the value is in bytes),
    ## ~4186 kilobytes should be the maximum for a 2 MiB header
    ## Try to pick somewhere in between, be aware that you should never share this value with anyone
    ## Remember this value, as we will need it in the future

    ## In some cases you will get a warning about the keyslot count
    ## For this setup it's harmless
    ## As we won't use another key/passphrase, having another keyslot is useless
```

Open the internal drive as `/dev/mapper/arch--pv`:

```bash
    cryptsetup open --header header.img -d=/dev/mapper/lukskey --keyfile-offset=X --keyfile-size=8192 /dev/SDA1 arch--pv
```

Close `lukskey` and unmount the second partition:

```bash
    cd /
    cryptsetup close lukskey
    umount /mnt/storage
```

### Configure LVM

What's LVM?
→ [https://wiki.archlinux.org/title/LVM](https://wiki.archlinux.org/title/LVM)

The example internal drive here is a ~500 GB HDD. \
Adjust the LV sizes to your needs. \
Make sure `root-lv` gets at least ~20 GiB.

Another thing you should be aware of, is the size of swap, some systems use swap exclusively, others don't at all.

What's swap?
→ [https://wiki.archlinux.org/title/Swap](https://wiki.archlinux.org/title/Swap)

```bash
    lsblk
    pvcreate /dev/mapper/arch--pv          # Create the PV on `arch--pv`
    vgcreate arch--vg /dev/mapper/arch--pv # Create the `arch--vg` VG on the `arch--pv` PV
    lvcreate -L 45G arch--vg -n root-lv # Create the ROOT LV in the `arch--vg` VG
    lvcreate -L 4G arch--vg -n swap-lv  # Create the SWAP LV in the `arch--vg` VG
    lvcreate -L 10G arch--vg -n var-lv  # Create the VAR  LV in the `arch--vg` VG
    lvcreate -L 5G arch--vg -n tmp-lv   # Create the TMP  LV in the `arch--vg` VG
    lvcreate -L 50G arch--vg -n home-lv # Create the HOME LV in the `arch--vg` VG

    pvdisplay # Check PV
    vgdisplay # Check VG
    lvdisplay | less # Check LVs
    mkfs.ext4 /dev/arch--vg/root-lv # Format `root-lv` as EXT4
    mkfs.ext4 /dev/arch--vg/home-lv # Format `home-lv` as EXT4
    mkfs.ext4 /dev/arch--vg/var-lv  # Format `var-lv`  as EXT4
    mkfs.xfs /dev/arch--vg/tmp-lv   # Format `tmp-lv`  as XFS
    mkswap /dev/arch--vg/swap-lv # Format `swap-lv` as linux swap
    swapon /dev/arch--vg/swap-lv # Enable `swap-lv` as swap (for performance and testing)
    mount /dev/arch--vg/root-lv /mnt/root     # Mount `root-lv`  on `/mnt/root`
    mkdir /mnt/root/boot # Make the `/boot` which will be needed by secure boot
    mount /dev/mapper/external /mnt/root/boot # Mount `external` on `/mnt/root/boot`
    lsblk
    mkdir /mnt/root/boot/efi # Make the `/boot/efi` directory which will be used for configuring secure boot
    mount /dev/SDB1 /mnt/root/boot/efi # Mount the first partition of the external drive on `/mnt/root/boot/efi`
```

## Install Arch Linux

### Pacman setup

Write the result you noted down from [https://www.archlinux.org/mirrorlist/](https://www.archlinux.org/mirrorlist/).

```bash
    rm /etc/pacman.d/mirrorlist && nano /etc/pacman.d/mirrorlist
    # Remove the “#” from all the lines with “#Server” in front, see the example of a mirrorlist below.

    ## To save the file in nano: CTRL + S
    ## To exit nano: CTRL + X
    ## To save and exit in nano: CTRL + S, CTRL + X
```

<details>
  <summary>An example of a repository mirrorlist</summary> <br />

```bash
##
## Arch Linux repository mirrorlist
## Generated on 2021-06-16
##

## Canada
Server = https://mirror.0xem.ma/arch/$repo/os/$arch
Server = https://mirror.csclub.uwaterloo.ca/archlinux/$repo/os/$arch
Server = https://mirror2.evolution-host.com/archlinux/$repo/os/$arch
Server = https://muug.ca/mirror/archlinux/$repo/os/$arch
Server = https://mirror.scd31.com/arch/$repo/os/$arch
Server = https://mirror.sergal.org/archlinux/$repo/os/$arch
```

</details>

Install the necessary packages into the `root-lv` LV mounted on `/mnt/root`:

```bash
    pacstrap /mnt/root base base-devel efibootmgr git gnupg linux-hardened man nano lvm2
```

### Additional storage management

Mount `home-lv` on `/mnt/home`, this is done because we will be creating a user home directory in the future:

```bash
    mount /dev/arch--vg/home-lv /mnt/root/home
```

Set all the permissions except execute (`x`) in `/mnt/root/tmp`:

```bash
    chmod 1666 /mnt/root/tmp
```

`arch-chroot` into the root LV:

```bash
    arch-chroot /mnt/root #`arch-chroot` into the root LV
```

Clone this repository, along with all the files we'll need:

```bash
    cd /mnt
    git clone -b main https://github.com/thegitplant/SE_Arch_Install_Guide.git Arch
```

### Configure FSTAB

I made a “secure” FSTAB template.

It is only a template, so we need a way to complete it seamlessly without much work. \
I created a script that does just that, so you don't have to.

I didn't use `genfstab` as it doesn't secure the FSTAB very well.

```bash
    cd Scripts
    chmod +x fstab.sh # Give the permission to execute
    ./fstab.sh        # Execute
```

Verify the FSTAB configuration:

```bash
    lsblk -f        # Get the UUIDs of `/dev/SDB1` and `/dev/SDB2`
    nano /etc/fstab # Verify if the first two fields match the UUIDs of `/dev/SDB1` and `/dev/SDB2`
```

<details>
  <summary markdown="span">Example of a complete FSTAB</summary> <br />

```bash
#FSTAB = File System TABle
#/etc/fstab: static file system information.
#Use 'blkid' or 'lsblk -f' to print the universally unique identifier for a device.
#This may be used with UUID= as a more robust way to name devices
#that works even if disks are added and removed. See fstab(5) for more information on identifiers.

# <file system>             <mount point>  <type>  <options>  <dump>  <pass>

#EFI ESP AND SECURE BOOT
UUID=3CAC-0A5D                            none     vfat     noauto,nodev,nosuid,noexec     0   2
UUID=c7d56d2a-0a78-4901-ae1b-fce6aadae3a9 none     ext4     noauto,nodev,nosuid,noexec     0   2

#LVM LOGICAL VOLUMES
/dev/mapper/arch----vg-root--lv   /        ext4     auto,exec,rw                           0   1
/dev/mapper/arch----vg-home--lv   /home    ext4     auto,exec,rw,nodev,nosuid              0   2
/dev/mapper/arch----vg-var--lv    /var     ext4     auto,nosuid,noexec,rw                  0   2
/dev/mapper/arch----vg-swap--lv   none     swap     swap                                   0   0

#TMP PARTITIONS
/dev/mapper/arch----vg-tmp--lv    /tmp     xfs      rw,noexec,nosuid,nodev                 0   0
/var/tmp                          /var/tmp none     rw,noexec,nosuid,nodev                 0   0

# You may want to use Tmpfs
# See: https://www.kernel.org/doc/html/latest/filesystems/tmpfs.html
## tmpfs                          /dev/shm tmpfs    rw,noexec,nodev,size=2G                0   0
/tmp                              /tmp none         rw,noexec,nosuid,nodev,bind            0   0

#PROC
proc                              /proc   proc      nosuid,nodev,noexec,hidepid=2,gid=proc 0   0
```

</details>

### Set the time zone

Replace “Region” with the desired region found in `/usr/share/zoneinfo`. \
Replace the “City” too.

For more information see: [https://wiki.archlinux.org/index.php/System_time#Time_standard](https://wiki.archlinux.org/index.php/System_time#Time_standard)

```bash
    ln -sf /usr/share/zoneinfo/Region/City /etc/localtime
    hwclock --systohc
```

### Locale

Set up the locale.

For more information see: [https://wiki.archlinux.org/index.php/installation_guide#Localization](https://wiki.archlinux.org/index.php/installation_guide#Localization)

```bash
    nano /etc/locale.gen

        # Uncomment the desired locale by removing the `#` in front of it

    locale-gen
```

### Network

If you have a wireless interface, and you won't use it, you can disable it like this:

```bash
    ip link Get the name of your wireless interface
    ip link set yourwirelessinterface down  Disable it, change the state of the device to DOWN
```

Set your hostname.

> Replace `thehostname` with your desired hostname.

For more information see: [https://wiki.archlinux.org/title/Network_configuration#Set_the_hostname](https://wiki.archlinux.org/title/Network_configuration#Set_the_hostname)

```bash
    hostnamectl set-hostname thehostname
```

Add the **temporary** DNS servers to be used — remove any other DNS servers:

```bash
    nano /etc/resolv.conf

        ## For the time being, you can simply use `1.1.1.1` or `8.8.8.8`
        ## The servers used below are supposedly "anonymous" DNS servers, meaning that they do not keep logs

        # Digitalcourage e.V.
        nameserver 85.214.20.141

        # f.6to4-servers.net, ISC, USA
        nameserver 204.152.184.76

        # You may find more at: https://servers.opennicproject.org/
```

Test if the DNS is working:

```bash
    ping archlinux.org
```

The following error will happen if DNS is not working, in that case use a reliable server, such as `1.1.1.1`, instead.

> `ping: archlinux.org: Temporary failure in name resolution`

### `mkinitcpio`

What's `mkinitcpio`? \
→ [https://wiki.archlinux.org/title/Mkinitcpio](https://wiki.archlinux.org/title/Mkinitcpio)

Give execution rights and execute the `enc_hooks.sh` script:

```bash
    chmod +x enc_hook.sh
    ./enc_hook.sh
```

Edit the `mkinitcpio` hooks:

```bash
    cd ../enc_hooks
    nano 2/encrypt_hook

        # Replace the 'X' in --keyfile-offset with your keyfile offset!!!

    cp 1/encrypt_hook /etc/initcpio/install/
    cp 2/encrypt_hook /etc/initcpio/hooks/

    nano /etc/mkinitcpio.conf

        # Add the following hooks (but don't replace them):
	    ## By that I mean that you should only add the things in the parentheses. They are separated by one space (` `)
        MODULES=(loop)
	    # `encrypt_hook` and `lvm2` should come after `block` and before `filesystems`
        HOOKS=(encrypt_hook lvm2)

        # Remove the following hooks (if they exist, also don't replace them):
        HOOKS=(systemd sd-lvm2 encrypt)

        COMPRESSION="xz" # Uncomment to enable the XZ compression (it's faster than default)
```

It should look like this:
```bash
MODULES=(loop)
```
...
```bash
HOOKS=(base udev autodetect modconf block encrypt_hook lvm2 filesystems keyboard fsck)
```
...
```bash
COMPRESSION="xz"
```

`...` represents that the variable is found _later_ in the file.

More information about the variables can be found here: [https://wiki.archlinux.org/title/Mkinitcpio#Configuration](https://wiki.archlinux.org/title/Mkinitcpio#Configuration)

### User Management

Change `root`'s password and create a new unprivileged user.

```bash
    passwd # Change the root password

    # Replace `userdir` with the desired user home directory name
    # Replace `johndoe` with your desired username
    useradd -G wheel -m -d /home/userdir -s /bin/bash johndoe

    nano /etc/sudoers

        Defaults env_reset
        Defaults timestamp_timeout=0
        root ALL=(ALL) ALL
        johndoe ALL=(ALL) ALL

    passwd johndoe # Set the password for your user
    chmod -c 0440 /etc/sudoers  # Harden `/etc/sudoers`
```

Limit access to `su` and `sudo`:

```bash
    chgrp wheel $(which su)
    chgrp wheel $(which sudo)
    chmod 4550 $(which su)
    chmod 4550 $(which sudo)
```

Login as `johndoe` and lock the root account.

```bash
    su -l johndoe
    sudo passwd -l root
```

### UEFI secure boot

Before starting this section check if you do in fact have an UEFI as opposed to a BIOS.

To confirm you have UEFI support, run the following:

```bash
    efibootmgr
```

If the output contains boot entries, then you do in fact have an UEFI.

If the output is the following:

> EFI variables are not supported on this system

You do **NOT** have an UEFI, and therefore should not use this section of the guide.

I recommend checking out the following links to get an understanding of UEFI and Secure Boot (they're a good read):

- [https://www.rodsbooks.com/linux-uefi/](https://www.rodsbooks.com/linux-uefi/)
- [https://wiki.archlinux.org/index.php/Unified_Extensible_Firmware_Interface](https://wiki.archlinux.org/index.php/Unified_Extensible_Firmware_Interface)
- [https://wiki.archlinux.org/index.php/Secure_Boot](https://wiki.archlinux.org/index.php/Secure_Boot)

Install `yay` for faster and easier installation of AUR packages.

What's `yay`?
→ [https://github.com/Jguer/yay](https://github.com/Jguer/yay)

```bash
    cd ~ # `cd` in your home directory (even though you should already be there)
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si
```

Install `cryptboot` and `sbupdate` using `yay`.

```bash
    yay cryptboot
    yay sbupdate
```

Configure `cryptboot` and generate EFI keys.

The source code of `cryptboot`: [https://github.com/xmikos/cryptboot](https://github.com/xmikos/cryptboot)

```bash
    cd /mnt/Arch/Scripts
    sudo chmod +x sb1.sh # Give execute permission
    sudo ./sb1.sh # Execute
```

Configure `cryptboot`:

```bash
    sudo nano /etc/cryptboot.conf
        # Remove everything else, and make sure only the following remains:
        BOOT_CRYPT_NAME="cryptboot"
        BOOT_DIR="/boot"
        EFI_DIR="/boot/efi"
        EFI_KEYS_DIR="/boot/efikeys"
```

Generate and enroll the EFI keys:

```bash
    sudo cryptboot-efikeys create
    sudo cryptboot-efikeys enroll
```

Configure `sbupdate`:
<!-- FIXME: This section has not been tested and relies on parts of the original guide -->
```bash
    sudo nano /etc/default/sbupdate
        KEY_DIR="/boot/efikeys"
        ESP_DIR="/boot/efi"
        CMDLINE_DEFAULT="/vmlinuz-linux-hardened root=/dev/mapper/arch----vg-root--lv rw quiet"

    sudo chmod +x sb2.sh
    sudo ./sb2.sh
```

Create the initframfs image using the `linux-hardened` preset:

```bash
    sudo mkinitcpio -p linux-hardened
```

> Most of the time there are a bunch of warnings stating that certain firmware is missing, they are [usually harmless](https://wiki.archlinux.org/title/Mkinitcpio#Possibly_missing_firmware_for_module_XXXX).

Make sure that all the files in `/boot/efikeys`, which start with “DB”, have the “DB” in their name in uppercase.

To check them:

```bash
    ls /boot/efikeys
```

Apply the configuration to the UEFI using `efibootmgr`.

See: `man efibootmgr`

```bash
    sudo efibootmgr -c -d /dev/SDB -p 1 -L "Arch Linux Hardened Signed" -l "EFI\Arch\linux-hardened-signed.efi"
```

This will allow us to boot directly, in other words no bootloader needed.

> _Technically_ the signed Linux EFI stub is the bootloader (because it acts like one).

More information about the EFI Boot Stub can be found here: [https://www.kernel.org/doc/html/latest/admin-guide/efi-stub.html](https://www.kernel.org/doc/html/latest/admin-guide/efi-stub.html)

Exit `arch-chroot` and clean up:

```bash
    umount -R /mnt # Unmount all drives mounted in `/mnt/`
    exit # Exit chroot, repeat until the sqare brackets ('[' and ']') are gone
    cd /
    shutdown 0 # Shut down the computer
```

#### Enable secure boot

Enter into the UEFI.

**Warning:** The menu/sections and the options will most likely vary!

> Use common sense to enable secure boot and to disable legacy boot. \
> For more information about the layout and features of your computer's UEFI, read the manual of your motherboard.

→ Security → Secure Boot — Enable/Yes
→ Disable legacy boot (BIOS mode)
→ Save and Exit

#### Enable Password On Boot (Optional)

**Warning!** Some computers may not have this option!

This prompts the user for an additional password on boot.
Booting resumes only after the user enters the correct password.

→ Security → Password on boot — PASSWORD0

#### Lock the UEFI (Optional)

Set a password on the UEFI itself.
This prevents an attacker from disabling secure boot, and altering the UEFI's settings.

> Note that Secure boot and the UEFI password can be reset, however to do so you would need to physically open up the computer.

> There are security measures to prevent this, such as pouring epoxy resin on your motherboard (therefore preventing the resetting/altering of your UEFI).

→ Security → Set password on UEFI (LOCK) — PASSWORD5

→ Save and reboot

Arch Linux should now be installed and working.

If it isn't booting, or you are having problems, **don't come to me asking for help**.

Only and only if you think there is an issue **with this guide**, then and only then you can **open an issue** on GitHub, otherwise the issue will be ignored and closed.

## System Hardening

### Encrypt the swap partition

There are a couple ways of doing this, here's the one that I think it's the simplest and most popular:

```bash
    sudo nano /etc/crypttab

        swap /dev/mapper/arch----vg-swap--lv /dev/urandom swap,cipher=twofish-xts-plain64,hash=sha512,size=512,nofail
```

What's `/etc/crypttab`?
→ `man crypttab`

The ArchWiki article on swap encryption:
→ [https://wiki.archlinux.org/title/Dm-crypt/Swap_encryption#Using_a_swap_partition](https://wiki.archlinux.org/title/Dm-crypt/Swap_encryption#Using_a_swap_partition)

### Restricting `umask`

For more information about what `umask` is and what it does see: `man umask`

```bash
    sudo nano /etc/profile

        umask 077 # Change the umask to 077
```

### Make access to `/boot` very strict

We do this so that **only** someone with `root` (or `sudo`) privileges can alter the directory.

```bash
    sudo chmod -R g-rwx, o-rwx /boot
```

### Apply some Linux PAM rules

What's PAM?
→ [http://www.linux-pam.org/whatispam.html](http://www.linux-pam.org/whatispam.html)

The following configuration counts the attempts of logins using the `pam_tally2.so` module, and after 2 attempts it blocks access (the ability to log in) for 5 minutes (300s).

`file` represents the failure count logging file.

As always, you may change whatever you want, how you want.

What's `pam_tally2.so`?
→ [http://linux-pam.org/Linux-PAM-html/sag-pam_tally2.html](http://linux-pam.org/Linux-PAM-html/sag-pam_tally2.html)

```bash
    sudo nano /etc/pam.d/system-login

        # Comment the first line by typing “#” in front of it! This is done so failed attempts are not counted twice!
        auth required pam_tally2.so deny=2 unlock_time=300 onerr=succeed file=/var/log/faillog
```

What's `pam_wheel`?
→ [http://linux-pam.org/Linux-PAM-html/sag-pam_wheel.html](http://linux-pam.org/Linux-PAM-html/sag-pam_wheel.html)

The following configurations allow access to `su` **only** if the user is in the `wheel` group. \
It checks if the user is in the `wheel` group using the UID of that user.

```bash
    sudo nano /etc/pam.d/su

        auth required pam_wheel.so use_uid
```

```bash
    sudo nano /etc/pam.d/su-l

        auth required pam_wheel.so use_uid
```

We already disabled the `root` password, by commenting every line in this file we are making sure that `root` definitely can't log into a TTY (even if the password for `root` is re-enabled).

More information available at: [https://tldp.org/LDP/solrhe/Securing-Optimizing-Linux-RH-Edition-v1.3/chap5sec41.html](https://tldp.org/LDP/solrhe/Securing-Optimizing-Linux-RH-Edition-v1.3/chap5sec41.html)

```bash
    sudo -e /etc/securetty # COMMENT EVERY LINE WITH '#' IN FRONT!
```

### “Disable” Core Dumps

This is done, because they occupy space, and more importantly, because they contain sensitive data.

Disabling them means that temporary core dumps will still be logged, but they are never going to be permanently stored.

See: `man coredump.conf`

```bash
    sudo nano /etc/systemd/coredump.conf

        Storage=none
        ProcessSizeMax=0
```

### Refresh `pacman` PGP keyring keys

See: `man pacman-key`
See: `man gpg`

```bash
    pacman-key --refresh-keys
```

## Advanced System Hardening

### SysRq — reboot/power off

Enable Linux Magic System Request Key for reboot/power off.

See: [https://www.kernel.org/doc/html/latest/admin-guide/sysrq.html](https://www.kernel.org/doc/html/latest/admin-guide/sysrq.html)

```bash
    echo 128 >> /proc/sys/kernel/sysrq
```

### File and directory access control

#### SUID

SUID files can be exploited allowing for privilege escalation. \
A good explanation of why they can be dangerous is available at: [https://gtfobins.github.io/#+suid](https://gtfobins.github.io/#+suid)

And a more in-depth look at why they can be dangerous can be found here: [https://wiki.gentoo.org/wiki/Security_Handbook/File_permissions](https://wiki.gentoo.org/wiki/Security_Handbook/File_permissions)

Finding files that have the SUID and/or SGID bit on them is done like this.

```bash
    find / -perm -004000 -perm 002000 -type f -print
```

Do this for files that don't need the SUID/SGID bit (most likely all):

```bash
chmod u-s /path/to/file # Unset the SUID bit for a file
chmod g-s /path/to/file # Unset the SGID bit for a file
```

#### Unowned files

Look for files that aren't owned (there shouldn't be any):

```bash
    find / -nouser -o -nogroup
```

However, if there are, you can simply change the ownership, or remove them.

See: `man chown`

#### World-writable files

Look for world-writable files.

```bash
    find / -perm -o+w
```

Word writable files can be dangerous, so be careful about what permissions they have.

#### Sticky bit

Find files/directories that have the sticky bit set.

```
    find / -perm -1000 -print
```

To unset a sticky bit (where it is not needed) use:

```bash
    chmod -t /path/to/file/or/directory
```

### Network Hardening

#### TCP security variables

These variables prevent certain attacks, exploits, and other things concerning network security. \
They are **not** the ultimate solution to a secure network, they are but just a small cog in a large wheel.

```bash
    lsblk
    mount /dev/SDB2 /mnt/storage
    sudo cat /mnt/Arch/TCP/TCP.conf >> /etc/sysctl.conf # Add the variables
    sudo sysctl -p # Configure the TCP kernel parameters at runtime
```

> We could've put the variables in another file, and then configure `sysctl` with that file as its input. However, it makes no difference.

#### Firewall

What's a firewall?
→ [https://en.wikipedia.org/wiki/Firewall_(computing)](https://en.wikipedia.org/wiki/Firewall_(computing))

In this section I present you with two firewall managers, they are merely here to show you that they exist. \
I chose them, because I thought they may be the most popular. As always you can do whatever you want, how you want.

##### Arno's Firewall

The configuration of Arno's firewall varies from person to person.

You will need to configure it yourself using the documentation available at: [https://github.com/arno-iptables-firewall/aif/](https://github.com/arno-iptables-firewall/aif/)

You may get it by cloning the git repository from GitHub (and looking at the `README`):

```bash
    git clone https://github.com/arno-iptables-firewall/aif.git
```

You may also install it using `yay` (it may not be up to date):

```bash
    yay arno-iptables-firewall
```

##### Uncomplicated Firewall (`ufw`)

The goal of UFW is to make configuring a firewall easy.

You can install it using `yay`, like so:

```bash
    yay ufw
```

As with any other firewall, the configuration is relative to your network, and to your requirements, some might not even need one.

See: `man ufw`
The ArchWiki article on it: [https://wiki.archlinux.org/title/Ufw](https://wiki.archlinux.org/title/Ufw)
The Ubuntu Wiki article on it: [https://wiki.ubuntu.com/UncomplicatedFirewall](https://wiki.ubuntu.com/UncomplicatedFirewall)

#### DNSCrypt

What is DNSCrypt?
→ [https://dnscrypt.info/](https://dnscrypt.info/)

Why would I **not** want to use it? I recommend you read this **before** you start using it.
→ [https://sockpuppet.org/blog/2015/01/15/against-dnssec/](https://sockpuppet.org/blog/2015/01/15/against-dnssec/)

Anyways, I want to use it, how do I do so?

There are a couple of ways to use DNSCrypt, a list of client implementations can be found here: [https://dnscrypt.info/implementations/](https://dnscrypt.info/implementations/)

The one client implementation I recommend the most is called `dnscrypt-proxy`, their [GitHub Wiki](https://github.com/DNSCrypt/dnscrypt-proxy/wiki) explains everything you are going to need.

I have decided that I do not want to use DNSCrypt, what now?

To change the DNS servers used we edited `/etc/resolv.conf`, however there are programs that can overwrite it, for a more permanent and elegant approach we usually use tools such as `dhcpd`.

You can also do it with `resolveconf`, for more details see: [https://wiki.archlinux.org/title/Resolv.conf#Overwriting_of_/etc/resolv.conf](https://wiki.archlinux.org/title/Resolv.conf#Overwriting_of_/etc/resolv.conf)

### Auditing and IDS

What's auditing?
→ [https://en.wikipedia.org/wiki/Information_technology_security_audit](https://en.wikipedia.org/wiki/Information_technology_security_audit)

IDS = Intrusion Detection System

What's an IDS?
→ [https://en.wikipedia.org/wiki/Intrusion_detection_system](https://en.wikipedia.org/wiki/Intrusion_detection_system)

What does this have to do with hardening? \
By looking for possible vulnerabilities you are going to know what's wrong, from that point all you need to do is find a way to patch it. It's easier said than done.

In this section I don't go into detail, instead I provide you with software that is designed to help you with auditing and detecting intrusions.

#### CHKRootkit

CHKRootkit is a popular tool used to check for possible rootkits.

What's a rootkit?
→ [https://en.wikipedia.org/wiki/Rootkit](https://en.wikipedia.org/wiki/Rootkit)

```bash
    yay chkrootkit # Install CHKRootkit
```

#### RKHunter

RKHunter has the same purpose as that of CHKRootkit: scan for rootkits.

See: [https://en.wikipedia.org/wiki/rkhunter](https://en.wikipedia.org/wiki/rkhunter)

```bash
    sudo pacman -S rkhunter # Install RKHunter
```

#### Afick

Afick is another tool used for auditing, it specializes in monitoring changes and seeing if something looks suspicious.

See: [http://afick.sourceforge.net/](http://afick.sourceforge.net/)

```bash
    yay afick # Install Afick
```

#### Lynis

If I had to pick only one auditing tool, it would be Lynis.

What is Lynis?
→ [https://cisofy.com/lynis/](https://cisofy.com/lynis/)

The installation instructions can be found here: [https://cisofy.com/lynis/#installation](https://cisofy.com/lynis/#installation)

#### ClamAV

What's ClamAV?
→ [https://en.wikipedia.org/wiki/Clam_AntiVirus](https://en.wikipedia.org/wiki/Clam_AntiVirus)

```bash
    sudo pacman -S clamav # Install ClamAV
    sudo freshclam # Refresh the virus database
```

The complete process of Auditing goes beyond this guide, if you want more auditing feel free to research it yourself.

### USBGuard

USBGuard is used to “guard” your computer against unwanted/unknown and/or possibly malicious USB devices by implementing a whitelist/blacklist system.

Official website: [https://usbguard.github.io/](https://usbguard.github.io/)

```bash
    sudo pacman -S usbguard # Install USBGuard
```

### AppArmor

What's AppArmor?
→ [https://gitlab.com/apparmor/apparmor/-/wikis/About](https://gitlab.com/apparmor/apparmor/-/wikis/About)

The ArchWiki article on it: [https://wiki.archlinux.org/title/AppArmor](https://wiki.archlinux.org/title/AppArmor)

You can install AppArmor with `pacman`:

```bash
    sudo pacman -S apparmor
```

### Sandboxing — Bubblewrap

See: [https://wiki.archlinux.org/index.php/Bubblewrap](https://wiki.archlinux.org/index.php/Bubblewrap).

You may install Bubblewrap like so:

```bash
    pacman -S bubblewrap
```

> Run it with `bwrap`

### Bleachbit

Bleachbit is used to clean files that are no longer necessary.

See: [https://www.bleachbit.org/](https://www.bleachbit.org/)

### Neovim (Text Editor)

Neovim is an improved version of Vim, which in turn is an improved version of the UNIX `vi`.
It allows for blazing fast editing of files (that is, only if you know how to use it).

```bash
    sudo pacman -S neovim  Install Neovim
```

> Command line interface: `nvim`

The ArchWiki article: [https://wiki.archlinux.org/title/Neovim](https://wiki.archlinux.org/title/Neovim)
Official Website: [https://neovim.io/](https://neovim.io/)

Neovim is quite flexible, therefore there are a number of extensions(plugins) for it.

#### Awesome Neovim

> Collections of awesome Neovim plugins. Mostly targeting Neovim specific features.

→ [https://github.com/rockerBOO/awesome-neovim](https://github.com/rockerBOO/awesome-neovim)

### Tomb (Encryption)

Tomb is a tool that allows for easy encryption of directories (tombs).

See: [https://wiki.archlinux.org/title/Tomb](https://wiki.archlinux.org/title/Tomb)

Official website: [https://www.dyne.org/software/tomb/](https://www.dyne.org/software/tomb/)

## Resources

I have used the following resources to check, improve, and consider implementing certain parts of this guide.

Websites:

- [ArchWiki](https://wiki.archlinux.org/)
- [Gentoo Wiki](https://wiki.gentoo.org)
- [Bob Cromwell](https://cromwell-intl.com/)
- [LUKS2 format documentation](https://gitlab.com/cryptsetup/LUKS2-docs)
- [The paranoid #! Security Guide (Archived)](https://web.archive.org/web/20140220055801/http://crunchbang.org:80/forums/viewtopic.php?id=24722)
- [Reddit post by wincraft71](https://www.reddit.com/r/archlinux/comments/7np36m/detached_luks_header_full_disk_encryption_with/)
- [Roderick W. Smith's Web Page](https://www.rodsbooks.com/)
- [The Linux Kernel documentation](https://www.kernel.org/doc/html/latest/)
- [https://sockpuppet.org](https://sockpuppet.org)
- [People @EECS ](https://people.eecs.berkeley.edu/)
- [XEX-based tweaked-codebook mode with ciphertext stealing (XTS)](https://en.wikipedia.org/wiki/Disk_encryption_theory#XEX-based_tweaked-codebook_mode_with_ciphertext_stealing_(XTS))
- [XTS weaknesses](https://en.wikipedia.org/wiki/Disk_encryption_theory#XTS_weaknesses)

`man` pages:

This guide wouldn't be existing if it wasn't for the man pages. \
**Most** commands (programs and scripts) were documented by me before using them. \
I encourage you to do the same.

Forget all of this and install and harden Gentoo. https://wiki.gentoo.org/wiki/Handbook:AMD64 https://wiki.gentoo.org/wiki/Hardened_Gentoo
Gentoo is better than Arch, btw.
If you ignore this, please at least use OpenRC instead of Systemd.
