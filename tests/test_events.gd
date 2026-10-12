extends TestCase
## US-41: event data, activity window, progress + reward, remote updates.


func test_builtin_valid() -> void:
	var d := GameMode.load_config("res://data/events/events.json")
	check(Events.valid(d), "built-in events.json is valid")
	check(d.events.any(func(e: Dictionary) -> bool: return str(e.id).begins_with("halloween")), "Halloween event defined")


func test_active_window_and_reward() -> void:
	var e: Dictionary = Events.data.events[0]
	Daily.fake_now = int(Time.get_unix_time_from_datetime_string(str(e.start) + "T12:00:00"))
	eq(Events.active_event().get("id", ""), e.id, "active on start date")
	check(ThemeManager.is_available(ThemeManager.get_theme("halloween")), "event theme usable during the event")
	SaveData.section("events").erase(e.id)
	SaveData.section("unlocks").themes = []
	for i in (e.challenges as Array).size():
		var c: Dictionary = e.challenges[i]
		var v := int(c.goal) - 10 if bool(c.get("lower_is_better", false)) else int(c.goal) + 10
		Events.submit(e, i, v)
	eq(Events.cleared_count(e), (e.challenges as Array).size(), "all cleared")
	check(SaveData.is_unlocked("themes", str(e.theme)), "theme kept for good")
	Daily.fake_now = int(Time.get_unix_time_from_datetime_string(str(e.end) + "T12:00:00")) + 86400 * 3
	check(Events.active_event().get("id", "") != e.id, "inactive after end")
	check(ThemeManager.is_available(ThemeManager.get_theme("halloween")), "still available after clearing")
	SaveData.section("unlocks").themes = []
	check(not ThemeManager.is_available(ThemeManager.get_theme("halloween")), "not available after the event without clearing")
	Daily.fake_now = 0


func test_remote_update() -> void:
	var keep: Dictionary = Events.data
	var newer := keep.duplicate(true)
	newer.version = int(keep.get("version", 0)) + 1
	newer.events[0].name = "Remote Name"
	check(not Events.apply_remote("{broken"), "broken JSON ignored")
	check(not Events.apply_remote(JSON.stringify({"version": 999, "events": [{"id": "x"}]})), "invalid schema ignored")
	var older := keep.duplicate(true)
	check(not Events.apply_remote(JSON.stringify(older)), "same/older version ignored")
	check(Events.apply_remote(JSON.stringify(newer)), "newer valid version used")
	eq(Events.data.events[0].name, "Remote Name", "content updated without app update")
	Events.data = keep
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Events.CACHE))
