#
# Copyright (C) 2026 The Android Open Source Project
#
# SPDX-License-Identifier: Apache-2.0
#

# Inherit common configuration
include device/rise/common/BoardConfigCommon.mk

# Architecture
# TARGET_ARCH_VARIANT is set by the board configuration.
TARGET_ARCH_VARIANT :=

# Console + early UART kept on userdebug/eng for boot diagnostics (low perf
# impact since they don't open PM gates or flood printk).
ifneq ($(TARGET_BUILD_VARIANT),user)
BOARD_KERNEL_CMDLINE += console=ttyS0,115200
BOARD_KERNEL_CMDLINE += earlycon=uart8250,mmio32,0xd4017000
BOARD_KERNEL_CMDLINE += earlyprintk
# The X100 does not implement Zacas, so SLUB never sets __CMPXCHG_DOUBLE on its
# caches and kmalloc_nolock() bails out unconditionally (mm/slub.c). That kills
# every BPF local storage allocation, which makes netd abort and, with the
# stock netd.rc, reboot-loop the board. Turning slab debugging on makes
# kmem_cache_debug() true, which is the one case where kmalloc_nolock() is
# allowed to fall through to its trylock path.
#
# Any SLAB_DEBUG_FLAGS bit is enough for that, so only enable consistency
# checks (F), and only on the kmalloc-* caches kmalloc_nolock() allocates
# from. Full slab_debug adds red-zoning, poisoning and a stack trace on every
# alloc and free, and takes every cache off the SLUB fastpath. Drop this once
# the kernel side is fixed.
#
# Still best-effort: the trylock can fail and return NULL under contention.
BOARD_KERNEL_CMDLINE += slab_debug=F,kmalloc-*
endif
# BOARD_KERNEL_CMDLINE += androidboot.first_stage_console=1

# Boot image
BOARD_MKBOOTIMG_ARGS := --header_version $(BOARD_BOOT_HEADER_VERSION) --pagesize $(BOARD_KERNEL_PAGESIZE) --kernel_offset 0x200000
BOARD_MKBOOTIMG_INIT_ARGS := --header_version $(BOARD_INIT_BOOT_HEADER_VERSION)

# Bootconfig
BOARD_BOOTCONFIG += androidboot.load_modules_parallel=true
BOARD_BOOTCONFIG += androidboot.logcat.buffersize=4M
# GKI

# Dynamic partitions
BOARD_SUPER_PARTITION_GROUPS := spacemit_dynamic_partitions
BOARD_SPACEMIT_DYNAMIC_PARTITIONS_PARTITION_LIST := system vendor vendor_dlkm system_dlkm

# Platform
TARGET_BOARD_PLATFORM := k3
TARGET_BOOTLOADER_BOARD_NAME := k3

# The x100 Soong variant selects the X100 ISA and out-of-order tuning.
TARGET_ARCH_VARIANT := x100

# Bring-up only: ttyS0 is IRQ-driven and does not flush during a panic, so an
# oops prints nothing once the console has handed over. Keeping the polling
# earlycon registered lets console_flush_on_panic() get the backtrace out. The
# cost is every line appearing twice, both consoles driving the same UART.
# Drop this once the K3 boots without panicking.
BOARD_KERNEL_CMDLINE += keep_bootcon

# Kernel — the K3 distribution exports only k3-pico-itx.dtb
TARGET_KERNEL_USE ?= mainline
KERNEL_MODULES_PATH := device/rise/spacemit/kernel/$(TARGET_KERNEL_USE)
TARGET_PREBUILT_KERNEL := $(KERNEL_MODULES_PATH)/Image

# Kernel modules — force the CCU core first (spacemit-ccu.ko exports the symbols
# that spacemit-ccu-k3.ko links against).
#
# ufs-spacemit.ko (CONFIG_SCSI_UFS_SPACEMIT_K3) is the SpacemiT host glue for the
# ufshc@c0e00000 controller. The Pico-ITX has no eMMC — its only storage is UFS —
# so this module MUST probe before the first-stage mount, i.e. it has to live in
# the vendor_boot ramdisk and load early. The UFS/SCSI core is builtin; only this
# host glue is a module. It is force-ordered right after the clocks (the UFS
# controller's clocks come from spacemit-ccu*). Listed via $(wildcard ...) so the
# build stays green until the kernel build publishes the .ko into the ramdisk dir
# (kernel-side: enable CONFIG_SCSI_UFS_SPACEMIT_K3=m and add it to the ramdisk
# module set + initramfs/modules.load).
BOARD_VENDOR_RAMDISK_KERNEL_MODULES := $(wildcard $(KERNEL_MODULES_PATH)/ramdisk/*.ko)
BOARD_VENDOR_RAMDISK_KERNEL_MODULES_LOAD := \
    $(KERNEL_MODULES_PATH)/ramdisk/spacemit-ccu.ko \
    $(wildcard $(KERNEL_MODULES_PATH)/ramdisk/ufs-spacemit.ko) \
    $(filter-out %/spacemit-ccu.ko %/ufs-spacemit.ko,$(BOARD_VENDOR_RAMDISK_KERNEL_MODULES))

BOARD_VENDOR_KERNEL_MODULES := $(wildcard $(KERNEL_MODULES_PATH)/vendor_dlkm/*.ko)
BOARD_VENDOR_KERNEL_MODULES_LOAD := $(BOARD_VENDOR_KERNEL_MODULES)
BOARD_SYSTEM_KERNEL_MODULES := $(wildcard $(KERNEL_MODULES_PATH)/system_dlkm/*.ko)
BOARD_SYSTEM_KERNEL_MODULES_LOAD := $(BOARD_SYSTEM_KERNEL_MODULES)

# Bootconfig
BOARD_BOOTCONFIG += androidboot.hardware=k3
# Storage = UFS (the Pico-ITX has no eMMC; UFS 2.2 is the only storage).
# Path derived from k3.dtsi: the controller node is
#   soc: soc { ...; ufshc: ufshc@c0e00000 { compatible = "spacemit,k3-ufshcd"; ... } }
# i.e. a direct child of /soc. Linux
# names the platform device from the node base name -> "c0e00000.ufshc", so the
# sysfs path is /devices/platform/soc/c0e00000.ufshc and the boot_devices token
# is soc/c0e00000.ufshc. First-stage init walks this controller down to its SCSI
# block device and builds /dev/block/platform/<this>/by-name/* from the GPT.
# NEEDS-BOARD-CONFIRMATION: verify against the live sysfs node name once a board
# boots — if the kernel renames the node (e.g. ufs@c0e00000) the suffix changes.
BOARD_BOOTCONFIG += androidboot.boot_devices=soc/c0e00000.ufshc
BOARD_BOOTCONFIG += androidboot.fstab_suffix=k3
BOARD_BOOTCONFIG += androidboot.vendor.apex.com.android.hardware.keymint=com.android.hardware.keymint.rust_nonsecure
BOARD_BOOTCONFIG += androidboot.vendor.apex.com.android.hardware.gatekeeper=com.android.hardware.gatekeeper.nonsecure
BOARD_BOOTCONFIG += androidboot.selinux=permissive

# Partition sizes (match the bootloader's Android GPT layout)
BOARD_SPACEMIT_DYNAMIC_PARTITIONS_SIZE := 2411724800
BOARD_USERDATAIMAGE_PARTITION_SIZE := 10662837248

# WiFi — RTL8852BE on PCIe, mainline rtw89 driver (nl80211).
# realtek makes libwifi_hal absorb libwifi-hal-rtk, now in-tree at
# hardware/realtek/wlan/wifi_hal. Leaving this unset instead selects
# libwifi-hal-fallback, whose vendor entry points are all stubs; the framework
# still works over plain nl80211 through wificond and wpa_supplicant, so the
# fallback is a usable configuration if the vendor HAL ever gets in the way.
# Caveat worth knowing: that HAL issues Realtek private nl80211 vendor commands
# meant for their out-of-tree driver, while this board runs mainline rtw89. Base
# connectivity does not depend on them, but the vendor features they back —
# gscan, RTT, link layer stats, the ring-buffer logger — can be expected to fail
# at runtime rather than at build time.
BOARD_WLAN_DEVICE := realtek
# Install the supplicant's init service. Without this the wpa_supplicant binary
# and its VINTF manifest ship, but nothing declares the init service, so the
# AIDL interface is advertised with no process behind it and the framework fails
# with "Failed to get internal ISupplicantStaIfaceHal instance".

# Bluetooth — RTL8852B on USB (btusb + btrtl). btusb enumerates the controller
# as a standard USB HCI. The AOSP default Bluetooth HAL drives it without a
# vendor UART transport. bdroid_buildcfg.h carries the board name / class-of-dev.
BOARD_BLUETOOTH_BDROID_BUILDCFG_INCLUDE_DIR := device/rise/spacemit/k3/bluetooth

# SELinux
BOARD_VENDOR_SEPOLICY_DIRS += device/rise/spacemit/k3/sepolicy/vendor

# Recovery
TARGET_RECOVERY_FSTAB_GENRULE := gen_fstab_k3

# VINTF
DEVICE_MANIFEST_FILE := device/rise/spacemit/k3/manifest.xml
