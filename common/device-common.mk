#
# Copyright (C) 2024 The Android Open Source Project
#
# SPDX-License-Identifier: Apache-2.0
#

$(call inherit-product, $(SRC_TARGET_DIR)/product/virtual_ab_ota/launch_with_vendor_ramdisk.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/generic_ramdisk.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/updatable_apex.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/emulated_storage.mk)
$(call inherit-product, frameworks/native/build/tablet-10in-xhdpi-2048-dalvik-heap.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/developer_gsi_keys.mk)

PRODUCT_USE_DYNAMIC_PARTITIONS := true
PRODUCT_SHIPPING_API_LEVEL := 37
VENDOR_SECURITY_PATCH = $(PLATFORM_SECURITY_PATCH)
BOOT_SECURITY_PATCH = $(PLATFORM_SECURITY_PATCH)
TARGET_VULKAN_SUPPORT := true
TARGET_USES_VULKAN := true

PRODUCT_PACKAGES += \
    update_engine \
    update_engine_client \
    update_verifier \
    checkpoint_gc \
    android.hardware.boot-service.default \
    android.hardware.boot-service.default_recovery \
    fastbootd \
    android.hardware.fastboot-service.example \
    android.hardware.health-service.example \
    android.hardware.health-service.example_recovery \
    com.android.hardware.usb.generic \
    com.android.hardware.audio.generic \
    com.android.hardware.thermal.rs.generic.v3 \
    com.android.hardware.power \
    wificond \
    com.android.hardware.keymint.rust_nonsecure \
    com.android.hardware.gatekeeper.nonsecure \
    android.hardware.composer.hwc3-service.drm \
    android.hardware.graphics.allocator-service.minigbm \
    mapper.minigbm \
    libGLES_mesa \
    libGLESv1_CM_mesa \
    libGLESv2_mesa \
    libgallium_dri \
    vulkan.mesa \
    libgbm_mesa \
    dri_gbm \
    vulkan_mesa_icd \
    libgbm_mesa_wrapper \
    zink_dri \
    powervr_dri \
    android.hardware.memtrack-service.example \
    android.hardware.dumpstate-service.example \
    hwservicemanager \
    android.hidl.allocator@1.0-service \
    webview_riscv64 \
    Luanti \
    modetest \
    wpa_supplicant \
    wpa_cli \
    android.hardware.bluetooth-service.default

PRODUCT_PROPERTY_OVERRIDES += \
    ro.opengles.version=131072 \
    persist.demo.rotationlock=1 \
    ro.frp.pst=/dev/block/by-name/frp \
    ro.sf.lcd_density=240 \
    sys.usb.configfs=1 \
    ro.surface_flinger.protected_contents=false \
    config.disable_renderscript=true \
    media.c2.hal.selection=aidl \
    debug.stagefright.c2inputsurface=-1

PRODUCT_VENDOR_PROPERTIES += \
    ro.hardware.egl=mesa \
    ro.hardware.vulkan=mesa \
    debug.hwui.renderer=skiavk \
    debug.renderengine.backend=skiavkthreaded \
    vendor.gralloc.minigbm.backend=gbm_mesa \
    vendor.mesa.gbm_backends_path=/vendor/lib64/gbm \
    wifi.interface=wlan0

PRODUCT_SOONG_NAMESPACES += \
    hardware/generic/audio \
    hardware/generic/thermal \
    external/minigbm/gbm_mesa_driver

PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.software.opengles.deqp.level-2022-03-01.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.opengles.deqp.level.xml \
    frameworks/native/data/etc/android.software.ipsec_tunnels.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.ipsec_tunnels.xml \
    frameworks/native/data/etc/android.software.verified_boot.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.verified_boot.xml \
    frameworks/native/data/etc/android.software.app_widgets.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.app_widgets.xml \
    frameworks/native/data/etc/android.software.backup.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.backup.xml \
    frameworks/native/data/etc/android.software.voice_recognizers.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.voice_recognizers.xml \
    frameworks/native/data/etc/android.software.device_admin.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.device_admin.xml \
    frameworks/native/data/etc/android.software.secure_lock_screen.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.secure_lock_screen.xml \
    frameworks/native/data/etc/android.hardware.usb.host.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.usb.host.xml \
    frameworks/native/data/etc/android.hardware.wifi.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.wifi.xml \
    frameworks/native/data/etc/android.hardware.wifi.direct.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.wifi.direct.xml \
    device/linaro/hikey/etc/permissions/android.hardware.screen.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.screen.xml \
    frameworks/av/services/audiopolicy/config/audio_policy_volumes.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio_policy_volumes.xml \
    frameworks/av/services/audiopolicy/config/default_volume_tables.xml:$(TARGET_COPY_OUT_VENDOR)/etc/default_volume_tables.xml \
    frameworks/av/services/audiopolicy/config/r_submix_audio_policy_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/r_submix_audio_policy_configuration.xml \
    frameworks/av/services/audiopolicy/config/bluetooth_audio_policy_configuration_7_0.xml:$(TARGET_COPY_OUT_VENDOR)/etc/bluetooth_audio_policy_configuration_7_0.xml \
    hardware/generic/audio/mixer_controls.xml:$(TARGET_COPY_OUT_VENDOR)/etc/mixer_controls.xml \
    hardware/generic/audio/audio_effects_config.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio_effects_config.xml \
    frameworks/av/media/libstagefright/data/media_codecs_google_c2.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_codecs.xml \
    frameworks/av/media/libstagefright/data/media_codecs_google_c2_video.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_codecs_google_c2_video.xml \
    frameworks/av/media/libstagefright/data/media_codecs_google_c2_audio.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_codecs_google_c2_audio.xml \
    device/rise/common/media_profiles_V1_0.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_profiles_V1_0.xml \
    device/rise/common/seccomp_policy/mediaswcodec.policy:$(TARGET_COPY_OUT_VENDOR)/etc/seccomp_policy/mediaswcodec.policy \
    device/rise/common/wifi/wpa_supplicant_overlay.conf:$(TARGET_COPY_OUT_VENDOR)/etc/wifi/wpa_supplicant_overlay.conf \
    device/rise/common/wifi/p2p_supplicant_overlay.conf:$(TARGET_COPY_OUT_VENDOR)/etc/wifi/p2p_supplicant_overlay.conf \
    frameworks/native/data/etc/android.hardware.bluetooth.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.bluetooth.xml \
    frameworks/native/data/etc/android.hardware.bluetooth_le.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.bluetooth_le.xml

DEVICE_PACKAGE_OVERLAYS += device/rise/common/overlay
