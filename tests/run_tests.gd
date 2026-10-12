extends Node
## Runs every tests/test_*.gd. Headless:
##   Godot --headless --path . res://tests/run_tests.tscn -- --test-save
## Exit code 0 = all green.


func _ready() -> void:
	var total := 0
	var failed := 0
	var dir := DirAccess.open("res://tests")
	for f in dir.get_files():
		if not (f.begins_with("test_") and f.ends_with(".gd")) or f == "test_case.gd":
			continue
		var script: GDScript = load("res://tests/" + f)
		for m in script.get_script_method_list():
			var mname: String = m.name
			if not mname.begins_with("test_"):
				continue
			var t: TestCase = script.new()
			t._current = "%s.%s" % [f.get_basename(), mname]
			await t.call(mname)
			total += 1
			if t.failures.is_empty():
				print("  ok   ", t._current)
			else:
				failed += 1
				for x in t.failures:
					print("  FAIL ", x)
	print("%d tests, %d failed" % [total, failed])
	get_tree().quit(1 if failed > 0 else 0)
