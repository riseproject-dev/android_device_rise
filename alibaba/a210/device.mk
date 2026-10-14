#
# Copyright (C) 2026 The Android Open Source Project
#
# SPDX-License-Identifier: Apache-2.0
#

$(call inherit-product, device/rise/common/device-common.mk)

# Kernel
LOCAL_KERNEL := device/rise/alibaba/kernel/mainline/Image
PRODUCT_COPY_FILES += $(LOCAL_KERNEL):kernel

# ALSA PCM device of the primary output: 0 = headset jack, 1 = HDMI.
PRODUCT_VENDOR_PROPERTIES += \
    ro.vendor.audio.primary.card_name=A210EVBAudio \
    ro.vendor.audio.primary.device=1 \
    ro.vendor.audio.mixer.config=/vendor/etc/mixer_controls_a210.xml

# Installed under a board specific name and selected through
# ro.vendor.audio.mixer.config: device-common.mk already copies the generic
# file to etc/mixer_controls.xml, and PRODUCT_COPY_FILES keeps the first entry
# for a destination.
PRODUCT_COPY_FILES += \
    device/rise/alibaba/a210/audio/mixer_controls.xml:$(TARGET_COPY_OUT_VENDOR)/etc/mixer_controls_a210.xml \
    device/rise/alibaba/a210/audio/audio_policy_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio_policy_configuration.xml \
    device/rise/alibaba/a210/audio/primary_audio_policy_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/primary_audio_policy_configuration.xml

PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.audio.output.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.audio.output.xml \
    frameworks/native/data/etc/android.hardware.audio.low_latency.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.audio.low_latency.xml

# ALSA debug tools
PRODUCT_PACKAGES_DEBUG += \
    tinyplay \
    tinycap \
    tinymix \
    tinypcminfo

PRODUCT_VENDOR_PROPERTIES += ro.hardware.gralloc=minigbm

PRODUCT_PROPERTY_OVERRIDES += \
    vendor.hwc.drm.internal_display_names=HDMI-A-1 \
    ro.vendor.hwc.use_overlay_planes=true

# AON co-processor firmware must be shipped in the vendor ramdisk
PRODUCT_COPY_FILES += device/rise/alibaba/a210/firmware/a210-aon.bin:$(TARGET_COPY_OUT_VENDOR_RAMDISK)/lib/firmware/a210-aon.bin

# GPU firmware: same rogue_36.52.104.182_v1.fw as T-Head TH1520 (same
# GPU core/revision).
PRODUCT_COPY_FILES += device/rise/alibaba/a210/firmware/powervr/rogue_36.52.104.182_v1.fw:$(TARGET_COPY_OUT_VENDOR)/firmware/powervr/rogue_36.52.104.182_v1.fw

PRODUCT_SOONG_NAMESPACES += device/rise/alibaba/a210/mesa

PRODUCT_PACKAGES += verisilicon_dri

# Zink only offers OpenGL ES 2.0 on top of Mesa's PowerVR Vulkan
# implementation, which lacks the VK_EXT_transform_feedback that ES 3.0
# needs. Declaring more makes apps and CTS ask for contexts EGL cannot create.

# Vulkan features, as Mesa's PowerVR driver exposes them on the BXM-4-64 and as
# CTS recomputes them from vkjson: API 1.2, hardware level 0 (no geometry or
# tessellation shaders) and no vulkan.compute (no variablePointers).
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.vulkan.level-0.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.vulkan.level.xml \
    device/rise/alibaba/a210/config/android.hardware.vulkan.version-1_2.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.vulkan.version.xml \
    frameworks/native/data/etc/android.software.vulkan.deqp.level-2021-03-01.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.vulkan.deqp.level.xml

# WiFi
PRODUCT_PACKAGES += linux_firmware_rtw88-rtw8822c

# Wifi P2P/Supplicant configs
PRODUCT_COPY_FILES += device/rise/alibaba/a210/wifi/wpa_supplicant.conf:$(TARGET_COPY_OUT_VENDOR)/etc/wifi/wpa_supplicant.conf

# Bluetooth
PRODUCT_PACKAGES += rtl8822cs_bt_firmware

# External USB (UVC) camera
PRODUCT_PACKAGES += android.hardware.camera.provider-V1-external-service

PRODUCT_COPY_FILES += \
    device/rise/alibaba/a210/external_camera_config.xml:$(TARGET_COPY_OUT_VENDOR)/etc/external_camera_config.xml \
    frameworks/native/data/etc/android.hardware.camera.external.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.camera.external.xml

# Bluetooth profiles
PRODUCT_PRODUCT_PROPERTIES += \
    bluetooth.profile.gatt.enabled?=true \
    bluetooth.profile.a2dp.source.enabled?=true \
    bluetooth.profile.avrcp.target.enabled?=true \
    bluetooth.profile.hfp.ag.enabled?=true \
    bluetooth.profile.hid.host.enabled?=true \
    bluetooth.profile.hid.device.enabled?=true \
    bluetooth.profile.opp.enabled?=true \
    bluetooth.profile.pan.nap.enabled?=true \
    bluetooth.profile.pan.panu.enabled?=true \
    bluetooth.profile.pbap.server.enabled?=true \
    bluetooth.profile.map.server.enabled?=true \
    bluetooth.profile.sap.server.enabled?=true \
    bluetooth.profile.bap.broadcast.assist.enabled=false \
    bluetooth.profile.bap.unicast.client.enabled=false \
    bluetooth.profile.bas.client.enabled=false \
    bluetooth.profile.ccp.server.enabled=false \
    bluetooth.profile.csip.set_coordinator.enabled=false \
    bluetooth.profile.hap.client.enabled=false \
    bluetooth.profile.mcp.server.enabled=false \
    bluetooth.profile.vcp.controller.enabled=false \
    bluetooth.profile.asha.central.enabled=false

# Fstab
PRODUCT_PACKAGES += \
    fstab.a210 \
    fstab.a210.vendor_ramdisk

# Init / ueventd
PRODUCT_COPY_FILES += \
    device/rise/alibaba/a210/init.a210.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/hw/init.a210.rc \
    device/rise/alibaba/a210/init.a210.usb.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/init.a210.usb.rc \
    device/rise/alibaba/a210/ueventd.a210.rc:$(TARGET_COPY_OUT_VENDOR)/etc/ueventd.rc
