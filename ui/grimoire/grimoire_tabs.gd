extends TabContainer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	tab_changed.connect(_on_tab_changed)
	_connect_prepare_signal()

func refresh() -> void:
	_refresh_all_tabs()

func _connect_prepare_signal() -> void:
	for tab in get_children():
		if tab.has_signal("spell_prepared"):
			tab.connect("spell_prepared", Callable(self, "_on_spell_prepared"))

func _on_tab_changed(_tab: int) -> void:
	_refresh_all_tabs()

func _on_spell_prepared(_recipe: SpellRecipeResource) -> void:
	for tab in get_children():
		if tab.has_signal("spell_prepared"):
			continue
		if tab.has_method("refresh"):
			tab.refresh()

func _refresh_all_tabs() -> void:
	for tab in get_children():
		if tab.has_method("refresh"):
			tab.refresh()
