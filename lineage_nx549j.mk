#
# Copyright (C) 2017-2021 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

# Inherit from those products. Most specific first.
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)

# Inherit some common LineageOS stuff.
$(call inherit-product, vendor/lineage/config/common_full_phone.mk)

# Inherit from nx549j device
$(call inherit-product, device/nubia/nx549j/device.mk)

# Device identifier. This must come after all inclusions
PRODUCT_DEVICE := nx549j
PRODUCT_NAME := lineage_nx549j
BOARD_VENDOR := nubia
PRODUCT_BRAND := nubia
PRODUCT_MODEL := Nubia Z11 mini S
PRODUCT_MANUFACTURER := nubia
TARGET_VENDOR := nubia

PRODUCT_GMS_CLIENTID_BASE := android-nubia

PRODUCT_BUILD_PROP_OVERRIDES += \
    PRIVATE_BUILD_DESC="nx549j-user 7.1.1 NMF26X 1.0 release-keys"

# Set BUILD_FINGERPRINT variable to be picked up by both system and vendor build.prop
BUILD_FINGERPRINT := "nubia/nx549j/nx549j:7.1.1/NMF26X/1.0:user/release-keys"
