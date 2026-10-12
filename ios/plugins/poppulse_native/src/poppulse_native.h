// PopPulseNative — tiny iOS plugin behind autoload/platform.gd.
// Exposes the singleton "PopPulseNative":
//   prepare_haptics()                      warm up the feedback generators
//   haptic(kind: int)                      0 light, 1 medium, 2 heavy, 3 error
//   share_image(png_path: String, text: String)   native share sheet (US-20)
//   system_reduce_motion() -> bool         UIAccessibilityIsReduceMotionEnabled (US-36)
//   open_url(url: String)                  open a URL (settings, privacy policy)
//   request_tracking_authorization()       App Tracking Transparency prompt (US-31)
//   tracking_status() -> int               0 not determined, 1 restricted, 2 denied, 3 authorized
#pragma once

#include "core/object/class_db.h"
#include "core/object/object.h"

class PopPulseNative : public Object {
	GDCLASS(PopPulseNative, Object);

	static PopPulseNative *instance;

protected:
	static void _bind_methods();

public:
	static PopPulseNative *get_singleton();

	void prepare_haptics();
	void haptic(int p_kind);
	void share_image(const String &p_png_path, const String &p_text);
	bool system_reduce_motion();
	void open_url(const String &p_url);
	void request_tracking_authorization();
	int tracking_status();

	PopPulseNative();
	~PopPulseNative();
};
