#
# Copyright (C) 2017-2021 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

TARGET_KERNEL_VERSION := 4.9

# Inherit from common msm8953-common
include device/xiaomi/msm8953-common/BoardConfigCommon.mk

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
BOARD_KERNEL_CMDLINE := console=null androidboot.console=ttyHSL0 androidboot.hardware=qcom msm_rtb.filter=0x237 ehci-hcd.park=3 lpm_levels.sleep_disabled=1 androidboot.bootdevice=7824900.sdhci earlycon=msm_hsl_uart,0x78af000 firmware_class.path=/vendor/firmware_mnt/image loop.max_part=7 buildvariant=userdebug

# Filesystem layout (nx549j is NOT A/B and uses a real recovery partition)
BOARD_BUILD_SYSTEM_ROOT_IMAGE := false
BOARD_USES_RECOVERY_AS_BOOT   := false
TARGET_NO_RECOVERY            := false

# HIDL
DEVICE_MANIFEST_FILE += $(DEVICE_PATH)/manifest.xml

# Kernel
TARGET_KERNEL_CONFIG := lineageos_nx549j_defconfig
KERNEL_MAKE_FLAGS := CROSS_COMPILE_ARM32=prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9/bin/arm-linux-androideabi-

# Partitions (placeholders; refine from stock fstab/scatter in next phase)
BOARD_BOOTIMAGE_PARTITION_SIZE     := 67108864
BOARD_RECOVERYIMAGE_PARTITION_SIZE := 67108864
BOARD_SYSTEMIMAGE_PARTITION_SIZE   := 3221225472
BOARD_USERDATAIMAGE_PARTITION_SIZE := 24159191040
BOARD_VENDORIMAGE_PARTITION_SIZE   := 268435456
BOARD_FLASH_BLOCK_SIZE             := 131072
BOARD_USES_VENDORIMAGE             := true
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
