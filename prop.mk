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

# Display: the rotation black-flicker workaround that used to live here
# (debug.sf.disable_backpressure=1 / debug.sf.latch_unsignaled=0) is gone, and so
# is the theory behind it. The flicker was never the ROTATE animation's black
# corners on a cmd-mode panel: it was the gralloc1 ALLOCATE_BUFFER op mismatch
# (hwcomposer emitted 17, gralloc only handled 15, so the allocation silently
# returned null). The rotation animation asks the HWC allocator for its
# screenshot layer, that allocation failed, and the black frames were the result
# -- the same bug that greyed out the UI and the camera preview. Fixed at the
# root in hardware/qcom-caf/msm8953/display commit e6b3da0 (op 17 -> 15); with
# that in place the stock ROTATE animation is smooth and flicker free
# (user-confirmed 2026-07-17), so these knobs are unnecessary. See BRINGUP_STATE.md
# "2026-07-17 - СЕРОЕ РЕШЕНО ОКОНЧАТЕЛЬНО".

NX549J_ENABLE_CAMERA2_FULL ?= false
# RAW enabled 2026-07-18: the imx318/imx258 are Bayer sensors (colorFilter=RGGB,
# full DNG matrices advertised) and the HAL already carries the complete RAW path
# (RAW cap enum, RAW16/RAW_OPAQUE stream configs, stall durations). GCam's HDR+
# engine (HdrPlusModule) only enrolls cameras whose REQUEST_AVAILABLE_CAPABILITIES
# contains RAW(3) -> without it Gcam_Create returns 0 and GCam NPE-crashes at init.
# Flipping this to true advertises RAW and lets GCam launch. Additive/safe: apps
# that never request a RAW stream are unaffected. Runtime-killable: persist.camera.hal3.raw 0.
NX549J_ENABLE_CAMERA2_RAW ?= true
NX549J_ENABLE_CAMERA2_HFR ?= false

NX549J_CAMERA2_FULL_PROP := 0
ifeq ($(NX549J_ENABLE_CAMERA2_FULL),true)
NX549J_CAMERA2_FULL_PROP := 1
endif

NX549J_CAMERA2_RAW_PROP := 0
ifeq ($(NX549J_ENABLE_CAMERA2_RAW),true)
NX549J_CAMERA2_RAW_PROP := 1
endif

NX549J_CAMERA2_HFR_PROP := 0
ifeq ($(NX549J_ENABLE_CAMERA2_HFR),true)
NX549J_CAMERA2_HFR_PROP := 1
endif

# Camera
PRODUCT_PROPERTY_OVERRIDES += \
vendor.camera.aux.packagelist=org.codeaurora.snapcam,com.android.camera,org.lineageos.snap \
persist.camera.hal3.full=$(NX549J_CAMERA2_FULL_PROP) \
	persist.camera.hal3.raw=$(NX549J_CAMERA2_RAW_PROP) \
	persist.camera.hal3.hfr=$(NX549J_CAMERA2_HFR_PROP) \
	persist.camera.force_bringup_snapshot_bufs=3 \
	persist.camera.nx549j.capture_blob_order=0 \
	persist.camera.nx549j.capture_snapshot_continuous=0 \
	persist.camera.nx549j.capture_snapshot_no_dynalloc=1 \
	persist.camera.nx549j.preview_snapshot_stream=0 \
	persist.camera.nx549j.preview_snapshot_bundle_metadata=0 \
	persist.camera.nx549j.preview_snapshot_unbundle=0 \
	persist.camera.nx549j.capture_snapshot_only_superbuf=1 \
	persist.camera.nx549j.capture_superbuf_snapshot_only=0 \
	persist.camera.nx549j.skip_bundle_setparam=0 \
	persist.camera.nx549j.skip_unmatched_head=0 \
	persist.camera.dual.camera=0
