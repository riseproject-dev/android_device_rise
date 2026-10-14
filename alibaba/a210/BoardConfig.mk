#
# Copyright (C) 2026 The Android Open Source Project
#
# SPDX-License-Identifier: Apache-2.0
#

include device/rise/common/BoardConfigCommon.mk

# Architecture
# Heterogeneous C908 (little) + C920 (big) cluster pair; neither implements
# Zvbb, so use the "a210" variant (build/soong/{cc,rust}/config/riscv64_device.go)
# instead of the riscv64 baseline.
TARGET_ARCH_VARIANT := a210

# Platform
TARGET_BOARD_PLATFORM := a210
TARGET_BOOTLOADER_BOARD_NAME := a210

$(call soong_config_set,minigbm,mesa_module,//device/rise/alibaba/a210/mesa:libgbm_mesa)

# Kernel
KERNEL_MODULES_PATH := device/rise/alibaba/kernel/mainline
TARGET_PREBUILT_KERNEL := $(KERNEL_MODULES_PATH)/Image

ifneq ($(TARGET_BUILD_VARIANT),user)
BOARD_KERNEL_CMDLINE += earlycon
BOARD_KERNEL_CMDLINE += console=ttyS4,115200
endif

# Kernel modules staged by zhihe_a210_dist; re-run its bazel dist to refresh.
BOARD_VENDOR_RAMDISK_KERNEL_MODULES := $(wildcard $(KERNEL_MODULES_PATH)/ramdisk/*.ko)

# Explicit load order (deps aren't alphabetical):
# clk core -> reset -> pinctrl/power domain -> gpio -> eMMC/SD -> watchdog.
BOARD_VENDOR_RAMDISK_KERNEL_MODULES_LOAD := \
    $(KERNEL_MODULES_PATH)/ramdisk/zhihe-clk-core.ko \
    $(KERNEL_MODULES_PATH)/ramdisk/clk-a210.ko \
    $(KERNEL_MODULES_PATH)/ramdisk/reset-a210.ko \
    $(KERNEL_MODULES_PATH)/ramdisk/pinctrl-a210.ko \
    $(KERNEL_MODULES_PATH)/ramdisk/a210-pd.ko \
    $(KERNEL_MODULES_PATH)/ramdisk/gpio-dwapb.ko \
    $(KERNEL_MODULES_PATH)/ramdisk/cqhci.ko \
    $(KERNEL_MODULES_PATH)/ramdisk/sdhci-of-dwcmshc.ko \
    $(KERNEL_MODULES_PATH)/ramdisk/dw_wdt.ko

# Vendor DLKM: loaded after rootfs mount. PowerVR GPU stack listed first,
# in dependency order (drm_exec -> drm_gpuvm, gpu-sched -> powervr).
BOARD_VENDOR_KERNEL_MODULES := $(wildcard $(KERNEL_MODULES_PATH)/vendor_dlkm/*.ko)
BOARD_VENDOR_KERNEL_MODULES_LOAD := \
    $(KERNEL_MODULES_PATH)/vendor_dlkm/drm_exec.ko \
    $(KERNEL_MODULES_PATH)/vendor_dlkm/drm_gpuvm.ko \
    $(KERNEL_MODULES_PATH)/vendor_dlkm/gpu-sched.ko \
    $(KERNEL_MODULES_PATH)/vendor_dlkm/powervr.ko \
    $(KERNEL_MODULES_PATH)/vendor_dlkm/i2c-designware-core.ko \
    $(KERNEL_MODULES_PATH)/vendor_dlkm/i2c-designware-platform.ko \
    $(KERNEL_MODULES_PATH)/vendor_dlkm/gpio-pca953x.ko \
    $(KERNEL_MODULES_PATH)/vendor_dlkm/pwrseq_simple.ko \
    $(KERNEL_MODULES_PATH)/vendor_dlkm/rtw88_core.ko \
    $(KERNEL_MODULES_PATH)/vendor_dlkm/rtw88_sdio.ko \
    $(KERNEL_MODULES_PATH)/vendor_dlkm/rtw88_8822c.ko \
    $(KERNEL_MODULES_PATH)/vendor_dlkm/rtw88_8822cs.ko \
    $(KERNEL_MODULES_PATH)/vendor_dlkm/phy-zhihe-snps-c10phy.ko \
    $(KERNEL_MODULES_PATH)/vendor_dlkm/phy-zhihe-snps-usb2.ko \
    $(KERNEL_MODULES_PATH)/vendor_dlkm/dwc2.ko
# HDMI/display pipeline modules
BOARD_VENDOR_KERNEL_MODULES_LOAD += \
    $(KERNEL_MODULES_PATH)/vendor_dlkm/drm_display_helper.ko \
    $(KERNEL_MODULES_PATH)/vendor_dlkm/drm_dma_helper.ko \
    $(KERNEL_MODULES_PATH)/vendor_dlkm/dw-hdmi.ko \
    $(KERNEL_MODULES_PATH)/vendor_dlkm/display-connector.ko \
    $(KERNEL_MODULES_PATH)/vendor_dlkm/th1520-dw-hdmi.ko \
    $(KERNEL_MODULES_PATH)/vendor_dlkm/verisilicon-dc.ko
# Audio modules
BOARD_VENDOR_KERNEL_MODULES_LOAD += \
    $(KERNEL_MODULES_PATH)/vendor_dlkm/dw-axi-dmac-platform.ko \
    $(KERNEL_MODULES_PATH)/vendor_dlkm/snd-soc-simple-card-utils.ko \
    $(KERNEL_MODULES_PATH)/vendor_dlkm/snd-soc-zhihe-pcm.ko \
    $(KERNEL_MODULES_PATH)/vendor_dlkm/snd-soc-zhihe-i2s.ko \
    $(KERNEL_MODULES_PATH)/vendor_dlkm/snd-soc-es8156.ko \
    $(KERNEL_MODULES_PATH)/vendor_dlkm/snd-soc-es7210.ko \
    $(KERNEL_MODULES_PATH)/vendor_dlkm/snd-soc-audio-graph-card2.ko

BOARD_SYSTEM_KERNEL_MODULES := $(wildcard $(KERNEL_MODULES_PATH)/system_dlkm/*.ko)
BOARD_SYSTEM_KERNEL_MODULES_LOAD := $(BOARD_SYSTEM_KERNEL_MODULES)

# Boot image
BOARD_KERNEL_BASE := 0x80000000
BOARD_MKBOOTIMG_ARGS := --header_version $(BOARD_BOOT_HEADER_VERSION) --pagesize $(BOARD_KERNEL_PAGESIZE) --kernel_offset 0x200000 --ramdisk_offset 0x04000000
BOARD_MKBOOTIMG_INIT_ARGS := --header_version $(BOARD_INIT_BOOT_HEADER_VERSION)

# Bootconfig
# Serialized (was true): parallel vendor_dlkm insmod intermittently
# freezes boot now that AON regulators + GPU/DRM modules race for it.
BOARD_BOOTCONFIG += androidboot.load_modules_parallel=false
BOARD_BOOTCONFIG += androidboot.logcat.buffersize=4M
BOARD_BOOTCONFIG += androidboot.hardware=a210
BOARD_BOOTCONFIG += androidboot.boot_devices=soc/500000.sdhci
BOARD_BOOTCONFIG += androidboot.fstab_suffix=a210
BOARD_BOOTCONFIG += androidboot.vendor.apex.com.android.hardware.keymint=com.android.hardware.keymint.rust_nonsecure
BOARD_BOOTCONFIG += androidboot.vendor.apex.com.android.hardware.gatekeeper=com.android.hardware.gatekeeper.nonsecure
BOARD_BOOTCONFIG += androidboot.selinux=permissive

# Partition sizes derived from the prebuilt GPT via sgdisk -p (dtbo unused for now).
# BOARD_DTBOIMG_PARTITION_SIZE := 8388608
BOARD_USERDATAIMAGE_PARTITION_SIZE := 57411600896

# Dynamic partitions
BOARD_SUPER_PARTITION_GROUPS := a210_dynamic_partitions
BOARD_A210_DYNAMIC_PARTITIONS_PARTITION_LIST := system vendor vendor_dlkm system_dlkm
BOARD_A210_DYNAMIC_PARTITIONS_SIZE := 2411724800

# Recovery
TARGET_RECOVERY_FSTAB_GENRULE := gen_fstab_a210

# Bluetooth
BOARD_BLUETOOTH_BDROID_BUILDCFG_INCLUDE_DIR := device/rise/alibaba/a210/bluetooth

# SELinux
BOARD_SEPOLICY_DIRS += device/rise/alibaba/a210/sepolicy/vendor

# VINTF
DEVICE_MANIFEST_FILE := device/rise/alibaba/a210/manifest.xml
