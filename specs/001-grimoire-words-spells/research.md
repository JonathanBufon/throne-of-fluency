# Phase 0 — Research

**Feature**: Grimório — Coletar Palavras, Preparar e Lançar Magias
**Date**: 2026-06-02

Esta fase resolve as decisões técnicas levantadas pela spec e pelas clarifications. Nenhum `NEEDS CLARIFICATION` permaneceu após `/speckit-clarify` — esta pesquisa documenta as escolhas de implementação para que `/speckit-tasks` possa decompor sem ambiguidade.

---

## R1 — Padrão de autoload + toggle do `WorldGrimoire`

**Decisão**: Espelhar o `WorldInventory` (`ui/hud/world_inventory.gd`) — `CanvasLayer` no topo (`layer = 20`), `process_mode = PROCESS_MODE_ALWAYS`, `_unhandled_input` consome a action `grimoire` para toggle, `get_tree().paused = true` no open e `false` no close, `_can_open()` gating por `OVERWORLD_PATH_PREFIX = "res://world/"` excluindo `tittle_screen`/`troca_fase`.

**Rationale**: O inventário já resolveu exatamente este problema (toggle, pause, gate por cena). Copiar o padrão garante consistência de UX (mesma sensação ao abrir/fechar) e mantém a manutenção simples — qualquer mudança de regra de overworld vale para os dois.

**Alternativas consideradas**:
- *Cena instanciada sob demanda em cada world scene*: descartado — duplicaria a lógica de gate por scene em cada chamada e quebraria o ciclo de pause.
- *Bottom sheet/UI dentro da player camera*: descartado — quebraria pause-tree e poderia conflitar com o overlay de diálogos.

---

## R2 — Tab do inventário embute a cena do `WorldGrimoire` (Clarification Q1)

**Decisão**: `WorldInventory` passa a usar `TabContainer` (Itens | Grimório). A tab "Grimório" tem como filho um `Control` que **instancia em runtime** a mesma `PackedScene` que o autoload `WorldGrimoire` carrega. O nó instanciado dentro do inventário roda em modo "embed" (sem o `CanvasLayer` raiz, sem `_unhandled_input` próprio — apenas o body de abas).

Implementação concreta:
- `world_grimoire.tscn` tem como raiz `CanvasLayer > PanelContainer > TabContainer{Words, Recipes, Prepare}`.
- A cena embed-friendly é o **`PanelContainer`** (filho da raiz). O autoload usa a cena completa; a tab do inventário instancia só o `PanelContainer` (ou usa `pack_scene` separada com a mesma `TabContainer` filha).
- Mais simples: extrair `TabContainer{Words, Recipes, Prepare}` como cena própria (`grimoire_tabs.tscn`) e reaproveitar dentro do `world_grimoire.tscn` standalone E dentro da tab do inventário.

**Rationale**: Atende Q1 sem duplicar UI. Uma única implementação visual das 3 abas; standalone e embedded variam só no chrome (CanvasLayer + Panel × tab pai).

**Alternativas consideradas**:
- *Duas cenas independentes com layout copiado*: rejeitado pelo próprio Q1 (manutenção dobra).
- *Tab do inventário só lê dados (sem reaproveitar UI)*: rejeitado — exigiria reimplementar 3 listas. Sem ganho.
- *Tecla G abre o inventário com tab Grimório pré-selecionada*: descartado em Q1 (opção C) — manteria menos código, mas atrapalha jogadores que só querem ver palavras (não querem o painel de itens junto).

---

## R3 — Extensão de `BattleRewardResource` com `word_drops` (User Story 1)

**Decisão**: Adicionar campo `@export var word_drops: Array[WordResource] = []` ao `battle_reward_resource.gd`. Sem campo de quantidade — palavra é booleana (sabe/não sabe).

Modificação em `GameData.grant_battle_rewards`: adicionar bloco análogo ao de `drops` (item) que itera `reward.word_drops` e chama `discover_word(word)`, coletando em `summary["new_words"]: Array[String]` os `text_en` recém-descobertos (somente os que retornaram `true` em `discover_word`).

**Rationale**: Mantém consistência com a estrutura de `drops` (item) já existente. `discover_word` já retorna `bool` para distinguir "já sabia" de "aprendeu agora" — basta usar. O array `new_words` no summary é o que a tela de vitória vai consumir.

**Alternativas consideradas**:
- *Adicionar quantidade (`wordDropQuantities`)*: rejeitado — palavra não é quantitativa.
- *Centralizar o anúncio dentro de `discover_word`*: rejeitado — viola separação de camadas (GameData não deveria emitir UI). Manter via summary.
- *Signal `word_discovered`*: pensado, mas a tela de vitória já lê o summary síncrono retornado por `grant_battle_rewards`. Signal seria útil pra HUD passiva (futuro), não pra esta spec.

---

## R4 — Anúncio inline na tela de vitória (Clarification Q2)

**Decisão**: Em `battle_scene.gd._format_victory_message`, depois do bloco de drops de item e antes do bloco de level results, adicionar:

```gdscript
var new_words := reward_summary.get("new_words", []) as Array
if not new_words.is_empty():
    lines.append("Palavras aprendidas: %s" % ", ".join(PackedStringArray(new_words)))
```

Mesma string `_show_result_message` já existente — sem cena nova, sem pop-up extra, sem confirmação adicional.

**Rationale**: Reusa o pipeline atual de mensagem de resultado. Linha única adicional preserva ritmo de combate (Clarification Q2 opção B).

**Observação**: O texto atual `lines: Array[String] = ["Victory"]` está em inglês. Mantenho fora do escopo desta spec (memória do usuário pede UI em PT-BR, mas mudar "Victory" para "Vitória" é mudança não-relacionada). A nova linha "Palavras aprendidas: …" entra já em PT-BR conforme regra.

**Alternativas consideradas**:
- *Pop-up dedicado bloqueante*: descartado em Q2 (A) — passo extra de confirmação.
- *Toast efêmero*: descartado em Q2 (C) — reduz ênfase pedagógica.

---

## R5 — Cast em batalha via novo comando `Magia` (User Story 3)

**Decisão**: Em `command_menu.gd`/`.tscn`:
- Adicionar `Button` chamado `MagicButton` em `%MainCommands`, posicionado **entre** `SkillsButton` e `ComboButton` (per FR-020).
- Novo array de estado: `_current_spells: Array[SkillResource] = []`.
- `_set_command_options` agora calcula spells preparadas: `_current_spells = GameData.prepared_spells.map(func(r): return r.result_skill).filter(func(s): return s != null)`.
- Novo handler `_on_magic_button_pressed`: chama `_populate_command_list(_current_spells)` e mostra `skill_container` — mesma pipeline que Skills/Combo/Item.
- Estado vazio (FR-023): se `_current_spells.is_empty()`, `magic_button.disabled = true` (não esconder, manter a posição estável no menu — coerente com `skills_button` que esconde quando `_current_skills.is_empty()`; revisar com usuário se preferir hide).

**Rationale**: Skills/Combo/Item já passam por `_populate_command_list` e `_on_command_pressed`. Magias preparadas são, no fim, `SkillResource` (`recipe.result_skill`). Reaproveitar = zero pipeline nova. MP check, animação, targeting — tudo já tratado por `_can_character_use_skill`/`_on_command_pressed`.

**Alternativas consideradas**:
- *Submenu separado com layout próprio*: rejeitado — duplica `_populate_command_list`.
- *Magia como subitem dentro de Skills*: rejeitado — pedagogia do grimório pede destaque visual (FR-020 explícito).
- *Esconder botão quando vazio (em vez de disabled)*: alternativa válida; manter `disabled` por consistência com o padrão atual de `skills_button` quando há skills mas todas sem MP — usuário pode flipar em revisão.

---

## R6 — Aba Receitas: visibilidade e mascaramento (FR-016, FR-017)

**Decisão**: Para cada `recipe` em `GameData.ALL_SPELL_RECIPES`:
- Conhecimento parcial = `recipe.get_known_word_count(GameData.known_words) > 0`.
- Se 0: receita não entra na lista (FR-017).
- Se ≥1 mas < total: receita entra, palavras desconhecidas viram literal `"???"` (FR-016).
- Se = total: receita entra com todas as palavras visíveis e indicador visual extra:
  - "Preparada ✓" se `GameData.is_spell_prepared(recipe)` (FR-018).
  - "Disponível" caso contrário.

Renderização: cada receita = uma `Label` (ou `HBoxContainer` com `Label` por palavra). Estilo simples; sem ícones nesta fase (ícones em `WordResource.icon` ficam para iteração futura — não é P1).

**Rationale**: `is_fully_known` e `get_known_word_count` já existem em `SpellRecipeResource` (foundation). Plug direto.

**Alternativas consideradas**:
- *Mostrar todas as receitas sempre (sem oculta)*: rejeitado — spoiler, contraria FR-017.
- *Buscar receitas dinâmicas/generativas*: explicit non-objective.

---

## R7 — Aba Preparar: seleção de palavras + feedback inline (Clarification Q3, FR-006-011)

**Decisão**: Layout:
- Lista lateral de palavras conhecidas (checkboxes ou `Button`s toggle, max 3 selecionáveis).
- Botão `Preparar`.
- `Label %FeedbackLabel` abaixo do botão.

Fluxo no `pressed` do Preparar:
1. Coletar `selected: Array[WordResource]`.
2. Se `selected.size() < 2 or selected.size() > 3`: feedback "Selecione entre 2 e 3 palavras."
3. `recipe := GameData.find_recipe_for_words(selected)`.
4. Se `recipe == null`: feedback "Essa combinação não forma nenhuma magia." (Clarification Q3 literal).
5. Se `GameData.is_spell_prepared(recipe)`: feedback "Essa magia já está preparada." (FR-010).
6. Senão: `GameData.prepare_spell(recipe)` (já auto-saves); feedback "Magia preparada: %s." % recipe.result_skill.name.

Feedback é limpado em qualquer mudança de seleção (signal `toggled` dos botões zera o label).

**Rationale**: Q3 escolheu inline persistente sem dismiss. Texto em PT-BR. Reaproveita `find_recipe_for_words` e `is_spell_prepared` da foundation.

**Alternativas consideradas**:
- *Drag-and-drop de palavras numa "mesa de combinação"*: divertido mas escopo de UI fora do P1. Backlog futuro.
- *Confirmar com `Enter`*: ok pra acessibilidade; adicionar como bind secundário se trivial — não bloqueia spec.

---

## R8 — Grimório sempre disponível, mensagem de catálogo vazio (Clarification Q5, FR-019a)

**Decisão**: Tecla `G` / botão HUD / tab de inventário sempre operam quando `_can_open()` aceita (mesmas regras do inventário). Se `GameData.known_words.is_empty()`, a aba Palavras mostra um `%EmptyLabel` com:

> "Você ainda não conhece nenhuma palavra. Vença batalhas para aprender."

Aba Receitas vazia exibe:

> "Sem palavras, sem receitas conhecidas."

Aba Preparar vazia desabilita o botão Preparar e mostra:

> "Aprenda palavras antes de preparar magias."

**Rationale**: Q5 escolheu "sempre disponível" sem gate; o estado vazio precisa de copy clara para virar teaser e não confusão.

---

## R9 — Action input `grimoire` (tecla G)

**Decisão**: Adicionar action `grimoire` em `project.godot` (`[input]`) com binding `KEY_G`. `_unhandled_input` em `WorldGrimoire` consome `is_action_pressed("grimoire")` igual ao `WorldInventory` faz com `"inventory"`.

**Rationale**: Padrão Godot, espelha exatamente o que `inventory` já faz. Sem conflito conhecido com bindings de batalha (batalha trava o tree, action não dispara).

**Verificação**: confirmar que `G` não conflita com nenhum input existente — `grep -n "KEY_G\b\|\"G\"" project.godot` antes de implementar.

---

## R10 — Persistência intra-sessão (Clarification Q4)

**Decisão**: Nada novo. `GameData` é autoload, então `known_words` e `prepared_spells` vivem entre cenas automaticamente. Save/load apenas entre sessões. Não há FR/SC extra.

**Rationale**: Clarification Q4 explicitamente escolheu opção A. Sem trabalho extra.

---

## Resumo de impacto

| Arquivo | Tipo de mudança |
|---|---|
| `battleSystem/resources/battle_reward_resource.gd` | Adicionar `word_drops` |
| `battleSystem/data/rewards/*.tres` | (Opcional) configurar word_drops em ≥1 encontro para validação |
| `battleSystem/battle_scene.gd` | Adicionar linha "Palavras aprendidas: …" em `_format_victory_message` |
| `world/cripta/game_data.gd` | Estender `grant_battle_rewards` para iterar `word_drops` e popular `summary["new_words"]` |
| `battleSystem/ui/command_menu.tscn/.gd` | Novo botão `MagicButton` entre Skills e Combo; novo handler |
| `ui/grimoire/world_grimoire.tscn/.gd` | Novo autoload + cena raiz |
| `ui/grimoire/grimoire_tabs.tscn/.gd` (ou tabs individuais) | Novas cenas reutilizáveis das 3 abas |
| `ui/hud/world_inventory.tscn/.gd` | Trocar container por `TabContainer`, embutir tabs de grimório |
| `ui/hud/world_hud.tscn/.gd` | Adicionar botão Grimório |
| `project.godot` | Adicionar autoload `WorldGrimoire`; adicionar action `grimoire` (KEY_G) |
