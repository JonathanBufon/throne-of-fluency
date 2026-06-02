---
description: "Task list for grimoire feature implementation"
---

# Tasks: Grimório — Coletar Palavras, Preparar e Lançar Magias

**Input**: Design documents from `/specs/001-grimoire-words-spells/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md (all present)

**Tests**: Esta spec não solicita testes formais. O projeto não tem runner automatizado (CLAUDE.md). Validação acontece via `quickstart.md` (manual no editor) e smoke headless. Não são geradas tasks de teste explícitas — checkpoints referenciam seções do `quickstart.md`.

**Organization**: Tasks agrupadas por user story. Cada story é entregável independentemente.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Pode rodar em paralelo (arquivos diferentes, sem dependências pendentes)
- **[Story]**: US1/US2/US3/US4 (mapeia para user story na spec.md)
- Caminhos relativos à raiz do repositório

## Path Conventions (Godot single-project)

- Resources GDScript: `battleSystem/resources/`
- Cenas e scripts de UI overworld: `ui/grimoire/`, `ui/hud/`
- Cenas e scripts de UI de batalha: `battleSystem/ui/`
- Data resources (`.tres`): `battleSystem/data/`
- Cena de batalha: `battleSystem/battle_scene.gd`
- Autoload de estado: `world/cripta/game_data.gd`

---

## Phase 1: Setup

**Purpose**: Garantir baseline limpo antes de codar.

- [ ] T001 Rodar smoke headless do projeto atual para snapshot pré-mudanças: `godot --headless --path . --quit` e confirmar exit code 0
- [ ] T002 Verificar que não há conflito com a tecla `G`: `grep -n 'KEY_G\b\|"G"' project.godot` (esperar zero matches)

---

## Phase 2: Foundational

**Purpose**: Sem prerequisitos compartilhados por **todas** as user stories. US1 e US3 são totalmente independentes da nova UI; US2 e US4 compartilham infra que vive no escopo da Phase 5 (US2) — US4 depende dela.

**Checkpoint**: nenhuma task aqui. Phase 3 (US1), Phase 4 (US3) e Phase 5 (US2) podem começar em paralelo após Setup.

---

## Phase 3: User Story 1 — Ganhar palavra ao vencer batalha (Priority: P1) 🎯 MVP

**Goal**: Derrotar um inimigo com `word_drops` configurado adiciona a(s) palavra(s) a `GameData.known_words` e anuncia na tela de vitória inline.

**Independent Test**: Quickstart §2.1 + §2.2 — configurar `word_drops` em um reward, vencer a batalha, confirmar linha "Palavras aprendidas: …" inline + persistência em save.json.

### Implementation for User Story 1

- [ ] T003 [US1] Adicionar `@export var word_drops: Array[WordResource] = []` em `battleSystem/resources/battle_reward_resource.gd` (sem `wordDropQuantities`; ver `contracts/battle_reward_word_drops.md`)
- [ ] T004 [US1] Estender `grant_battle_rewards` em `world/cripta/game_data.gd`: inicializar `summary["new_words"] = []`; após o loop de `drops`, iterar `reward.word_drops` e chamar `discover_word(word)`; quando retornar `true`, append `word.text_en` em `summary["new_words"]` (ver `contracts/game_data_api.md`)
- [ ] T005 [US1] Em `battleSystem/battle_scene.gd._format_victory_message`, adicionar bloco "Palavras aprendidas: …" após o loop de drops e antes do bloco de `level_results` (ver `contracts/battle_reward_word_drops.md` para o snippet exato; texto em PT-BR)
- [ ] T006 [P] [US1] Configurar `word_drops` em `battleSystem/data/rewards/orc_grunt_reward.tres` com `[ fire.tres, ball.tres ]` para validação (paralelizável com T003-T005 — arquivo de dados independente; editor pode reclamar até T003 estar mergeado, deixar como última ação do bloco)

**Checkpoint**: Quickstart §2.2 deve passar — vencer o encontro de teste mostra "Palavras aprendidas: fire, ball" inline e fechar/abrir o jogo preserva as palavras (§2.6, parte 1).

---

## Phase 4: User Story 3 — Cast em batalha (Priority: P1)

**Goal**: Botão `Magia` no menu de comandos lista as magias em `GameData.prepared_spells` e executa a `result_skill` pela pipeline normal de `SkillResource`.

**Independent Test**: Quickstart §2.5 — com `prepared_spells` populado manualmente (via debugger ou save preparado), abrir batalha, selecionar Magia → escolher magia → confirmar dano e consumo de MP.

**Nota**: Independente de US1, US2 e US4. Pode rodar em paralelo com Phase 3.

### Implementation for User Story 3

- [ ] T007 [US3] Adicionar `Button` chamado `MagicButton` em `battleSystem/ui/command_menu.tscn` dentro de `%MainCommands`, posicionado **entre** `SkillsButton` e `ComboButton` (FR-020). Texto: "Magia". Manter `unique_name_in_owner`
- [ ] T008 [US3] Em `battleSystem/ui/command_menu.gd`: adicionar `@onready var magic_button: Button = %MagicButton`, declarar `var _current_spells: Array[SkillResource] = []`, conectar `magic_button.pressed` em `_ready`, implementar `_set_spell_options()` (popula `_current_spells` a partir de `GameData.prepared_spells.map(...)`), chamar `_set_spell_options()` em `_set_command_options`, implementar `_on_magic_button_pressed` espelhando `_on_skill_button_pressed` (ver `contracts/command_menu_magia.md`)
- [ ] T009 [US3] Verificar que `_can_character_use_skill` continua tratando MP corretamente para as magias preparadas (são `SkillResource`, deve funcionar sem mudança); se `prepared_spells` estiver vazio, `magic_button.disabled = true` (FR-023)

**Checkpoint**: Quickstart §2.5 deve passar (forçando uma magia em `prepared_spells` via debugger ou save de teste). Edge case §3.5 (MP insuficiente) deve mostrar o botão da magia como `disabled` no submenu.

---

## Phase 5: User Story 2 — Preparar magia (Priority: P1)

**Goal**: Abrir o grimório no overworld (tecla G como caminho mínimo), selecionar 2-3 palavras conhecidas na aba Preparar, confirmar, e adicionar a magia correspondente em `GameData.prepared_spells`.

**Independent Test**: Quickstart §2.3 (parte: tecla G) + §2.4 (aba Preparar) — com `known_words` populado, abrir grimório via G, navegar para Preparar, selecionar palavras, confirmar feedback inline.

**Nota**: Esta phase introduz a infra do grimório (autoload + cena raiz). US4 estende essa infra com as outras abas e os outros caminhos de acesso.

### Implementation for User Story 2

- [ ] T010 [US2] Em `project.godot`: registrar autoload `WorldGrimoire = "*res://ui/grimoire/world_grimoire.gd"` (depois de `BattleTransition`) e adicionar input action `grimoire` com binding `KEY_G` (ver `contracts/grimoire_scene.md`)
- [ ] T011 [P] [US2] Criar `ui/grimoire/world_grimoire.gd` — `extends CanvasLayer`, espelhando o padrão de `ui/hud/world_inventory.gd`: `layer = 20`, `process_mode = PROCESS_MODE_ALWAYS`, `_unhandled_input` consome `is_action_pressed("grimoire")` e `ui_cancel` quando aberto, `_can_open()` com mesmas constantes (`OVERWORLD_PATH_PREFIX`, `EXCLUDED_PATH_FRAGMENTS`), métodos públicos `open()`/`close()`/`toggle()`/`is_open()` (ver `contracts/grimoire_scene.md`)
- [ ] T012 [P] [US2] Criar `ui/grimoire/world_grimoire.tscn` — raiz `CanvasLayer` com filho `PanelContainer` → `TabContainer` (chamado `GrimoireTabs`) com 3 abas placeholder vazias chamadas `Words`, `Recipes`, `Prepare` (T015-T017 e T019-T020 preenchem)
- [ ] T013 [US2] Criar `ui/grimoire/grimoire_tab_prepare.tscn` — `Control` com `VBoxContainer`: lista de palavras (gerada em runtime como `ToggleButton`s), `Button` chamado `PrepareButton` com texto "Preparar", `Label` chamado `%FeedbackLabel`, `%EmptyLabel` para estado sem palavras
- [ ] T014 [US2] Implementar `ui/grimoire/grimoire_tab_prepare.gd`: em `_ready` ou `refresh()`, listar `GameData.known_words` como toggles (máx 3 selecionáveis); `PrepareButton.pressed`: coletar selecionadas → validar 2-3 palavras → chamar `GameData.find_recipe_for_words(selected)` → ramificar nos casos `<2-3 palavras` / `recipe == null` / `is_spell_prepared` / sucesso, atualizando `%FeedbackLabel` com as strings PT-BR definidas em R7 (research.md); limpar `%FeedbackLabel` no signal `toggled` de cada toggle; estado vazio desabilita `PrepareButton` e mostra `%EmptyLabel` "Aprenda palavras antes de preparar magias." (FR-019a)
- [ ] T015 [US2] Conectar `grimoire_tab_prepare.tscn` como a aba `Prepare` em `world_grimoire.tscn` (instanciar como filho da tab). Garantir que `world_grimoire.open()` chama `refresh()` na aba ativa
- [ ] T016 [US2] Validar fluxo: abrir editor, rodar `shroom-lands.tscn` (ou cena de mundo), apertar G → grimório abre com tree pausado; apertar G de novo → fecha (Quickstart §2.3 parte 1+2)

**Checkpoint**: Quickstart §2.3 (parte tecla G) + §2.4 (aba Preparar) devem passar. Edge cases §3.2 (catálogo vazio Preparar), §3.3 (não abre durante diálogo) e §3.4 (não abre durante batalha) também.

---

## Phase 6: User Story 4 — Consultar palavras e receitas conhecidas (Priority: P2)

**Goal**: Completar as 3 abas do grimório (Palavras, Receitas, Preparar — esta última já vinda de US2) e expor os 3 caminhos de acesso (tecla G + tab no inventário + botão na HUD).

**Independent Test**: Quickstart §2.3 (todos os 3 caminhos) + §2.4 (abas Palavras/Receitas com filtragem) + edge cases §3.2 e §3.6.

**Nota**: Depende de Phase 5 (US2) ter criado a cena raiz do grimório, o autoload e a action input.

### Implementation for User Story 4

- [ ] T017 [P] [US4] Criar `ui/grimoire/grimoire_tab_words.tscn` — `Control` com `VBoxContainer` (`%WordList`) + `%EmptyLabel`. Sem script complexo, ou um script mínimo que renderiza
- [ ] T018 [P] [US4] Implementar `ui/grimoire/grimoire_tab_words.gd`: `refresh()` itera `GameData.known_words` e cria `Label` por palavra com formato "text_en — text_pt (tipo)" usando `WordResource.part_of_speech` quando ≠ OTHER; estado vazio mostra `%EmptyLabel` com "Você ainda não conhece nenhuma palavra. Vença batalhas para aprender." (FR-019a)
- [ ] T019 [P] [US4] Criar `ui/grimoire/grimoire_tab_recipes.tscn` — `Control` com `VBoxContainer` (`%RecipeList`) + `%EmptyLabel`
- [ ] T020 [P] [US4] Implementar `ui/grimoire/grimoire_tab_recipes.gd`: `refresh()` itera `GameData.ALL_SPELL_RECIPES`, filtra por `recipe.get_known_word_count(GameData.known_words) > 0` (FR-017), renderiza cada receita como `Label` com palavras conhecidas visíveis e desconhecidas mascaradas como `"???"` (FR-016), marca "Preparada ✓" se `GameData.is_spell_prepared(recipe)` (FR-018); estado vazio: "Sem palavras, sem receitas conhecidas."
- [ ] T021 [US4] Conectar `grimoire_tab_words.tscn` e `grimoire_tab_recipes.tscn` como filhos das tabs `Words` e `Recipes` em `world_grimoire.tscn`; em `world_grimoire.gd.open()`, chamar `refresh()` em todas as abas antes de mostrar
- [ ] T022 [US4] Modificar `ui/hud/world_inventory.tscn`: trocar layout raiz para `TabContainer` com 2 tabs ("Itens" mantém conteúdo atual; "Grimório" recebe a cena de tabs do grimório). Em `world_inventory.gd._ready`: instanciar a cena de tabs e adicionar como filho da tab "Grimório". Reutilizar a mesma cena base do grimório standalone — instanciar apenas o `TabContainer{Words, Recipes, Prepare}` (extrair como `grimoire_tabs.tscn` se necessário, conforme R2 em research.md)
- [ ] T023 [US4] Adicionar botão "Grimório" em `ui/hud/world_hud.tscn` e handler em `world_hud.gd` que chama `WorldGrimoire.open()`. Posicionar onde fizer sentido visual (próximo ao indicador de gold ou em uma barra de ações)
- [ ] T024 [US4] Validar todos os 3 caminhos de acesso (Quickstart §2.3) e o filtro de receitas parcial (Quickstart §3.6)

**Checkpoint**: Todos os critérios de aceitação de US4 (spec §"User Story 4") devem passar. Edge cases §3.1 (save corrompido), §3.2 (catálogo vazio em todas as 3 abas) e §3.6 (receita parcial com `???`) também.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Validação end-to-end e tarefas que tocam todas as user stories.

- [ ] T025 [P] Rodar smoke headless: `godot --headless --path . --quit` (exit 0, sem warnings novos)
- [ ] T026 [P] Rodar cena de teste: `godot --headless --path . --scene res://battleSystem/tests/test_battle_scene.tscn --quit-after 30` (sem crash, sem erros novos)
- [ ] T027 Executar Quickstart §2 (golden path completo): vencer batalha com word_drops → abrir grimório pelos 3 caminhos → preparar magia → cast em batalha → fechar/abrir jogo e confirmar persistência
- [ ] T028 [P] Executar Quickstart §3 (edge cases): save corrompido, catálogo vazio, conflito com diálogo, conflito com batalha, MP insuficiente, receita parcial
- [ ] T029 Confirmar manualmente no editor que abertura/fechamento do grimório é imperceptível (SC-006: ≤200 ms); se houver lag, investigar `_unhandled_input` ou pause
- [ ] T030 Verificar que `prepared_spells` aparece corretamente em batalha sem reabrir o jogo (SC-007 implícito); confirmar que botão Magia vazio não trava o turno

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Sem dependências
- **Foundational (Phase 2)**: vazio nesta feature
- **User Stories (Phases 3-6)**:
  - US1 (Phase 3) e US3 (Phase 4): podem rodar em paralelo, independentes entre si e de US2/US4
  - US2 (Phase 5): independente de US1/US3, mas é prerequisito para US4
  - US4 (Phase 6): depende de US2 (cena raiz, autoload, action)
- **Polish (Phase 7)**: depende de US1, US2, US3, US4 completas

### User Story Dependencies

```text
Setup → US1 ─┐
       └→ US3 ─┤
       └→ US2 ─┴→ US4 → Polish
```

### Within Each User Story

- T003 → T004 → T005 dentro de US1 (resource definida antes de GameData usá-la antes de battle_scene exibir)
- T010 antes de T011/T012 dentro de US2 (autoload precisa estar registrado para a cena rodar como autoload)
- T013-T014 (Prepare tab) antes de T015 (conectar à cena raiz)
- US4: T017-T020 (4 arquivos de tab) podem rodar em paralelo; T021 depende de todos; T022/T023 podem rodar em paralelo após T021

### Parallel Opportunities

- **Cross-story**: US1 (Phase 3) e US3 (Phase 4) totalmente paralelas — sem arquivos compartilhados.
- **US1 interno**: T006 (config de .tres) pode rodar logo após T003 (campo definido).
- **US2 interno**: T011 e T012 [P] (script vs cena) podem ser feitos em paralelo após T010.
- **US4 interno**: T017+T018 (Words tab) e T019+T020 (Recipes tab) são pares independentes; T017/T019 [P] em paralelo, T018/T020 [P] em paralelo.
- **Polish**: T025, T026 e T028 [P] podem rodar em paralelo (smoke + edge cases não compartilham estado).

---

## Parallel Example: User Story 4 (depois de T021)

```bash
# Após cena raiz com 3 tabs prontas:
Task: "T022 Modificar world_inventory.tscn/.gd para TabContainer + embed grimório"
Task: "T023 Adicionar botão Grimório à world_hud.tscn/.gd"
# Ambas tocam HUD/inventário, arquivos diferentes — paralelas.
```

## Parallel Example: User Stories 1 e 3

```bash
# Após Phase 1 (Setup), Developer A e Developer B podem trabalhar em paralelo:
Developer A: T003-T006 (US1 — battle_reward + game_data + battle_scene)
Developer B: T007-T009 (US3 — command_menu)
# Zero arquivos compartilhados.
```

---

## Implementation Strategy

### MVP First (US1 + US3, depois US2)

Como há 3 stories P1, o MVP **real** do grimório só fica funcional com as 3:
- US1 sozinha: jogador ganha palavras mas não pode fazer nada com elas.
- US3 sozinha: botão Magia existe mas lista vazia.
- US2 sozinha: dá pra preparar magia mas sem source de palavras (sem US1) e sem como usar (sem US3).

Estratégia recomendada:
1. Phase 1 (Setup): T001-T002
2. **Phase 3 (US1) e Phase 4 (US3) em paralelo** (developers diferentes, ou serial se solo): toda a parte "back-end" da feature
3. Phase 5 (US2): UI mínima funcional (tecla G + Prepare tab)
4. **STOP & VALIDATE**: Quickstart §2 completo (golden path) com pelo menos um caminho de acesso
5. Phase 6 (US4): polish da UI (outras abas, outros caminhos de acesso, inventory embed)
6. Phase 7 (Polish): validação completa

### Incremental Delivery

1. T001-T002 (Setup) → baseline
2. US1 + US3 → grimório "headless" (dados + cast funcional, sem UI ainda) — útil pra QA backend
3. US2 → UI mínima usável — pode demo internamente
4. US4 → UI completa — pronto para PR
5. Polish → smoke + edge cases → merge

### Sugestão de granularidade de commit

Um commit por phase é razoável (4 commits no total dentro desta feature, fora os de Setup/Polish). Memória do projeto pede conventional commits PT-BR — exemplos:

- `feat(grimoire): drop de palavra em vitória (US1, refs #45)`
- `feat(grimoire): comando Magia em batalha (US3, refs #45)`
- `feat(grimoire): autoload + aba Preparar (US2, refs #45)`
- `feat(grimoire): abas Palavras/Receitas + HUD + tab inventário (US4, refs #45)`
- `chore(grimoire): smoke + edge case validation (polish, refs #45)`

---

## Notes

- `[P]` = arquivos diferentes, sem dependências pendentes.
- `[Story]` = traceabilidade para spec.md.
- Cada user story é independentemente entregável e testável (com a ressalva da dependência US2 → US4).
- Sem runner de teste automatizado: validação manual via `quickstart.md`.
- Commit ao fim de cada user story (não por task), seguindo a granularidade do CLAUDE.md (commits semânticos PT-BR).
- Memória do projeto: UI em PT-BR, fonte default do Godot na gameplay (CuteFantasy apenas decorativa).
- Não renomear nodes/cenas sem necessidade; preservar APIs existentes de `CharacterResource`/`SkillResource`/`GameData`.
- Não remover `battleSystem/tests/test_battle_scene.tscn`.
