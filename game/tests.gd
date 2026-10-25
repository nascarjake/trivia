extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	game.persist_enabled = false
	root.add_child(game)
	await process_frame
	game.muted = true
	game.reduced_motion = true
	game.studio.reduced_motion = true
	var bank_builder = load("res://scripts/question_bank.gd")
	for mask in range(1, 256):
		var cats := []
		for i in range(8):
			if mask & (1 << i): cats.append(bank_builder.CATEGORIES[i])
		var questions: Array = bank_builder.build(cats)
		assert(questions.size() == 15)
		var seen := []
		var counts := {}
		for i in range(15):
			var q: Dictionary = questions[i]
			assert(cats.has(q.category))
			assert(int(q.difficulty) == i / 5)
			assert(not seen.has(q.question))
			seen.append(q.question)
			counts[q.category] = counts.get(q.category, 0) + 1
		assert(counts.size() == cats.size())
		assert(counts.values().max() - counts.values().min() <= 1)
	# Twelve full runs from 60 distinct facts per tier in one theme.
	# Synthetic fixtures verify capacity; they are never shipped as real questions.
	var fixtures := []
	var seed: Array = bank_builder.active_bank()
	for d in range(3):
		for j in range(60):
			var q: Dictionary = seed[0].duplicate(true)
			q.id = "fixture-%d-%d" % [d, j]
			q.fact_key = q.id
			q.category = "Gaming"
			q.difficulty = d
			fixtures.append(q)
	var actual_history := []
	var actual_runs := []
	var actual_repeats := 0
	for run_index in range(36):
		var actual: Dictionary = bank_builder.select_pack(bank_builder.CATEGORIES, actual_history, seed)
		assert(actual.questions.size() == 15)
		var recent_facts := []
		for past in actual_runs.slice(maxi(0, actual_runs.size() - 11)): recent_facts.append_array(past)
		var run_facts := []
		for q in actual.questions:
			assert(not recent_facts.has(q.fact_key))
			run_facts.append(q.fact_key)
			actual_history = bank_builder.remember(actual_history, q)
		actual_runs.append(run_facts)
		if run_index < 12: actual_repeats += int(actual.repeats)
	assert(actual_repeats == 0)
	print("Actual bank: first 12 runs / 180 unique facts / zero repeats; rolling 12-run window passes across 36 runs")
	var history := []
	for run_index in range(12):
		var rotation: Dictionary = bank_builder.select_pack(["Gaming"], history, fixtures)
		assert(rotation.questions.size() == 15 and rotation.repeats == 0)
		for q in rotation.questions: history = bank_builder.remember(history, q)
	assert(history.size() == 180)
	var exhausted: Dictionary = bank_builder.select_pack(["Gaming"], history, fixtures)
	assert(exhausted.repeats == 15)
	assert(exhausted.questions.map(func(q): return q.id).has(history[0].id))
	var paraphrase: Dictionary = fixtures[0].duplicate(true)
	paraphrase.id = "same-fact-new-wording"
	fixtures.append(paraphrase)
	var dedup: Dictionary = bank_builder.select_pack(["Gaming"], history, fixtures)
	assert(dedup.repeats == 15)
	assert(not bank_builder.available({"expires_at": "2026-10-25"}, "2026-10-25"))
	var short_pool: Array = fixtures.slice(0, 2)
	assert(bank_builder.select_pack(["Gaming"], [], short_pool).questions.is_empty())
	# Save/reload keeps older preference fields and history; uses a disposable file.
	game.preference_path = "/tmp/trivia-preferences-test.cfg"
	game.persist_enabled = true
	var legacy := ConfigFile.new()
	legacy.set_value("legacy", "keep", 42)
	legacy.save(game.preference_path)
	game.recent_questions = history
	game.best = 32000
	game.save_preferences()
	game.recent_questions = []
	game.best = 0
	game.load_preferences()
	assert(game.recent_questions.size() == 180 and game.best == 32000)
	legacy.load(game.preference_path)
	assert(legacy.get_value("legacy", "keep") == 42)
	DirAccess.remove_absolute(game.preference_path)
	game.persist_enabled = false
	game.recent_questions = []
	game.set_categories([])
	assert(game.start_button.disabled)
	await game.start_game()
	assert(game.phase == "lobby")
	game.set_categories(["Gaming", "Music"])
	game.select_character(2)
	assert(game.studio.character_index == 2 and game.studio.people.size() == 2)
	await game.start_game()
	assert(game.pack.size() == 15)
	assert(game.phase == "question")
	# A final answer cannot be submitted without choosing.
	game.lock_answer()
	assert(game.phase == "question")
	# 50:50 always removes two wrong answers and can only be used once.
	game.use_lifeline(0)
	assert(game.eliminated.size() == 2)
	assert(not game.eliminated.has(int(game.pack[0].correct)))
	game.use_lifeline(0)
	assert(game.used.size() == 1)
	# Complete all 15 questions, including both guaranteed checkpoints.
	for i in range(15):
		game.choose(int(game.pack[i].correct))
		if i == 0:
			game.lock_answer()
			assert(game.phase == "locked" and game.final_button.disabled)
			var locked_choice: int = game.selected
			game.choose((locked_choice + 1) % 4)
			assert(game.selected == locked_choice)
			assert(game.studio.stage_state == "locked")
			await create_timer(0.20).timeout
			assert(game.phase == "reveal" and game.source_panel.visible)
			assert(game.answers[locked_choice].get_node("Feedback").text == "[correct]")
		else: await game.lock_answer()
		assert(game.bank == game.MONEY[i])
		if i == 4: assert(game.guarantee == 1000)
		if i == 9: assert(game.guarantee == 32000)
		if i < 14: game.next_question()
	assert(game.phase == "finished")
	assert(game.bank == 1000000)
	# Failed answer after a checkpoint pays the guarantee, not current bank.
	game.back_to_lobby()
	await game.start_game()
	game.round_index = 6
	game.bank = 2000
	game.guarantee = 1000
	game.load_question()
	game.choose((int(game.pack[6].correct) + 1) % 4)
	await game.lock_answer()
	assert(game.phase == "finished" and game.bank == 1000)
	# Walk-away keeps the bank.
	game.back_to_lobby()
	await game.start_game()
	game.bank = 4000
	game.walk_away()
	assert(game.phase == "question" and game.modal.visible)
	game.cancel_modal()
	assert(game.phase == "question" and not game.modal.visible)
	game.walk_away()
	game.accept_modal()
	assert(game.phase == "finished" and game.bank == 4000)
	# Replay keeps themes and resets the run, including used lifelines.
	game.accept_modal()
	assert(game.phase == "question" and game.bank == 0 and game.used.is_empty())
	assert(game.selected_categories == ["Gaming", "Music"])
	# Modal lifelines pause the clock and eliminated answers receive no votes.
	game.timed = true
	game.time_left = 5.0
	game.use_lifeline(0)
	game.use_lifeline(2)
	assert(game.vote_container.visible)
	var total := 0
	for i in range(4):
		total += int(game.vote_bars[i].value)
		if game.eliminated.has(i): assert(game.vote_bars[i].value == 0)
	assert(total == 100)
	game._process(6.0)
	assert(game.phase == "question" and game.time_left == 5.0)
	game.hide_modal()
	game.guarantee = 1000
	game._process(6.0)
	assert(game.phase == "finished" and game.bank == 1000)
	game.cancel_modal()
	assert(game.phase == "lobby")
	for answer in game.answers:
		assert(answer.position.x + answer.size.x <= 1260)
		assert(answer.position.y + answer.size.y <= 821)
		assert(answer.get_theme_font_size("font_size") >= 17)
	for q in seed:
		for choice in q.answers:
			var width: float = game.answers[0].get_theme_font("font").get_string_size("D:    " + str(choice), HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x
			assert(width < 528)
	assert(game.studio.spots.size() == 2)
	print("PASS: 12-run rotation, exhaustion, canonical dedup, expiry, save/reload, reveal lock, stage lights, layout;  255 category mixes, selection, characters, timer, votes, replay; full climb, safeguards, wrong answer, walk-away, 50:50")
	quit(0)
