# Implementation Plan: Grimório — Coletar Palavras, Preparar e Lançar Magias

**Branch**: `feat/grimorio-foundation` | **Date**: 2026-06-02 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/001-grimoire-words-spells/spec.md`

## Summary

Completar o vertical slice do grimório (steps 4-6 da issue #45) sobre a foundation já entregue na branch (commit `4aab1fd`). O slice cobre: (4) drop de palavra em vitória → (5) tela de grimório acessível por 3 caminhos (tecla G, tab no inventário, botão HUD) com abas Palavras/Receitas/Preparar → (6) cast de magia preparada via novo comando "Magia" no menu de batalha. O save/load do step 3 já cobre `known_words`/`prepared_spells` — esta fase só estende o ciclo end-to-end.

Abordagem técnica: estender `BattleRewardResource` com `word_drops`, ligar `GameData.grant_battle_rewards` ao `discover_word` existente, espelhar o padrão do `WorldInventory` autoload para criar `WorldGrimoire`, embutir a mesma cena dentro de uma tab no `WorldInventory` (single source de UI per Clarification Q1), adicionar botão `Magia` ao `CommandMenu` reaproveitando a pipeline existente de `SkillResource` (per Clarification Q2/Q3/Q4/Q5).

## Technical Context

**Language/Version**: GDScript (Godot 4.6)

**Primary Dependencies**: Godot Engine 4.6 (GL Compatibility renderer); nenhuma dependência externa.

**Storage**: `user://save.json` (JSON via `FileAccess`), já implementado em `GameData.save_game`/`load_game` na foundation.

**Testing**: Sem runner automatizado. Validação via:
- `godot --headless --path . --quit` (smoke geral do projeto)
- `godot --headless --path . --scene res://battleSystem/tests/test_battle_scene.tscn --quit-after 30`
- Validação manual no editor (golden path descrito em `quickstart.md`).

**Target Platform**: Desktop (Linux/Windows/Mac), viewport fixo `800x760`, stretch `canvas_items`, filtro Nearest.

**Project Type**: Single-project Godot game (top-down pixel art RPG educacional).

**Performance Goals**: 60 fps no overworld e em batalha; abertura/fechamento do grimório imperceptível (≤200 ms, SC-006); transições de cena via `BattleTransition` já estabelecidas.

**Constraints**:
- UI em PT-BR; CuteFantasy apenas decorativa, fonte default do Godot na gameplay (memória do projeto).
- Não renomear nodes/cenas sem necessidade; preservar API atual de `CharacterResource`/`SkillResource`/`GameData`.
- Não editar UID/import manualmente sem motivo claro.
- Não remover `battleSystem/tests/test_battle_scene.tscn`.
- Convenção: `snake_case` em funções/variáveis; campos exportados pré-existentes em `camelCase` permanecem.

**Scale/Scope**:
- 5 palavras + 2 receitas + 2 skills resultantes (conteúdo inicial já commitado).
- 3 caminhos de acesso ao grimório, 3 abas (Palavras/Receitas/Preparar).
- 1 botão novo no menu de comandos (`Magia`) + 1 submenu.
- 1 campo novo em `BattleRewardResource` (`word_drops`).
- 1 seção nova na tela de vitória (inline).

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

`.specify/memory/constitution.md` ainda contém apenas o template não-ratificado (placeholders genéricos). Sem princípios concretos para enforcer.

**Gate status**: PASS (vácuo). Como substituto operacional, aplico as convenções do `CLAUDE.md` do projeto (estilo de código, autoloads, fonte/idioma da UI) e as regras de memória do usuário (UI em PT-BR, workflow issue→branch→PR, fonte default na gameplay). Nenhuma violação prevista.

**Pós-design (Phase 1) re-check**: PASS — design não introduz padrão arquitetural novo; reaproveita autoload, signals, e a pipeline de `SkillResource` já em uso.

## Project Structure

### Documentation (this feature)

```text
specs/001-grimoire-words-spells/
├── plan.md              # Este arquivo (/speckit-plan)
├── spec.md              # /speckit-specify + /speckit-clarify
├── research.md          # Phase 0 — decisões técnicas e alternativas
├── data-model.md        # Phase 1 — entities, campos e ciclo de vida
├── quickstart.md        # Phase 1 — validação manual end-to-end
├── contracts/           # Phase 1 — contratos públicos (signals, métodos, recursos)
│   ├── game_data_api.md
│   ├── grimoire_scene.md
│   ├── command_menu_magia.md
│   └── battle_reward_word_drops.md
├── checklists/
│   └── requirements.md  # /speckit-specify
└── tasks.md             # /speckit-tasks (não criado por este comando)
```

### Source Code (repository root)

Real tree (relevante para esta feature; demais pastas inalteradas):

```text
actors/
  player/                            (existente, sem mudança)
  enemy/                             (existente, sem mudança)

battleSystem/
  battle_scene.gd                    MODIFICAR: _format_victory_message ganha bloco "Palavras aprendidas:"
  resources/
    battle_reward_resource.gd        MODIFICAR: + word_drops: Array[WordResource]
    word_resource.gd                 (existente, sem mudança)
    spell_recipe_resource.gd         (existente, sem mudança)
  data/
    rewards/                         AJUSTAR: configurar word_drops em encontros de teste
      *.tres
    words/, spells/                  (existente, sem mudança)
  ui/
    command_menu.tscn/.gd            MODIFICAR: novo botão Magia entre Skills e Combo;
                                                  reusa _populate_command_list para listar prepared_spells

ui/
  hud/
    world_hud.tscn/.gd               MODIFICAR: + botão Grimório (CTA HUD)
    world_inventory.tscn/.gd         MODIFICAR: container vira TabContainer (Itens | Grimório);
                                                  embute a cena de WorldGrimoire na 2ª tab
  grimoire/                          NOVO
    world_grimoire.tscn              cena raiz do grimório (CanvasLayer + Panel + TabContainer)
    world_grimoire.gd                autoload; toggle por tecla G; pause tree no padrão WorldInventory
    grimoire_tab_words.tscn/.gd      aba Palavras (lista EN/PT/tipo)
    grimoire_tab_recipes.tscn/.gd    aba Receitas (oculta sem nenhuma palavra; "???" parcial)
    grimoire_tab_prepare.tscn/.gd    aba Preparar (seleciona 2-3, valida, prepara)

world/
  cripta/
    game_data.gd                     SEM MUDANÇA NA API — apenas confirmar:
                                      • discover_word/has_word/prepare_spell já fazem o trabalho
                                      • grant_battle_rewards passa a iterar word_drops
                                        (adicionar bloco na função existente)

project.godot                        MODIFICAR: + autoload WorldGrimoire; + input action "grimoire" (G)
```

**Structure Decision**: Single-project Godot game. Mantemos a estrutura por domínio (`actors/`, `battleSystem/`, `world/`, `ui/`) já estabelecida. O grimório se encaixa em duas camadas: **dados** (`battleSystem/resources` + `battleSystem/data`) e **UI overworld** (`ui/grimoire/` novo, espelhando `ui/hud/`). O cast em batalha vive em `battleSystem/ui/command_menu.gd` sem nova cena dedicada — apenas um botão a mais e um array a mais em `_populate_command_list`.

## Complexity Tracking

Sem violações constitucionais (constituição não ratificada). Nenhuma complexidade extra a justificar — a feature reusa três padrões já estabelecidos:

| Reaproveitamento | Padrão fonte | Razão |
|---|---|---|
| Autoload pause-tree com toggle por tecla | `WorldInventory` (`ui/hud/world_inventory.gd`) | Comportamento idêntico ao do inventário; copy & adapt evita inventar nova convenção. |
| Embedding de cena em tab | `TabContainer` padrão Godot | Atende Clarification Q1 (single source UI) sem custom logic. |
| Submenu de comandos em batalha | `_populate_command_list` em `CommandMenu` | Skills, Combo e Item já passam pela mesma função; magia é só uma 4ª lista. |
