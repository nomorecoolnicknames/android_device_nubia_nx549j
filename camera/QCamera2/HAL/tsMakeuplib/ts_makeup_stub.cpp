#include "ts_makeup_engine.h"
#include "ts_detectface_engine.h"

int ts_makeup_skin_beautyEx(TSMakeupDataEx*, TSMakeupDataEx*, const TSRect*, int, int) { return 0; }
void ts_makeup_finish() {}
TSHandle ts_detectface_create_context() { return 0; }
int ts_detectface_detectEx(TSHandle, TSMakeupDataEx*) { return 0; }
int ts_detectface_get_face_info(TSHandle, int, TSRect*, TSRect*, TSRect*, TSRect*) { return 0; }
void ts_detectface_destroy_context(TSHandle*) {}
