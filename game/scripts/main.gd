extends Node3D

const QuestionBank = preload("res://scripts/question_bank.gd")
const Studio = preload("res://scripts/studio.gd")
const MONEY = [100, 200, 300, 500, 1000, 2000, 4000, 8000, 16000, 32000, 64000, 125000, 250000, 500000, 1000000]
const GOLD = Color("dfbf7d")
const MUTED = Color("919bc0")
var studio: Node3D
var ui: Control
var lobby: Control
var play_ui: Control
var question_label: Label
var meta_label: Label
var status_label: Label
var bank_label: Label
var source_label: RichTextLabel
var answers: Array[Button] = []
var ladder: Array[Label] = []
var lifelines: Array[Button] = []
var final_button: Button
var next_button: Button
var walk_button: Button
var selected_categories: Array = QuestionBank.CATEGORIES.duplicate()
var category_buttons: Array[Button] = []
var category_count: Label
var character_buttons: Array[Button] = []
var character_index := 0
var character_name: Label
var timed_button: CheckButton
var timed := false
var time_left := 30.0
var timer_label: Label
var timer_bar: ProgressBar
var safe_label: Label
var source_panel: Panel
var ladder_highlight: Panel
var best_label: Label
var best := 0
var correct_count := 0
var persist_enabled := true
var modal_cancel: Button
var modal_action: Callable
var modal_shade: ColorRect
var vote_container: Control
var vote_bars: Array[ProgressBar] = []
var vote_labels: Array[Label] = []
var mode_button: CheckButton
var start_button: Button
var modal: Panel
var modal_title: Label
var modal_text: Label
var modal_button: Button
var pack: Array = []
var round_index := 0
var selected := -1
var bank := 0
var guarantee := 0
var phase := "lobby"
var used: Array = []
var eliminated: Array = []
var generation := 0
var api := "http://127.0.0.1:8765"
var audio_player: AudioStreamPlayer
var muted := false
var answer_styles := {}
var recent_questions: Array = []
var shared_bank: Array = []
var rotation_repeats := 0
var reduced_motion := false
var motion_button: CheckButton
var preference_path := "user://preferences.cfg"

func _ready() -> void:
	if OS.has_feature("web"):
		api = str(JavaScriptBridge.eval("new URL('.', window.location.href).href")).trim_suffix("/")
	studio = Studio.new()
	add_child(studio)
	load_preferences()
	if OS.has_feature("web"):
		reduced_motion = reduced_motion or bool(JavaScriptBridge.eval("window.matchMedia('(prefers-reduced-motion: reduce)').matches"))
	studio.reduced_motion = reduced_motion
	build_ui()
	select_character(character_index)
	audio_player = AudioStreamPlayer.new()
	add_child(audio_player)
	mode_button.text = "%d curated questions · checking weekly bank…" % QuestionBank.active_bank().size()
	if not persist_enabled: return
	var manifest := await request("/bank/manifest.json", {}, false)
	var response := {}
	var snapshot_path: String = str(manifest.get("path", ""))
	if snapshot_path.begins_with("versions/") and snapshot_path.ends_with(".json") and not snapshot_path.contains(".."):
		response = await request("/bank/" + snapshot_path, {}, false)
		if response.get("version", "") != manifest.get("active", "unavailable"): response = {}
	if response.get("questions", []) is Array and not response.get("questions", []).is_empty():
		shared_bank = response.questions
		mode_button.text = "%d questions · bank checked %s" % [shared_bank.size(), str(response.get("updated_at", "unknown"))]
	if response.is_empty() or response.has("error"):
		mode_button.text = "%d bundled questions · offline fallback" % QuestionBank.active_bank().size()
	refresh_categories()

func request(path: String, body: Dictionary = {}, post := true) -> Dictionary:
	var http := HTTPRequest.new()
	add_child(http)
	http.accept_gzip = not OS.has_feature("web") # Browser fetch already decodes Content-Encoding.
	http.timeout = 150 if path == "/api/pack" else 35
	var error := http.request(api + path, ["Content-Type: application/json"], HTTPClient.METHOD_POST if post else HTTPClient.METHOD_GET, JSON.stringify(body) if post else "")
	if error != OK:
		http.queue_free()
		return {"error": "The question service is unavailable."}
	var response = await http.request_completed
	http.queue_free()
	var data = JSON.parse_string(response[3].get_string_from_utf8())
	if response[1] != 200 or not data is Dictionary:
		return {"error": "The question service could not complete this request. Try again."}
	return data

func label(parent: Node, value: String, pos: Vector2, size_value: Vector2, font_size := 20, color := Color.WHITE) -> Label:
	var n := Label.new()
	n.text = value
	n.position = pos
	n.size = size_value
	n.add_theme_font_size_override("font_size", font_size)
	n.add_theme_color_override("font_color", color)
	n.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(n)
	return n

func style(bg: Color, border: Color, width := 1) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(width)
	s.set_corner_radius_all(5)
	s.content_margin_left = 18
	s.content_margin_right = 18
	return s

func answer_style(bg: Color, border: Color) -> StyleBoxTexture:
	var key := bg.to_html(false) + border.to_html(false)
	if answer_styles.has(key): return answer_styles[key]
	var svg := '<svg xmlns="http://www.w3.org/2000/svg" width="526" height="52"><defs><linearGradient id="g" x2="0" y2="1"><stop stop-color="#%s"/><stop offset="1" stop-color="#%s"/></linearGradient></defs><path d="M24 1 H502 L525 26 L502 51 H24 L1 26 Z" fill="url(#g)" stroke="#%s" stroke-width="2"/></svg>' % [bg.lightened(0.07).to_html(false), bg.to_html(false), border.to_html(false)]
	var image := Image.new()
	image.load_svg_from_string(svg)
	var s := StyleBoxTexture.new()
	s.texture = ImageTexture.create_from_image(image)
	s.content_margin_left = 29
	s.content_margin_right = 29
	answer_styles[key] = s
	return s

func button(parent: Node, value: String, pos: Vector2, size_value: Vector2, callback: Callable) -> Button:
	var n := Button.new()
	n.text = value
	n.position = pos
	n.size = size_value
	n.add_theme_font_size_override("font_size", 18)
	n.add_theme_stylebox_override("normal", style(Color("101a38"), Color("45517b")))
	n.add_theme_stylebox_override("hover", style(Color("26345a"), GOLD))
	n.add_theme_stylebox_override("focus", style(Color(0, 0, 0, 0), GOLD, 2))
	n.add_theme_stylebox_override("pressed", style(Color("876834"), GOLD))
	n.add_theme_stylebox_override("disabled", style(Color("0b1023"), Color("242c46")))
	n.pressed.connect(callback)
	parent.add_child(n)
	return n

func panel(parent: Node, pos: Vector2, size_value: Vector2, color: Color) -> Panel:
	var n := Panel.new()
	n.position = pos
	n.size = size_value
	n.add_theme_stylebox_override("panel", style(color, Color("293151")))
	parent.add_child(n)
	return n

func build_ui() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)
	ui = Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(ui)
	panel(ui, Vector2.ZERO, Vector2(1600, 86), Color("070d20"))
	label(ui, "MILLIONAIRE", Vector2(40, 12), Vector2(380, 36), 30, GOLD)
	label(ui, "T R E N D I N G   E D I T I O N", Vector2(42, 53), Vector2(350, 18), 11, MUTED)
	label(ui, "15 QUESTIONS   /   3 LIFELINES", Vector2(526, 29), Vector2(570, 28), 14, MUTED)
	button(ui, "Sound: off" if muted else "Sound: on", Vector2(1300, 23), Vector2(122, 40), toggle_sound).name = "Sound"
	button(ui, "Camera", Vector2(1434, 23), Vector2(126, 40), func(): studio.cycle_camera()).name = "Camera"
	motion_button = CheckButton.new()
	motion_button.position = Vector2(1070, 24)
	motion_button.size = Vector2(218, 40)
	motion_button.text = "Reduced motion"
	motion_button.button_pressed = reduced_motion
	motion_button.toggled.connect(func(value):
		reduced_motion = value
		studio.reduced_motion = value
		save_preferences())
	ui.add_child(motion_button)
	ui.get_node("Camera").disabled = true
	lobby = Control.new()
	ui.add_child(lobby)
	panel(lobby, Vector2(28, 112), Vector2(970, 700), Color(0.02, 0.035, 0.09, 0.96))
	label(lobby, "01  /  MAKE IT YOUR GAME", Vector2(58, 135), Vector2(600, 25), 13, GOLD)
	label(lobby, "Choose your themes.", Vector2(54, 176), Vector2(920, 67), 47)
	label(lobby, "Pick one, pick a few, or take on everything. Every question stays in your mix.", Vector2(58, 252), Vector2(910, 32), 18, MUTED)
	category_count = label(lobby, "", Vector2(58, 307), Vector2(470, 30), 15, GOLD)
	button(lobby, "Select all", Vector2(720, 302), Vector2(115, 36), func(): set_categories(QuestionBank.CATEGORIES))
	button(lobby, "Clear", Vector2(847, 302), Vector2(115, 36), func(): set_categories([]))
	var descriptions := ["The internet, platforms & creators", "Worlds, consoles & iconic games", "Artists, instruments & great records", "Cinema, television & storytelling", "Discoveries, nature & the universe", "Code, inventions & digital life", "The rules, the teams & the greats", "Places, flavors & everyday culture"]
	for i in range(8):
		var pos := Vector2(58 + (i % 2) * 458, 360 + (i / 2) * 91)
		var n := button(lobby, "", pos, Vector2(446, 78), toggle_category.bind(i))
		n.alignment = HORIZONTAL_ALIGNMENT_LEFT
		category_buttons.append(n)
		label(n, QuestionBank.CATEGORIES[i], Vector2(23, 10), Vector2(365, 30), 22)
		label(n, descriptions[i], Vector2(23, 44), Vector2(375, 22), 13, MUTED)
		label(n, "", Vector2(391, 23), Vector2(35, 28), 20, GOLD).name = "Mark"
	label(lobby, "THE CLIMB", Vector2(58, 738), Vector2(130, 24), 12, GOLD)
	label(lobby, "$100    /    $1,000    /    $32,000    /    $1,000,000", Vector2(197, 731), Vector2(754, 37), 23)
	label(lobby, "Safety nets at questions 5 and 10. You can walk away with your bank.", Vector2(197, 771), Vector2(754, 25), 14, MUTED)
	panel(lobby, Vector2(1020, 112), Vector2(552, 190), Color(0.02, 0.035, 0.09, 0.94))
	label(lobby, "02  /  YOUR HOT SEAT", Vector2(1046, 133), Vector2(490, 25), 13, GOLD)
	character_name = label(lobby, "", Vector2(1046, 171), Vector2(500, 43), 30)
	for i in range(3):
		character_buttons.append(button(lobby, ["Alex", "Mina", "Jules"][i], Vector2(1046 + i * 167, 237), Vector2(155, 42), select_character.bind(i)))
	panel(lobby, Vector2(1020, 565), Vector2(552, 247), Color(0.02, 0.035, 0.09, 0.97))
	label(lobby, "03  /  SET THE STAKES", Vector2(1046, 586), Vector2(490, 25), 13, GOLD)
	timed_button = CheckButton.new()
	timed_button.position = Vector2(1040, 626)
	timed_button.size = Vector2(500, 40)
	timed_button.text = "Beat the clock · 30 seconds per question"
	timed_button.button_pressed = timed
	timed_button.add_theme_font_size_override("font_size", 16)
	lobby.add_child(timed_button)
	mode_button = CheckButton.new()
	mode_button.position = Vector2(1040, 673)
	mode_button.size = Vector2(500, 40)
	mode_button.text = "Cached question bank"
	mode_button.disabled = true
	mode_button.add_theme_font_size_override("font_size", 16)
	lobby.add_child(mode_button)
	label(lobby, "History stays on this device. Clearing storage resets it.
Finite pools repeat oldest facts once exhausted.", Vector2(1046, 734), Vector2(492, 54), 15, MUTED)
	best_label = label(lobby, "", Vector2(40, 839), Vector2(660, 35), 17, MUTED)
	start_button = button(lobby, "TAKE THE HOT SEAT", Vector2(1020, 830), Vector2(552, 54), start_game)
	start_button.add_theme_stylebox_override("normal", answer_style(Color("96621c"), GOLD))
	start_button.add_theme_font_size_override("font_size", 21)
	refresh_categories()
	play_ui = Control.new()
	play_ui.visible = false
	ui.add_child(play_ui)
	panel(play_ui, Vector2(1280, 105), Vector2(292, 694), Color(0.02, 0.035, 0.09, 0.97))
	label(play_ui, "THE MILLION DOLLAR CLIMB", Vector2(1302, 119), Vector2(253, 28), 13, GOLD)
	ladder_highlight = panel(play_ui, Vector2(1293, 0), Vector2(266, 33), Color("98651e"))
	for i in range(15):
		var idx := 14 - i
		var n := label(play_ui, "%02d     %s" % [idx + 1, money(MONEY[idx])], Vector2(1310, 161 + i * 34), Vector2(244, 32), 21, MUTED)
		ladder.push_front(n)
	bank_label = label(play_ui, "", Vector2(1302, 693), Vector2(260, 39), 24, GOLD)
	safe_label = label(play_ui, "", Vector2(1302, 746), Vector2(260, 30), 15, MUTED)
	label(play_ui, "ONE OF EACH. MAKE THEM COUNT.", Vector2(40, 108), Vector2(590, 28), 12, MUTED)
	for i in range(3):
		var n := button(play_ui, ["1   /   50:50", "2   /   Phone a friend", "3   /   Ask the audience"][i], Vector2(40 + i * 237, 144), Vector2(224, 46), use_lifeline.bind(i))
		n.add_theme_font_size_override("font_size", 16)
		lifelines.append(n)
	timer_label = label(play_ui, "", Vector2(1008, 118), Vector2(237, 36), 26, GOLD)
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	timer_bar = ProgressBar.new()
	timer_bar.position = Vector2(1050, 166)
	timer_bar.size = Vector2(195, 5)
	timer_bar.show_percentage = false
	timer_bar.max_value = 30
	timer_bar.add_theme_stylebox_override("background", style(Color("141c36"), Color("141c36"), 0))
	timer_bar.add_theme_stylebox_override("fill", style(GOLD, GOLD, 0))
	play_ui.add_child(timer_bar)
	source_panel = panel(play_ui, Vector2(40, 399), Vector2(1208, 111), Color(0.02, 0.035, 0.09, 0.96))
	source_label = RichTextLabel.new()
	source_label.position = Vector2(20, 14)
	source_label.size = Vector2(1168, 85)
	source_label.meta_clicked.connect(func(meta):
		if str(meta).begins_with("https://"): OS.shell_open(str(meta)))
	source_label.add_theme_font_size_override("normal_font_size", 17)
	source_label.add_theme_color_override("default_color", Color("d5dbee"))
	source_panel.add_child(source_label)
	panel(play_ui, Vector2(28, 526), Vector2(1232, 295), Color(0.018, 0.026, 0.07, 0.97))
	meta_label = label(play_ui, "", Vector2(55, 538), Vector2(1180, 27), 13, GOLD)
	var question_box := panel(play_ui, Vector2(40, 577), Vector2(1208, 99), Color("0c204c"))
	question_box.add_theme_stylebox_override("panel", answer_style(Color("081e4d"), Color("728abb")))
	question_label = label(play_ui, "", Vector2(85, 584), Vector2(1118, 84), 27)
	question_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	question_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	question_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	for i in range(4):
		var n := button(play_ui, "", Vector2(40 + (i % 2) * 612, 694 + (i / 2) * 62), Vector2(596, 52), choose.bind(i))
		n.add_theme_stylebox_override("hover", answer_style(Color("26345a"), GOLD))
		n.add_theme_stylebox_override("pressed", answer_style(Color("765826"), GOLD))
		n.add_theme_stylebox_override("disabled", answer_style(Color("0b1023"), Color("242c46")))
		n.alignment = HORIZONTAL_ALIGNMENT_LEFT
		n.add_theme_font_size_override("font_size", 21)
		n.add_theme_color_override("font_disabled_color", Color("dbe2f1"))
		var feedback := label(n, "", Vector2(416, 1), Vector2(148, 14), 11, Color.WHITE)
		feedback.name = "Feedback"
		feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		answers.append(n)
	status_label = label(play_ui, "", Vector2(40, 833), Vector2(884, 46), 17, MUTED)
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	final_button = button(play_ui, "FINAL ANSWER", Vector2(976, 834), Vector2(272, 48), lock_answer)
	final_button.add_theme_stylebox_override("normal", answer_style(Color("96621c"), GOLD))
	next_button = button(play_ui, "Next question", Vector2(976, 834), Vector2(272, 48), next_question)
	next_button.visible = false
	walk_button = button(play_ui, "Walk away", Vector2(1280, 815), Vector2(142, 44), walk_away)
	button(play_ui, "Leave game", Vector2(1432, 815), Vector2(140, 44), confirm_leave)
	label(play_ui, "A–D  select    ENTER  lock / next", Vector2(1286, 864), Vector2(287, 25), 12, MUTED)
	modal_shade = ColorRect.new()
	modal_shade.color = Color(0.003, 0.006, 0.02, 0.80)
	modal_shade.size = Vector2(1600, 900)
	ui.add_child(modal_shade)
	modal = panel(ui, Vector2(410, 225), Vector2(780, 460), Color("0c1733"))
	modal_title = label(modal, "", Vector2(36, 29), Vector2(708, 52), 32, GOLD)
	modal_text = label(modal, "", Vector2(36, 100), Vector2(708, 245), 22)
	modal_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	modal_button = button(modal, "Back to the question", Vector2(36, 377), Vector2(708, 50), accept_modal)
	modal_cancel = button(modal, "Keep playing", Vector2(402, 377), Vector2(342, 50), cancel_modal)
	vote_container = Control.new()
	vote_container.position = Vector2(36, 188)
	modal.add_child(vote_container)
	for i in range(4):
		var bar := ProgressBar.new()
		bar.position = Vector2(38, i * 37)
		bar.size = Vector2(597, 23)
		bar.show_percentage = false
		bar.add_theme_stylebox_override("background", style(Color("152444"), Color("152444"), 0))
		bar.add_theme_stylebox_override("fill", style(Color("638bdf"), Color("638bdf"), 0))
		vote_container.add_child(bar)
		vote_bars.append(bar)
		label(vote_container, "ABCD"[i], Vector2(0, i * 37 - 3), Vector2(30, 30), 19, GOLD)
		vote_labels.append(label(vote_container, "", Vector2(651, i * 37 - 3), Vector2(64, 30), 19))
	modal.visibility_changed.connect(func(): modal_shade.visible = modal.visible)
	hide_modal()

func refresh_categories() -> void:
	for i in range(category_buttons.size()):
		var active := selected_categories.has(QuestionBank.CATEGORIES[i])
		category_buttons[i].add_theme_stylebox_override("normal", style(Color("17386b") if active else Color("0b142b"), GOLD if active else Color("344467"), 2 if active else 1))
		category_buttons[i].get_node("Mark").text = "+" if active else ""
	var bank_data := QuestionBank.active_bank() if shared_bank.is_empty() else shared_bank
	var count := 0
	for q in bank_data:
		if selected_categories.has(q.category) and QuestionBank.available(q, Time.get_date_string_from_system(true)): count += 1
	category_count.text = "%d OF 8 THEMES  /  %d CACHED QUESTIONS" % [selected_categories.size(), count]
	start_button.disabled = selected_categories.is_empty() or phase == "preparing"
	best_label.text = "PERSONAL BEST   %s     /     15 questions to a million" % money(best)

func set_categories(values: Array) -> void:
	if phase == "preparing": return
	selected_categories = values.duplicate()
	refresh_categories()

func toggle_category(index: int) -> void:
	if phase == "preparing": return
	var category: String = QuestionBank.CATEGORIES[index]
	if selected_categories.has(category): selected_categories.erase(category)
	else: selected_categories.append(category)
	refresh_categories()

func select_character(index: int) -> void:
	character_index = index
	studio.set_character(index)
	character_name.text = ["Alex  /  The curious one", "Mina  /  The quick thinker", "Jules  /  The all-rounder"][index]
	for i in range(character_buttons.size()):
		character_buttons[i].add_theme_stylebox_override("normal", style(Color("17386b") if i == index else Color("0b142b"), GOLD if i == index else Color("344467")))

func load_preferences() -> void:
	if not persist_enabled: return
	var config := ConfigFile.new()
	if config.load(preference_path) != OK: return
	var saved = config.get_value("game", "categories", QuestionBank.CATEGORIES)
	if saved is Array:
		var valid: Array = saved.filter(func(c): return QuestionBank.CATEGORIES.has(c))
		if not valid.is_empty(): selected_categories = valid
	character_index = clampi(int(config.get_value("game", "character", 0)), 0, 2)
	muted = bool(config.get_value("game", "muted", false))
	timed = bool(config.get_value("game", "timed", false))
	best = int(config.get_value("game", "best", 0))
	reduced_motion = bool(config.get_value("game", "reduced_motion", false))
	var history = config.get_value("game", "recent_questions", [])
	if history is Array: recent_questions = history.slice(maxi(0, history.size() - QuestionBank.HISTORY_LIMIT))

func save_preferences() -> void:
	if not persist_enabled: return
	var config := ConfigFile.new()
	config.load(preference_path) # Keep unknown fields and older saves intact.
	config.set_value("game", "categories", selected_categories)
	config.set_value("game", "character", character_index)
	config.set_value("game", "muted", muted)
	config.set_value("game", "timed", timed)
	config.set_value("game", "best", best)
	config.set_value("game", "recent_questions", recent_questions)
	config.set_value("game", "reduced_motion", reduced_motion)
	if config.save(preference_path) != OK:
		push_warning("Local preferences/history could not be saved; rotation lasts this session.")

func money(value: int) -> String:
	var result := str(value)
	var i := result.length() - 3
	while i > 0:
		result = result.insert(i, ",")
		i -= 3
	return "$" + result

func start_game() -> void:
	if selected_categories.is_empty() or phase == "preparing": return
	phase = "preparing"
	generation += 1
	start_button.disabled = true
	start_button.text = "Opening the studio…"
	timed = timed_button.button_pressed
	var selection := QuestionBank.select_pack(selected_categories, recent_questions, shared_bank)
	pack = selection.questions
	rotation_repeats = int(selection.repeats)
	if pack.size() != 15:
		phase = "lobby"
		start_button.disabled = false
		start_button.text = "TAKE THE HOT SEAT"
		show_modal("This mix needs more questions", str(selection.error) + " Choose more themes or import a reviewed batch.")
		return
	save_preferences()
	start_button.disabled = false
	start_button.text = "TAKE THE HOT SEAT"
	for q in pack:
		var correct_text: String = q.answers[int(q.correct)]
		q.answers.shuffle()
		q.correct = q.answers.find(correct_text)
	round_index = 0
	correct_count = 0
	bank = 0
	guarantee = 0
	used.clear()
	lobby.hide()
	play_ui.show()
	ui.get_node("Camera").disabled = false
	studio.cinematic = false
	studio.shot = "wide"
	load_question()

func load_question() -> void:
	phase = "question"
	selected = -1
	eliminated.clear()
	hide_modal()
	source_label.text = ""
	source_panel.hide()
	time_left = 30.0
	timer_bar.visible = timed
	studio.shot = "wide"
	studio.set_mood("question")
	var q: Dictionary = pack[round_index]
	if not QuestionBank.available(q, Time.get_date_string_from_system(true)):
		finish_run("A question expired. Your bank is safe.")
		return
	recent_questions = QuestionBank.remember(recent_questions, q)
	save_preferences()
	meta_label.text = "QUESTION %02d / 15     •     %s     •     %s" % [round_index + 1, str(q.category).to_upper(), "NASA HEADLINE / DATED" if q.get("kind", "evergreen") == "current" else "CURATED BANK"]
	question_label.text = q.question
	status_label.text = "Playing for %s · Select an answer, then lock it in." % money(MONEY[round_index])
	if rotation_repeats > 0:
		status_label.text = "Pool exhausted: %d recent facts reused in this run. Oldest first." % rotation_repeats
	for i in range(4):
		answers[i].get_node("Feedback").text = ""
		answers[i].text = "%s:    %s" % ["ABCD"[i], q.answers[i]]
		var text_width := answers[i].get_theme_font("font").get_string_size(answers[i].text, HORIZONTAL_ALIGNMENT_LEFT, -1, 21).x
		answers[i].add_theme_font_size_override("font_size", clampi(int(21 * 528 / maxf(text_width, 1)), 17, 21))
		answers[i].disabled = false
		answers[i].add_theme_stylebox_override("normal", answer_style(Color("101a38"), Color("717dbe")))
		answers[i].add_theme_stylebox_override("disabled", answer_style(Color("0b1023"), Color("242c46")))
	for i in range(15):
		ladder[i].add_theme_color_override("font_color", GOLD if i == round_index else Color("83ceaf") if i < round_index else Color.WHITE if i in [4, 9, 14] else MUTED)
	bank_label.text = money(bank)
	safe_label.text = "GUARANTEED  " + money(guarantee)
	ladder_highlight.position.y = 161 + (14 - round_index) * 34
	for i in range(3):
		lifelines[i].disabled = used.has(i)
		lifelines[i].text = ["1   /   50:50", "2   /   Phone a friend", "3   /   Ask the audience"][i] + (" · used" if used.has(i) else "")
	final_button.show()
	final_button.disabled = true
	next_button.hide()
	next_button.text = "Next question"
	walk_button.disabled = false
	play_tone(330.0, 0.11)

func choose(index: int) -> void:
	if phase != "question" or eliminated.has(index) or modal.visible: return
	selected = index
	for i in range(4):
		answers[i].add_theme_stylebox_override("normal", answer_style(Color("765826") if i == index else Color("101a38"), GOLD if i == index else Color("717dbe")))
	final_button.disabled = false
	status_label.text = "%s selected. Is that your final answer?" % "ABCD"[index]
	play_tone(440.0, 0.06)

func lock_answer() -> void:
	if phase != "question" or selected < 0 or modal.visible: return
	phase = "locked"
	final_button.disabled = true
	walk_button.disabled = true
	for b in answers: b.disabled = true
	answers[selected].add_theme_stylebox_override("disabled", answer_style(Color("96621c"), GOLD))
	studio.shot = "contestant"
	studio.set_mood("locked")
	for b in lifelines: b.disabled = true
	status_label.text = "You've locked in %s…" % "ABCD"[selected]
	var token := generation
	await get_tree().create_timer(0.12 if reduced_motion else 1.35 + round_index * 0.035).timeout
	if token != generation or phase != "locked": return
	var q: Dictionary = pack[round_index]
	var correct := int(q.correct)
	answers[correct].get_node("Feedback").text = "[correct]"
	if selected != correct: answers[selected].get_node("Feedback").text = "[your answer]"
	answers[correct].add_theme_stylebox_override("disabled", answer_style(Color("17604f"), Color("7ad4ae")))
	for i in range(4):
		if i != correct: answers[i].add_theme_stylebox_override("disabled", answer_style(Color("5d263c") if i == selected else Color("0b1023"), Color("c66679") if i == selected else Color("242c46")))
	source_panel.show()
	source_label.clear()
	source_label.add_text(str(q.explanation) + (" · Checked " + str(q.verified_at) if q.has("verified_at") else "") + "\n")
	source_label.push_meta(str(q.get("source", "")))
	source_label.add_text("Read the source")
	source_label.pop()
	final_button.hide()
	if selected == correct:
		correct_count += 1
		bank = MONEY[round_index]
		studio.set_mood("correct")
		if round_index in [4, 9]: guarantee = bank
		bank_label.text = money(bank)
		safe_label.text = "GUARANTEED  " + money(guarantee)
		play_tone(660.0, 0.35)
		status_label.text = "Correct! %s banked. Guaranteed: %s." % [money(bank), money(guarantee)]
		phase = "reveal"
		next_button.show()
		if round_index == 14:
			phase = "finished"
			next_button.hide()
			finish_run("You're a millionaire!")
	else:
		phase = "finished"
		bank = guarantee
		bank_label.text = money(bank)
		safe_label.text = "FINAL PAYOUT"
		status_label.text = "The answer was %s. You take home %s." % ["ABCD"[correct], money(bank)]
		play_tone(150.0, 0.4)
		studio.set_mood("wrong")
		next_button.text = "See results"
		next_button.show()
		record_result()

func next_question() -> void:
	if phase == "finished":
		finish_run("That’s the game.")
		return
	if phase != "reveal": return
	round_index += 1
	load_question()

func walk_away() -> void:
	if phase != "question" or modal.visible: return
	show_modal("Your money. Your call.", "Walk away with %s?\n\nAn incorrect answer leaves you with %s. You can keep playing for %s." % [money(bank), money(guarantee), money(MONEY[round_index])])
	set_modal_action("Take " + money(bank), cash_out, true)

func cash_out() -> void:
	if phase != "question": return
	finish_run("A good night in the hot seat.")

func confirm_leave() -> void:
	if phase == "finished":
		back_to_lobby()
		return
	if modal.visible or phase == "locked": return
	show_modal("Leave this game?", "Your current run will end. Return to the studio to change your themes or character.")
	set_modal_action("Leave game", back_to_lobby, true)

func record_result() -> void:
	best = maxi(best, bank)
	save_preferences()

func finish_run(title_value: String) -> void:
	phase = "finished"
	for b in answers: b.disabled = true
	for b in lifelines: b.disabled = true
	final_button.hide()
	walk_button.disabled = true
	next_button.text = "See results"
	next_button.show()
	record_result()
	bank_label.text = money(bank)
	safe_label.text = "FINAL PAYOUT"
	status_label.text = "Run complete. You take home %s." % money(bank)
	show_modal(title_value, "%s\n\nCorrect: %d  /  Lifelines used: %d\nPersonal best: %s\n\nReady to make another climb?" % [money(bank), correct_count, used.size(), money(best)])
	set_modal_action("Play this mix again", replay, true)
	modal_cancel.text = "Choose themes"
	# The secondary action is handled centrally to avoid accumulating signals.
	modal_cancel.set_meta("return_to_lobby", true)

func replay() -> void:
	back_to_lobby()
	start_game()

func back_to_lobby() -> void:
	generation += 1
	phase = "lobby"
	hide_modal()
	play_ui.hide()
	ui.get_node("Camera").disabled = true
	lobby.show()
	studio.cinematic = true
	studio.shot = "wide"
	studio.set_mood("question")
	refresh_categories()

func show_modal(title_value: String, text_value: String) -> void:
	modal_title.text = title_value
	modal_text.text = text_value
	modal_text.size.y = 245
	modal_button.disabled = false
	modal_button.text = "Back to the question" if phase == "question" else "Back to the studio"
	modal_button.size.x = 708
	modal_cancel.hide()
	modal_cancel.text = "Keep playing"
	modal_cancel.set_meta("return_to_lobby", false)
	modal_action = Callable()
	vote_container.hide()
	modal.show()

func set_modal_action(text_value: String, action: Callable, cancel := false) -> void:
	modal_button.text = text_value
	modal_action = action
	modal_button.size.x = 342 if cancel else 708
	modal_cancel.visible = cancel

func accept_modal() -> void:
	var action := modal_action
	modal_cancel.set_meta("return_to_lobby", false)
	hide_modal()
	if action.is_valid(): action.call()

func hide_modal() -> void:
	modal.hide()
	modal_shade.hide()

func cancel_modal() -> void:
	if bool(modal_cancel.get_meta("return_to_lobby", false)): back_to_lobby()
	else: hide_modal()

func show_votes(votes: Array) -> void:
	modal_text.text = "The audience has spoken. A simulated poll can still be wrong."
	modal_text.size.y = 74
	vote_container.show()
	for i in range(4):
		vote_bars[i].value = votes[i]
		vote_labels[i].text = "%d%%" % int(votes[i])

func _process(delta: float) -> void:
	if timer_label == null: return
	if phase == "question" and timed and not modal.visible:
		time_left = maxf(0.0, time_left - delta)
		if time_left <= 0.0:
			bank = guarantee
			studio.set_mood("wrong")
			finish_run("Time’s up.")
	timer_label.add_theme_font_size_override("font_size", 26 if timed else 18)
	timer_label.text = "%02d SEC" % int(ceil(time_left)) if timed else "CLASSIC / NO TIMER"
	timer_label.add_theme_color_override("font_color", Color("ff977f") if timed and time_left <= 10 else GOLD)
	timer_bar.value = time_left

func use_lifeline(index: int) -> void:
	if phase != "question" or used.has(index) or modal.visible: return
	var q: Dictionary = pack[round_index]
	if index == 0:
		used.append(index)
		lifelines[index].disabled = true
		var wrong := []
		for i in range(4):
			if i != int(q.correct): wrong.append(i)
		wrong.shuffle()
		eliminated = wrong.slice(0, 2)
		for i in eliminated:
			answers[i].text = "%s:    —" % "ABCD"[i]
			answers[i].disabled = true
		if eliminated.has(selected):
			selected = -1
			final_button.disabled = true
		status_label.text = "Two incorrect answers removed. Two possibilities remain."
		return
	var title_value := "Phone a friend" if index == 1 else "Ask the audience"
	show_modal(title_value, "Your simulated friend is thinking…" if index == 1 else "The simulated audience is voting…")
	modal_button.disabled = true
	var suggestion := int(q.correct)
	if randf() < 0.24:
		var choices := []
		for i in range(4):
			if not eliminated.has(i): choices.append(i)
		suggestion = choices.pick_random()
	if index == 1:
		show_modal(title_value + " · practice", "I'd lean toward %s: %s. I could be wrong, so trust your own knowledge too.\n\nLifelines use local simulations and can be wrong." % ["ABCD"[suggestion], q.answers[suggestion]])
	else:
		var votes := [0, 0, 0, 0]
		var choices := []
		for i in range(4):
			if not eliminated.has(i): choices.append(i)
		for i in range(100): votes[suggestion if randf() < 0.48 else choices.pick_random()] += 1
		show_modal(title_value + " · practice", "")
		show_votes(votes)
	used.append(index)
	lifelines[index].disabled = true

func toggle_sound() -> void:
	muted = not muted
	ui.get_node("Sound").text = "Sound: off" if muted else "Sound: on"
	save_preferences()

func play_tone(hz: float, duration: float) -> void:
	if muted: return
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	var frames := int(duration * 22050)
	var data := PackedByteArray()
	data.resize(frames * 2)
	for i in range(frames):
		var t := float(i) / 22050
		var envelope := sin(float(i) / frames * PI) * 0.12
		var sample := int(sin(t * TAU * hz) * envelope * 32767)
		data.encode_s16(i * 2, sample)
	stream.data = data
	audio_player.stream = stream
	audio_player.play()

func _unhandled_key_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo() or not event is InputEventKey: return
	if modal.visible:
		if event.keycode == KEY_ESCAPE and not modal_button.disabled: cancel_modal()
		return
	if event.keycode in [KEY_A, KEY_B, KEY_C, KEY_D]: choose([KEY_A, KEY_B, KEY_C, KEY_D].find(event.keycode))
	if phase == "question" and event.keycode in [KEY_1, KEY_2, KEY_3]: use_lifeline([KEY_1, KEY_2, KEY_3].find(event.keycode))
	if event.keycode == KEY_ENTER:
		if phase == "question": lock_answer()
		elif phase in ["reveal", "finished"]: next_question()
