extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	game.persist_enabled = false
	root.add_child(game)
	await process_frame
	game.muted = true
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
		await game.lock_answer()
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
	print("PASS: 255 category mixes, selection, characters, timer, votes, replay; full climb, safeguards, wrong answer, walk-away, 50:50")
	quit(0)
