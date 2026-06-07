#
# Copyright (C) 2017-2021 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

TARGET_KERNEL_VERSION := 4.9

# Inherit from common msm8953-common
include device/nubia/msm8953-common/BoardConfigCommon.mk

DEVICE_PATH := device/nubia/nx549j

# Bootloader / vendor identity
BOARD_VENDOR := nubia

# Display (5.2" 1080x1920 IPS, ~424dpi nominal -> use 420 bucket)
TARGET_SCREEN_DENSITY := 420

# Kernel boot image layout (matches preserved nx549j boot.img header)
BOARD_KERNEL_BASE        := 0x80000000
BOARD_KERNEL_PAGESIZE    := 2048
BOARD_KERNEL_TAGS_OFFSET := 0x00000100
BOARD_RAMDISK_OFFSET     := 0x01000000
BOARD_KERNEL_OFFSET      := 0x00008000
BOARD_MKBOOTIMG_ARGS := --ramdisk_offset $(BOARD_RAMDISK_OFFSET) --tags_offset $(BOARD_KERNEL_TAGS_OFFSET) --kernel_offset $(BOARD_KERNEL_OFFSET)

# Cmdline (lifted from working crDroid nx549j boot.img)
BOARD_KERNEL_CMDLINE := androidboot.hardware=qcom msm_rtb.filter=0x237 ehci-hcd.park=3 lpm_levels.sleep_disabled=1 androidboot.bootdevice=7824900.sdhci earlycon=msm_serial_dm,0x78af000,115200n8 loop.max_part=16 androidboot.usbconfigfs=true androidboot.selinux=permissive
BOARD_KERNEL_CMDLINE += frgmark.raw_wdt=1 frgmark.recovery_timeout_sec=120 frgmark.bcb_misc_devt=179:28 initcall_debug

# Filesystem layout (nx549j is NOT A/B and uses a real recovery partition)
BOARD_BUILD_SYSTEM_ROOT_IMAGE := false
BOARD_USES_RECOVERY_AS_BOOT   := false
BOARD_SKIP_RECOVERY_FROM_BOOT := true
TARGET_NO_RECOVERY            := false

# HIDL
DEVICE_MANIFEST_FILE += $(DEVICE_PATH)/manifest.xml

# Kernel
TARGET_KERNEL_CONFIG := lineageos_nx549j_defconfig
KERNEL_MAKE_FLAGS := CROSS_COMPILE_ARM32=prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9/bin/arm-linux-androideabi-
TARGET_KERNEL_ADDITIONAL_FLAGS += CPATH="/usr/include/node:/usr/include/node/openssl/archs/linux-x86_64/no-asm/include:/usr/include:/usr/include/x86_64-linux-gnu"
TARGET_KERNEL_ADDITIONAL_FLAGS += HOSTCFLAGS="-I/usr/include/node -I/usr/include/node/openssl/archs/linux-x86_64/no-asm/include -fuse-ld=lld"
TARGET_KERNEL_ADDITIONAL_FLAGS += HOSTLOADLIBES_sign-file=/usr/lib/x86_64-linux-gnu/libcrypto.so.3 HOSTLOADLIBES_extract-cert=/usr/lib/x86_64-linux-gnu/libcrypto.so.3

# Partitions (placeholders; refine from stock fstab/scatter in next phase)
BOARD_BOOTIMAGE_PARTITION_SIZE     := 67108864
BOARD_RECOVERYIMAGE_PARTITION_SIZE := 67108864
BOARD_SYSTEMIMAGE_PARTITION_SIZE   := 4294967296
BOARD_USERDATAIMAGE_PARTITION_SIZE := 24159191040
BOARD_FLASH_BLOCK_SIZE             := 131072
BOARD_VENDORIMAGE_PARTITION_SIZE   := 300384256
BOARD_VENDORIMAGE_FILE_SYSTEM_TYPE := ext4
TARGET_COPY_OUT_VENDOR             := vendor

# Power
TARGET_TAP_TO_WAKE_NODE := "/proc/touchpanel/enable_dt2w"

# RIL
ENABLE_VENDOR_RIL_SERVICE := true

# Security Patch Level
VENDOR_SECURITY_PATCH := 2020-05-05

# Inherit the proprietary files
include vendor/nubia/nx549j/BoardConfigVendor.mk

BOARD_CACHEIMAGE_PARTITION_SIZE := 268435456
BOARD_CACHEIMAGE_FILE_SYSTEM_TYPE := ext4

TARGET_OTA_ASSERT_DEVICE := nx549j,NX549J

# HighwayStar vendor blobs are Android 9 ABI — skip strict ELF check for Android 11
BUILD_BROKEN_PREBUILT_ELF_FILES := true
BUILD_BROKEN_ELF_PREBUILT_PRODUCT_COPY_FILES := true
