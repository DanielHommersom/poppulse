class_name TestCase
extends RefCounted
## Minimal unit-test base: methods named test_* are run by tests/run_tests.gd.

var failures: Array[String] = []
var _current := ""


func check(cond: bool, msg: String) -> void:
	if not cond:
		failures.append("%s: %s" % [_current, msg])


func eq(a: Variant, b: Variant, msg: String) -> void:
	if typeof(a) in [TYPE_INT, TYPE_FLOAT] and typeof(b) in [TYPE_INT, TYPE_FLOAT]:
		check(is_equal_approx(float(a), float(b)), "%s (got %s, want %s)" % [msg, a, b])
	else:
		check(a == b, "%s (got %s, want %s)" % [msg, a, b])


## Throw-away file under user://tests/.
func tmp_path(name: String) -> String:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://tests"))
	var p := "user://tests/" + name
	for suffix in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(p + suffix))
	return p
