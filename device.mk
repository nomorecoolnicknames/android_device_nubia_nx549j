#
# Copyright (C) 2017-2021 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

# Inherit from msm8953-common
$(call inherit-product, device/nubia/msm8953-common/msm8953.mk)

$(call inherit-product, $(SRC_TARGET_DIR)/product/product_launched_with_n_mr1.mk)

# Overlay
DEVICE_PACKAGE_OVERLAYS += $(LOCAL_PATH)/overlay
DEVICE_PACKAGE_OVERLAYS += $(LOCAL_PATH)/overlay-lineage

# Boot animation
TARGET_SCREEN_HEIGHT := 1920
TARGET_SCREEN_WIDTH := 1080

# Boot HAL
# Android 11 vold checkpoint setup calls IBootControl even on this single-slot
# device. The msm8953 bootctrl HAL reports one slot and keeps vold from waiting
# forever for a missing android.hardware.boot@1.0/default service.
PRODUCT_PACKAGES += \
    android.hardware.boot@1.0-impl \
    android.hardware.boot@1.0-service \
    bootctrl.msm8953

# Audio configuration
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/audio/audio_platform_info.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio_platform_info.xml \
    $(LOCAL_PATH)/audio/mixer_paths_mtp.xml:$(TARGET_COPY_OUT_VENDOR)/etc/mixer_paths_mtp.xml

# Camera
PRODUCT_PACKAGES += \
    camera.msm8953 \
    libmm-qcamera

# Fingerprint — Goodix GF3208, WORKING (enroll + unlock confirmed 2026-07-16).
# The Goodix stack is Android-9 blobs (gx_fpd daemon + fps_hal wrapper +
# libfp_client) running on this Android-11 vendor image. It is shipped as
# prebuilts (fingerprint-a9.mk) rather than built from AOSP source, plus an
# LD_PRELOAD binder-compat shim (libbindershim.so) that bridges the A9<->A11
# binder wire-format divergences (interface token, strong-binder stability, and
# the servicemanager writeNoException reply prefix). Binary patches: BUG A in
# gxfingerprint.default.so (NULL cmd=2 buffer) and BUG B in gx_fpd (a premature
# decStrong that tore down FpService). Init wiring (LD_PRELOAD on gx_fpd/fps_hal
# and the goodix.fp.service.ready cold-boot gate) is in init.nx549j.rc /
# init.goodix.sh / the fps_hal .rc. Full analysis: BRINGUP_STATE.md 2026-07-16.
# Do NOT re-add the AOSP-built service module here — it would collide with the
# prebuilt A9 binary at the same vendor path.
$(call inherit-product, vendor/nubia/msm8953-common/fingerprint-a9.mk)

PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.fingerprint.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.fingerprint.xml

# NFC
PRODUCT_PACKAGES += \
    com.android.nfc_extras \
    NfcNci \
    Tag \
    android.hardware.nfc@1.0-impl-bcm \
    android.hardware.nfc@1.0-service

PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/configs/nfc/libnfc-brcm.conf:system/etc/libnfc-brcm.conf \
    $(LOCAL_PATH)/configs/nfc/libnfc-brcm-20797b00.conf:system/etc/libnfc-brcm-20797b00.conf \
    $(LOCAL_PATH)/configs/nfc/libnfc-brcm.conf:$(TARGET_COPY_OUT_VENDOR)/etc/libnfc-nci.conf \
    $(LOCAL_PATH)/configs/nfc/libnfc-brcm-20797b00.conf:$(TARGET_COPY_OUT_VENDOR)/etc/libnfc-nci-20797b00.conf \
    $(LOCAL_PATH)/configs/nfc/nfcee_access.xml:system/etc/nfcee_access.xml \
    frameworks/native/data/etc/android.hardware.nfc.hce.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.nfc.hce.xml \
    frameworks/native/data/etc/android.hardware.nfc.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.nfc.xml \
    frameworks/native/data/etc/com.android.nfc_extras.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/com.android.nfc_extras.xml

# Gatekeeper
PRODUCT_PACKAGES += \
    android.hardware.gatekeeper@1.0-impl \
    android.hardware.gatekeeper@1.0-service

# Keymaster
PRODUCT_PACKAGES += \
    android.hardware.keymaster@3.0-impl \
    android.hardware.keymaster@3.0-service

# Properties
-include device/nubia/nx549j/prop.mk

# Ramdisk
PRODUCT_PACKAGES += \
    init.goodix.sh \
    init.recovery.qcom.rc \
    init.recovery.qcom.usb.rc \
    init.nx549j.rc

# Sensors
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/configs/sensors/sensor_def_qcomdev.conf:$(TARGET_COPY_OUT_VENDOR)/etc/sensors/sensor_def_qcomdev.conf \
    $(LOCAL_PATH)/configs/sensors/sensor_def_qcomdev.conf:system/etc/sensors/sensor_def_qcomdev.conf \
    device/nubia/msm8953-common/sensors/hals.conf:$(TARGET_COPY_OUT_VENDOR)/etc/sensors/hals.conf \
    device/nubia/msm8953-common/sensors/hals.conf:system/etc/sensors/hals.conf

# Soong namespaces
PRODUCT_SOONG_NAMESPACES += \
    $(LOCAL_PATH)

# Update engine
PRODUCT_PACKAGES += \
    update_engine \
    update_engine_sideload \
    update_verifier

PRODUCT_PACKAGES_DEBUG += \
    update_engine_client

# Verity disabled (vendor.img oversize w/ FEC on 256MB oem partition)

# Full-VNDK bring-up shims (2026-07-18). Custom libs (NOT stock-extracted) that
# let HALs load under the strict isolated vendor linker namespace once
# ro.vndk.lite was removed. Bytes live in vendor/nubia/nx549j/proprietary; no
# generated-Android.mk entry, so they must be installed here or a clean
# vendorimage loses them. arch is fixed by the dest path (device has 32-only /
# 64-only), so no multilib guard is needed. See VNDK_FULL_MIGRATION_20260717.md.
#   libgui_shim_cam.so (32): resolves camera HAL libgui.so symbol under strict NS
#   libsched_shim.so   (64): set_sched_policy shim (GPS/qti_gnss HAL) under strict NS
# The 3rd VNDK shim (com.qualcomm.qti.wifidisplayhal@1.0.so) is already installed
# via msm8953-common-vendor.mk; the two patched stock blobs (libgps.utils.so 64,
# libmmcamera2_stats_modules.so) are patched in-place in the common proprietary tree.
PRODUCT_COPY_FILES += \
    vendor/nubia/nx549j/proprietary/vendor/lib/libgui_shim_cam.so:$(TARGET_COPY_OUT_VENDOR)/lib/libgui_shim_cam.so \
    vendor/nubia/nx549j/proprietary/vendor/lib64/libsched_shim.so:$(TARGET_COPY_OUT_VENDOR)/lib64/libsched_shim.so


# NX549J: expose the Hexagon/ADSP RPC library to apps. libadsprpc.so ships in
# /vendor/lib*, but without a vendor public.libraries.txt an app cannot dlopen
# it, so GCam's Halide HDR+ backend fails with
# "halide: Failed to load libcdsprpc.so or libadsprpc.so" and never brings up
# its Hexagon environment. (libcdsprpc.so is listed for completeness; MSM8953
# has no CDSP and the entry is simply unused.)
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/configs/public.libraries.txt:$(TARGET_COPY_OUT_VENDOR)/etc/public.libraries.txt

# Inherit the proprietary files
$(call inherit-product, vendor/nubia/nx549j/nx549j-vendor.mk)
