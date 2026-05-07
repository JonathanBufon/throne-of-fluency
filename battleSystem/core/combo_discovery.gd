extends RefCounted
class_name ComboDiscovery

static func get_available_combos(
	active_agent: TurnBasedAgent,
	agents: Array,
	combos: Array
) -> Array[ComboResource]:
	var available_combos: Array[ComboResource] = []
	for combo in combos:
		var combo_resource := combo as ComboResource
		if combo_resource != null and can_use_combo(combo_resource, active_agent, agents):
			available_combos.append(combo_resource)
	return available_combos

static func can_use_combo(
	combo: ComboResource,
	active_agent: TurnBasedAgent,
	agents: Array
) -> bool:
	if combo == null or active_agent == null:
		return false

	var participants := get_participant_agents(combo, agents)
	if participants.size() != combo.participantNames.size():
		return false
	if not participants.has(active_agent):
		return false

	for i in participants.size():
		var agent := participants[i]
		if agent.character_resource == null or agent.character_resource.is_dead():
			return false
		if not agent.is_action_ready():
			return false
		if not _agent_knows_required_tech(agent, combo, i):
			return false
		if agent.character_resource.currentMana < combo.get_participant_mana_cost(i):
			return false

	return true

static func get_participant_agents(combo: ComboResource, agents: Array) -> Array[TurnBasedAgent]:
	var participants: Array[TurnBasedAgent] = []
	if combo == null:
		return participants

	for participant_name in combo.participantNames:
		var agent := _find_agent_by_character_name(String(participant_name), agents)
		if agent == null:
			participants.clear()
			return participants
		participants.append(agent)

	return participants

static func pay_participant_costs(combo: ComboResource, agents: Array) -> bool:
	var participants := get_participant_agents(combo, agents)
	if participants.size() != combo.participantNames.size():
		return false

	for i in participants.size():
		var agent := participants[i]
		if agent.character_resource == null:
			return false
		if agent.character_resource.currentMana < combo.get_participant_mana_cost(i):
			return false

	for i in participants.size():
		participants[i].character_resource.spend_mana(combo.get_participant_mana_cost(i))

	return true

static func consume_participant_gauges(combo: ComboResource, agents: Array) -> void:
	for agent in get_participant_agents(combo, agents):
		agent.consume_action_gauge()

static func _find_agent_by_character_name(character_name: String, agents: Array) -> TurnBasedAgent:
	for node in agents:
		var agent := node as TurnBasedAgent
		if agent == null or agent.character_resource == null:
			continue
		if agent.character_resource.name == character_name:
			return agent
	return null

static func _agent_knows_required_tech(
	agent: TurnBasedAgent,
	combo: ComboResource,
	participant_index: int
) -> bool:
	if participant_index >= combo.requiredTechs.size():
		return true

	var required_tech := combo.requiredTechs[participant_index] as SkillResource
	if required_tech == null:
		return true

	var known_techs := agent.skills
	if known_techs.is_empty() and agent.character_resource != null:
		known_techs = agent.character_resource.techs

	for tech in known_techs:
		if tech == required_tech:
			return true
		if tech is SkillResource and tech.name == required_tech.name:
			return true

	return false
