@tool
extends EditorPlugin
## Android plugin v2 packaging for PopPulseNative (US-42). The AAR is optional:
## until it is built (docs/build-android.md) exports simply skip it and
## Platform falls back to Input.vibrate_handheld etc.

var _export: ExportPlugin


func _enter_tree() -> void:
	_export = ExportPlugin.new()
	add_export_plugin(_export)


func _exit_tree() -> void:
	remove_export_plugin(_export)
	_export = null


class ExportPlugin extends EditorExportPlugin:
	const AAR := "res://addons/poppulse_native/bin/poppulse_native-release.aar"

	func _get_name() -> String:
		return "PopPulseNative"

	func _supports_platform(platform: EditorExportPlatform) -> bool:
		return platform is EditorExportPlatformAndroid and FileAccess.file_exists(AAR)

	func _get_android_libraries(_platform: EditorExportPlatform, _debug: bool) -> PackedStringArray:
		return PackedStringArray(["poppulse_native/bin/poppulse_native-release.aar"])

	func _get_android_dependencies(_platform: EditorExportPlatform, _debug: bool) -> PackedStringArray:
		return PackedStringArray(["androidx.core:core-ktx:1.13.1"])
