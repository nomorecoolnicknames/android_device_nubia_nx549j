# Audio
PRODUCT_PROPERTY_OVERRIDES += \
persist.vendor.audio.fluence.speaker=true \
persist.vendor.audio.fluence.voicecall=true \
persist.vendor.audio.fluence.voicerec=false \
ro.vendor.audio.sdk.fluencetype=fluence

# Bring-up diagnostics: keep ADB unauthenticated and enabled for local boot loops.
PRODUCT_SYSTEM_DEFAULT_PROPERTIES += \
ro.secure=0 \
ro.adb.secure=0 \
persist.sys.usb.config=adb

# Camera
PRODUCT_PROPERTY_OVERRIDES += \
vendor.camera.aux.packagelist=org.codeaurora.snapcam,com.android.camera,org.lineageos.snap \
persist.camera.dual.camera=0
