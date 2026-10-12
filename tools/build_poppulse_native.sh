#!/bin/bash
# Builds ios/plugins/poppulse_native/PopPulseNative.{debug,release}.xcframework
# (device arm64 + simulator arm64/x86_64) against the Godot source of the exact
# engine version. Usage: tools/build_poppulse_native.sh [path-to-godot-source]
# The source must be checked out at the engine's tag (here 4.7.2-stable).
set -euo pipefail

GODOT_SRC="${1:-$HOME/src/godot}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PLUGIN="$ROOT/ios/plugins/poppulse_native"
SRC="$PLUGIN/src/poppulse_native.mm"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# Generated headers the plugin needs (scons writes them in place, no engine build).
export PATH="$HOME/Library/Python/3.9/bin:$PATH"
(cd "$GODOT_SRC" && scons -s platform=ios target=template_debug \
	core/extension/gdextension_interface.gen.h core/disabled_classes.gen.h)

DEFINES=(-D_LIBCPP_REMOVE_TRANSITIVE_INCLUDES -DIOS_ENABLED -DAPPLE_EMBEDDED_ENABLED
	-DUNIX_ENABLED -DCOREAUDIO_ENABLED -DTHREADS_ENABLED -DNDEBUG)

compile() { # <variant debug|release> <sdk> <arch> <min-flag>
	local out="$WORK/$1-$2-$3"
	mkdir -p "$out"
	local extra=()
	[ "$1" = debug ] && extra+=(-DDEBUG_ENABLED -g)
	[ "$2" = iphonesimulator ] && extra+=(-DIOS_SIMULATOR)
	xcrun --sdk "$2" clang++ -x objective-c++ -std=gnu++17 -fobjc-arc -O2 \
		-arch "$3" -isysroot "$(xcrun --sdk "$2" --show-sdk-path)" "$4" \
		-fvisibility=hidden -ffp-contract=off -Wno-ambiguous-macro \
		-I"$GODOT_SRC" -I"$GODOT_SRC/platform/ios" "${DEFINES[@]}" ${extra[@]+"${extra[@]}"} \
		-c "$SRC" -o "$out/poppulse_native.o"
	xcrun ar rcs "$out/libPopPulseNative.a" "$out/poppulse_native.o"
}

for v in debug release; do
	compile $v iphoneos arm64 -miphoneos-version-min=14.0
	compile $v iphonesimulator arm64 -mios-simulator-version-min=14.0
	compile $v iphonesimulator x86_64 -mios-simulator-version-min=14.0
	mkdir -p "$WORK/$v-sim"
	xcrun lipo -create "$WORK/$v-iphonesimulator-arm64/libPopPulseNative.a" \
		"$WORK/$v-iphonesimulator-x86_64/libPopPulseNative.a" -output "$WORK/$v-sim/libPopPulseNative.a"
	rm -rf "$PLUGIN/PopPulseNative.$v.xcframework"
	xcodebuild -create-xcframework \
		-library "$WORK/$v-iphoneos-arm64/libPopPulseNative.a" \
		-library "$WORK/$v-sim/libPopPulseNative.a" \
		-output "$PLUGIN/PopPulseNative.$v.xcframework" >/dev/null
	echo "built PopPulseNative.$v.xcframework"
done
