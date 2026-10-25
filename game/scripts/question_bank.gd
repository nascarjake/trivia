extends RefCounted

const CATEGORIES = ["Internet & creators", "Gaming", "Music", "Film & TV", "Science & space", "Technology", "Sports", "Culture & food"]
const HISTORY_LIMIT = 10080
const RECENT_WINDOW = 180

static func active_bank() -> Array:
	var value = JSON.parse_string(FileAccess.get_file_as_string("res://data/questions.json"))
	return value if value is Array else []

static func available(q: Dictionary, today: String) -> bool:
	return str(q.get("expires_at", "")).is_empty() or str(q.expires_at) > today

static func build(selected_categories: Array, recent: Array = [], bank: Array = []) -> Array:
	return select_pack(selected_categories, recent, bank).questions

static func select_pack(selected_categories: Array, recent: Array = [], bank: Array = []) -> Dictionary:
	var failure := {"questions": [], "repeats": 0, "error": "Not enough distinct facts for this mix and difficulty."}
	if selected_categories.is_empty(): return failure
	var order := []
	for category in selected_categories:
		if not CATEGORIES.has(category): return failure
		if not order.has(category): order.append(category)
	order.shuffle()
	var all := active_bank() if bank.is_empty() else bank
	var today := Time.get_date_string_from_system(true)
	var seen := {}
	for i in range(recent.size()):
		var entry = recent[i]
		if entry is Dictionary:
			seen[str(entry.get("id", ""))] = i + 1
			seen[str(entry.get("fact_key", ""))] = i + 1
	var cutoff := maxi(0, recent.size() - RECENT_WINDOW)
	var cells := {}
	for q in all:
		if not q is Dictionary or not available(q, today): continue
		var key: String = str(q.category) + str(int(q.difficulty))
		if not cells.has(key): cells[key] = []
		cells[key].append(q)
	var result := []
	var used_ids := {}
	var used_facts := {}
	var repeats := 0
	var category_counts := {}
	var tier_counts := {}
	for category in order: category_counts[category] = 0
	for i in range(15):
		var difficulty := i / 5
		var category_options := []
		var lowest_count := 16
		for category in order:
			var options := []
			for q in cells.get(category + str(difficulty), []):
				if used_ids.has(q.id) or used_facts.has(q.fact_key): continue
				options.append(q)
			if options.is_empty(): continue
			var count: int = category_counts[category]
			if count < lowest_count:
				lowest_count = count
				category_options.clear()
			if count == lowest_count:
				var fresh := 0
				var oldest_score := 2147483647
				for q in options:
					var rank := maxi(int(seen.get(q.id, 0)), int(seen.get(q.fact_key, 0)))
					if rank <= cutoff: fresh += 1
					oldest_score = mini(oldest_score, rank)
				category_options.append({"category": category, "options": options, "fresh": fresh, "oldest": oldest_score, "tier_count": tier_counts.get(category + str(difficulty), 0)})
		if category_options.is_empty(): return failure
		category_options.shuffle()
		category_options.sort_custom(func(a, b):
			if a.tier_count != b.tier_count: return a.tier_count < b.tier_count
			if a.fresh != b.fresh: return a.fresh > b.fresh
			return a.oldest < b.oldest)
		var bucket: Dictionary = category_options[0]
		var options: Array = bucket.options
		options.shuffle()
		var chosen: Dictionary = options[0]
		var oldest := 2147483647
		for q in options:
			var age := maxi(int(seen.get(q.id, 0)), int(seen.get(q.fact_key, 0)))
			if age < oldest:
				oldest = age
				chosen = q
		if oldest > cutoff: repeats += 1
		category_counts[chosen.category] += 1
		var tier_key: String = chosen.category + str(difficulty)
		tier_counts[tier_key] = int(tier_counts.get(tier_key, 0)) + 1
		result.append(chosen)
		used_ids[chosen.id] = true
		used_facts[chosen.fact_key] = true
	if category_counts.values().min() == 0 or category_counts.values().max() - category_counts.values().min() > 1: return failure
	return {"questions": result.duplicate(true), "repeats": repeats, "error": ""}

static func remember(recent: Array, q: Dictionary) -> Array:
	var result := recent.filter(func(e): return e is Dictionary and e.get("id") != q.id and e.get("fact_key") != q.fact_key)
	result.append({"id": q.id, "fact_key": q.fact_key})
	return result.slice(maxi(0, result.size() - HISTORY_LIMIT))
