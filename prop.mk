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

# Display: rotation black-flicker mitigation (command-mode OTM1906C/S6D1FA4X01 panel).
# SurfaceFlinger rotation animation exposes its black background on this cmd-mode
# panel; these two knobs cut the full black flash down to ~0.1 s (user-confirmed
# on kernel #271, 2026-07-16). NOT a hardware blank (mdss_fb_blank stays 0).
# TODO(rotation): the residual ~0.1 s is the ROTATE animation's black corners on a
# non-square 1080x1920 panel; there is NO runtime knob for the animation type.
# Eliminating it fully needs a framework change (default rotation animation
# ROTATE -> CROSSFADE, or JUMPCUT) = system-image rebuild. Deferred (cosmetic).
PRODUCT_PROPERTY_OVERRIDES += \
debug.sf.disable_backpressure=1 \
debug.sf.latch_unsignaled=0

NX549J_ENABLE_CAMERA2_FULL ?= false
NX549J_ENABLE_CAMERA2_RAW ?= false
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
