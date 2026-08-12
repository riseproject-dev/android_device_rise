#
# Copyright (C) 2024 The Android Open Source Project
#
# SPDX-License-Identifier: Apache-2.0
#

# Virtual A/B
$(call inherit-product, $(SRC_TARGET_DIR)/product/virtual_ab_ota/launch_with_vendor_ramdisk.mk)

# Use generic ramdisk (init_boot)
$(call inherit-product, $(SRC_TARGET_DIR)/product/generic_ramdisk.mk)

# Enable updating of APEXes
$(call inherit-product, $(SRC_TARGET_DIR)/product/updatable_apex.mk)

# Enable project quotas and casefolding for emulated storage without sdcardfs
$(call inherit-product, $(SRC_TARGET_DIR)/product/emulated_storage.mk)

# Dalvik heap config
$(call inherit-product, frameworks/native/build/tablet-10in-xhdpi-2048-dalvik-heap.mk)

# GSI keys
$(call inherit-product, $(SRC_TARGET_DIR)/product/developer_gsi_keys.mk)

# Dynamic partitions
PRODUCT_USE_DYNAMIC_PARTITIONS := true

# API level. Android 17 is SDK 37, which maps to vendor API level 202604
# (build/make/core/product_config.mk: sdk-to-vendor-api-level). That level
# turns on CHECK_DEV_TYPE_VIOLATIONS and TARGET_RESTRICTS_ASHMEM_USAGE.
PRODUCT_SHIPPING_API_LEVEL := 37

# Set Vendor SPL to match platform
VENDOR_SECURITY_PATCH = $(PLATFORM_SECURITY_PATCH)
BOOT_SECURITY_PATCH = $(PLATFORM_SECURITY_PATCH)

# A/B OTA
PRODUCT_PACKAGES += \
    update_engine \
    update_engine_client \
    update_verifier \
    checkpoint_gc

# Boot control
PRODUCT_PACKAGES += \
    android.hardware.boot-service.default \
    android.hardware.boot-service.default_recovery

# Fastboot
PRODUCT_PACKAGES += \
    fastbootd \
    android.hardware.fastboot-service.example

# Health
PRODUCT_PACKAGES += \
    android.hardware.health-service.example \
    android.hardware.health-service.example_recovery

# USB HAL (BayLibre generic)
PRODUCT_PACKAGES += \
    com.android.hardware.usb.generic

# Audio HAL (BayLibre generic)
PRODUCT_PACKAGES += \
    com.android.hardware.audio.generic

PRODUCT_PACKAGES += \
    tinyplay2 \
    tinycap2 \
    tinymix2 \
    tinypcminfo2 \
    cplay

# Thermal HAL (BayLibre generic, v3)
PRODUCT_PACKAGES += \
    com.android.hardware.thermal.rs.generic.v3

# Power HAL
PRODUCT_PACKAGES += \
    com.android.hardware.power

# Android 17 moved wificond to system_ext behind RELEASE_DISABLE_WIFICOND,
# which is true for every release config, and only re-adds it through
# PRODUCT_PACKAGES_SHIPPING_API_LEVEL_33, well below ours. The SpacemiT
# boards leave BOARD_WLAN_DEVICE unset to select libwifi-hal-fallback and
# let the framework drive the device over plain nl80211 through wificond,
# so it has to come back explicitly.
PRODUCT_PACKAGES += \
    wificond

# KeyMint (software, no TEE)
PRODUCT_PACKAGES += \
    com.android.hardware.keymint.rust_nonsecure

# Gatekeeper (software, no TEE — required for FBE /data encryption)
PRODUCT_PACKAGES += \
    com.android.hardware.gatekeeper.nonsecure

# Graphics - HWComposer + Gralloc
# No legacy gralloc0 module here on purpose: Mesa reads gralloc metadata through
# its IMapper5 u_gralloc backend, which talks to mapper.minigbm directly. That
# backend only exists if Mesa is built with the 'ui' dependency available -- see
# subprojects/vndk/meson.build in the Mesa fork. Without it Mesa falls through to
# its fallback gralloc, which cannot resolve a DRM fourcc for YUV, and camera
# NV12 frames fail to import as AHardwareBuffers.
PRODUCT_PACKAGES += \
    android.hardware.composer.hwc3-service.drm \
    android.hardware.graphics.allocator-service.minigbm \
    mapper.minigbm

# Mesa3D GPU (PowerVR Vulkan + Zink OpenGL ES)
PRODUCT_PACKAGES += \
    libGLES_mesa \
    libGLESv1_CM_mesa \
    libGLESv2_mesa \
    libgallium_dri \
    vulkan.mesa \
    libgbm_mesa \
    dri_gbm \
    vulkan_mesa_icd \
    libgbm_mesa_wrapper

PRODUCT_PROPERTY_OVERRIDES += \
    ro.opengles.version=196608 \
    persist.demo.rotationlock=1

PRODUCT_PACKAGES += \
    zink_dri \
    powervr_dri \
    spacemit_dri

PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.opengles.aep.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.opengles.aep.xml \
    frameworks/native/data/etc/android.software.opengles.deqp.level-2022-03-01.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.opengles.deqp.level.xml

# Vulkan
TARGET_VULKAN_SUPPORT := true
TARGET_USES_VULKAN := true

PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.vulkan.compute-0.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.vulkan.compute.xml \
    frameworks/native/data/etc/android.hardware.vulkan.level-1.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.vulkan.level.xml \
    frameworks/native/data/etc/android.hardware.vulkan.version-1_1.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.vulkan.version.xml \
    frameworks/native/data/etc/android.software.vulkan.deqp.level-2021-03-01.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.vulkan.deqp.level.xml

PRODUCT_VENDOR_PROPERTIES += \
    ro.hardware.egl=mesa \
    ro.hardware.vulkan=mesa \
    debug.hwui.renderer=skiavk \
    debug.renderengine.backend=skiavkthreaded \
    vendor.gralloc.minigbm.backend=gbm_mesa \
    vendor.mesa.gbm_backends_path=/vendor/lib64/gbm

# DRM
PRODUCT_PACKAGES += \
    android.hardware.drm@latest-service.clearkey

# Memtrack
PRODUCT_PACKAGES += \
    android.hardware.memtrack-service.example

# Dumpstate
PRODUCT_PACKAGES += \
    android.hardware.dumpstate-service.example

# HIDL compatibility
PRODUCT_PACKAGES += \
    hwservicemanager \
    android.hidl.allocator@1.0-service

# Per-board bits (fstab / init / ueventd / GPU firmware) live in each board's
# device/spacemit/<board>/device.mk — they are SoC/board-specific (fstab mmc
# node, UDC controller, PowerVR firmware revision), NOT common.

# Permissions
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.software.ipsec_tunnels.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.ipsec_tunnels.xml \
    frameworks/native/data/etc/android.software.verified_boot.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.verified_boot.xml \
    frameworks/native/data/etc/android.software.app_widgets.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.app_widgets.xml \
    frameworks/native/data/etc/android.software.backup.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.backup.xml \
    frameworks/native/data/etc/android.software.voice_recognizers.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.voice_recognizers.xml \
    frameworks/native/data/etc/android.software.device_admin.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.device_admin.xml \
    frameworks/native/data/etc/android.software.secure_lock_screen.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.secure_lock_screen.xml \
    frameworks/native/data/etc/android.hardware.usb.accessory.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.usb.accessory.xml \
    frameworks/native/data/etc/android.hardware.usb.host.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.usb.host.xml \
    frameworks/native/data/etc/android.hardware.ethernet.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.ethernet.xml \
    frameworks/native/data/etc/android.hardware.wifi.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.wifi.xml \
    frameworks/native/data/etc/android.hardware.wifi.direct.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.wifi.direct.xml \
    device/linaro/hikey/etc/permissions/android.hardware.screen.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.screen.xml

# Audio configuration (generic). Board-specific audio_policy / codec config
# (e.g. the K1 ES8326) lives in the per-board device.mk.
PRODUCT_COPY_FILES += \
    frameworks/av/services/audiopolicy/config/audio_policy_volumes.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio_policy_volumes.xml \
    frameworks/av/services/audiopolicy/config/default_volume_tables.xml:$(TARGET_COPY_OUT_VENDOR)/etc/default_volume_tables.xml \
    frameworks/av/services/audiopolicy/config/r_submix_audio_policy_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/r_submix_audio_policy_configuration.xml \
    frameworks/av/services/audiopolicy/config/usb_audio_policy_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/usb_audio_policy_configuration.xml \
    frameworks/av/services/audiopolicy/config/a2dp_in_audio_policy_configuration_7_0.xml:$(TARGET_COPY_OUT_VENDOR)/etc/a2dp_in_audio_policy_configuration_7_0.xml \
    frameworks/av/services/audiopolicy/config/bluetooth_audio_policy_configuration_7_0.xml:$(TARGET_COPY_OUT_VENDOR)/etc/bluetooth_audio_policy_configuration_7_0.xml \
    hardware/generic/audio/mixer_controls.xml:$(TARGET_COPY_OUT_VENDOR)/etc/mixer_controls.xml

# audio_effects_config.xml is copied, not installed through
# hardware/generic/audio/audio_effects.mk. That makefile sets the soong config
# var hardware_interfaces_audio/use_default_audio_effects_config, which gates
# both our audio_effects_config.xml-generic and the AOSP audio_effects_config.xml
# in hardware/interfaces/audio/aidl/default. Setting it enables both, and they
# install to the same path, so the build fails on overriding commands.
PRODUCT_COPY_FILES += \
    hardware/generic/audio/audio_effects_config.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio_effects_config.xml

# Media codecs
PRODUCT_COPY_FILES += \
	device/spacemit/common/android.hardware.media.c2-extended-seccomp_policy:$(TARGET_COPY_OUT_VENDOR)/etc/seccomp_policy/android.hardware.media.c2-extended-seccomp_policy \
    frameworks/av/media/libstagefright/data/media_codecs_google_c2.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_codecs.xml \
    frameworks/av/media/libstagefright/data/media_codecs_google_c2_video.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_codecs_google_c2_video.xml \
    frameworks/av/media/libstagefright/data/media_codecs_google_c2_audio.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_codecs_google_c2_audio.xml \
    device/spacemit/common/media_profiles_V1_0.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_profiles_V1_0.xml

# Soong namespaces
PRODUCT_SOONG_NAMESPACES += \
    device/spacemit/k1 \
    hardware/generic/usb \
    hardware/generic/audio \
    hardware/generic/thermal

# UI
PRODUCT_PACKAGES += \
    Launcher3QuickStep

# WebView provider (riscv64). Not K1-specific — shared by all SpacemiT K1-family
# boards. Chromium ships no official riscv64 WebView prebuilt, so import the
# locally-built system_webview_apk (com.android.webview) from common/webview/
# rather than patching external/chromium-webview (which would require forking
# that AOSP repo). com.android.webview is availableByDefault in config_webview_packages.xml.
PRODUCT_PACKAGES += webview_riscv64

# SettingsProvider defaults shared by all SpacemiT boards (K1, K3):
# def_screen_off_timeout=-1 keeps the screen from ever sleeping, so the SoC never
# idles into s2idle suspend -- a bring-up board with no functional display/input
# stays reachable over adb/serial. Plus stay_on_while_plugged_in and no lockscreen.
# Board-agnostic (no density/resolution), so it lives in common, not per-board.
DEVICE_PACKAGE_OVERLAYS += device/spacemit/common/overlay


# Storage: for factory reset protection feature
PRODUCT_PROPERTY_OVERRIDES += \
	ro.frp.pst=/dev/block/by-name/frp
    