extends RefCounted

const CATEGORIES = ["Internet & creators", "Gaming", "Music", "Film & TV", "Science & space", "Technology", "Sports", "Culture & food"]

static func build(selected_categories: Array) -> Array:
	if selected_categories.is_empty(): return []
	var order := []
	for category in selected_categories:
		if not CATEGORIES.has(category): return []
		if not order.has(category): order.append(category)
	order.shuffle()
	var all: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/questions.json"))
	var result := []
	for i in range(15):
		var category: String = order[i % order.size()]
		var options := all.filter(func(q): return q.category == category and int(q.difficulty) == i / 5 and not result.has(q))
		if options.is_empty(): return []
		result.append(options.pick_random())
	return result.duplicate(true)
