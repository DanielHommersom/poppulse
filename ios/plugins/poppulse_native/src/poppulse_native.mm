#include "poppulse_native.h"

#import <UIKit/UIKit.h>
#import <AppTrackingTransparency/AppTrackingTransparency.h>

#include "core/config/engine.h"

// Generators are created once and kept "prepared" so the first tap has no
// latency. UIImpactFeedbackGenerator is fire-and-forget and does not queue,
// which is what keeps fast pop streams (>10/s) from lagging behind.
static UIImpactFeedbackGenerator *gen_light = nil;
static UIImpactFeedbackGenerator *gen_medium = nil;
static UIImpactFeedbackGenerator *gen_heavy = nil;
static UINotificationFeedbackGenerator *gen_notify = nil;

PopPulseNative *PopPulseNative::instance = nullptr;

void PopPulseNative::_bind_methods() {
	ClassDB::bind_method(D_METHOD("prepare_haptics"), &PopPulseNative::prepare_haptics);
	ClassDB::bind_method(D_METHOD("haptic", "kind"), &PopPulseNative::haptic);
	ClassDB::bind_method(D_METHOD("share_image", "png_path", "text"), &PopPulseNative::share_image);
	ClassDB::bind_method(D_METHOD("system_reduce_motion"), &PopPulseNative::system_reduce_motion);
	ClassDB::bind_method(D_METHOD("open_url", "url"), &PopPulseNative::open_url);
	ClassDB::bind_method(D_METHOD("request_tracking_authorization"), &PopPulseNative::request_tracking_authorization);
	ClassDB::bind_method(D_METHOD("tracking_status"), &PopPulseNative::tracking_status);
}

PopPulseNative *PopPulseNative::get_singleton() {
	return instance;
}

void PopPulseNative::prepare_haptics() {
	dispatch_async(dispatch_get_main_queue(), ^{
		if (gen_light == nil) {
			gen_light = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
			gen_medium = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium];
			gen_heavy = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleHeavy];
			gen_notify = [[UINotificationFeedbackGenerator alloc] init];
		}
		[gen_light prepare];
		[gen_medium prepare];
		[gen_heavy prepare];
		[gen_notify prepare];
	});
}

void PopPulseNative::haptic(int p_kind) {
	dispatch_async(dispatch_get_main_queue(), ^{
		if (gen_light == nil) {
			return;
		}
		switch (p_kind) {
			case 0:
				[gen_light impactOccurredWithIntensity:0.8];
				[gen_light prepare];
				break;
			case 1:
				[gen_medium impactOccurred];
				[gen_medium prepare];
				break;
			case 2:
				[gen_heavy impactOccurred];
				[gen_heavy prepare];
				break;
			default:
				[gen_notify notificationOccurred:UINotificationFeedbackTypeError];
				[gen_notify prepare];
				break;
		}
	});
}

// Root view controller of the foreground window (iOS 13+ scene API).
static UIViewController *root_view_controller() {
	for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
		if (scene.activationState == UISceneActivationStateForegroundActive && [scene isKindOfClass:UIWindowScene.class]) {
			for (UIWindow *window in ((UIWindowScene *)scene).windows) {
				if (window.isKeyWindow) {
					return window.rootViewController;
				}
			}
		}
	}
	return nil;
}

void PopPulseNative::share_image(const String &p_png_path, const String &p_text) {
	NSString *path = [NSString stringWithUTF8String:p_png_path.utf8().get_data()];
	NSString *text = [NSString stringWithUTF8String:p_text.utf8().get_data()];
	dispatch_async(dispatch_get_main_queue(), ^{
		UIImage *image = [UIImage imageWithContentsOfFile:path];
		NSMutableArray *items = [NSMutableArray arrayWithObject:text];
		if (image != nil) {
			[items addObject:image];
		}
		UIActivityViewController *vc = [[UIActivityViewController alloc] initWithActivityItems:items applicationActivities:nil];
		UIViewController *root = root_view_controller();
		if (root == nil) {
			return;
		}
		while (root.presentedViewController != nil) {
			root = root.presentedViewController;
		}
		// iPad requires an anchor for the popover.
		vc.popoverPresentationController.sourceView = root.view;
		vc.popoverPresentationController.sourceRect = CGRectMake(CGRectGetMidX(root.view.bounds), CGRectGetMaxY(root.view.bounds) - 80, 1, 1);
		[root presentViewController:vc animated:YES completion:nil];
	});
}

bool PopPulseNative::system_reduce_motion() {
	return UIAccessibilityIsReduceMotionEnabled();
}

void PopPulseNative::open_url(const String &p_url) {
	NSString *s = [NSString stringWithUTF8String:p_url.utf8().get_data()];
	dispatch_async(dispatch_get_main_queue(), ^{
		NSURL *url = [NSURL URLWithString:s];
		if (url != nil) {
			[UIApplication.sharedApplication openURL:url options:@{} completionHandler:nil];
		}
	});
}

// ATT must be requested while the app is active; the result is polled from
// GDScript through tracking_status().
void PopPulseNative::request_tracking_authorization() {
	if (@available(iOS 14, *)) {
		dispatch_async(dispatch_get_main_queue(), ^{
			[ATTrackingManager requestTrackingAuthorizationWithCompletionHandler:^(ATTrackingManagerAuthorizationStatus status){
			}];
		});
	}
}

int PopPulseNative::tracking_status() {
	if (@available(iOS 14, *)) {
		return (int)ATTrackingManager.trackingAuthorizationStatus;
	}
	return 3;
}

PopPulseNative::PopPulseNative() {
	instance = this;
}

PopPulseNative::~PopPulseNative() {
	if (instance == this) {
		instance = nullptr;
	}
}

// --- Plugin entry points (referenced from PopPulseNative.gdip) -----------------

static PopPulseNative *plugin = nullptr;

void poppulse_native_init() {
	plugin = memnew(PopPulseNative);
	Engine::get_singleton()->add_singleton(Engine::Singleton("PopPulseNative", plugin));
}

void poppulse_native_deinit() {
	if (plugin) {
		memdelete(plugin);
		plugin = nullptr;
	}
}
