# Throne of Fluency

Guia técnico do estado atual do projeto.

## Resumo

Throne of Fluency é um RPG educacional top-down em pixel art feito em Godot 4.6. O projeto usa GDScript, cenas por domínio de gameplay e combate por turnos em uma tela dedicada estilo JRPG.

## Stack

- Engine: Godot 4.6
- Renderer: GL Compatibility
- Linguagem: GDScript
- Main scene: `main.tscn`
- Viewport: `800x760`, stretch mode `canvas_items`
- Pixel art: filtro `Nearest`
- Autoloads:
  - `GameData` -> `world/cripta/game_data.gd`
  - `BattleTransition` -> `world/battle_transition.gd`

## Estrutura

```txt
actors/
  player/             Player do overworld
  enemy/              Inimigo do overworld e gatilho de batalha
  lumen/              Companheiro Lumen

battleSystem/
  battle_scene.tscn   Cena real de batalha
  battle_scene.gd
  core/
    character.gd
    enemy_battle_template.tscn
    turn_based_agent.gd
    turn_based_controller.gd
  data/
    characters/
    skills/
  resources/
    character_resource.gd
    skillResource.gd
  tests/
    test_battle_scene.tscn
  ui/
    command_menu.tscn/.gd
    player_status_display.tscn/.gd
    player_stats_container.tscn/.gd
    turn_order_bar.tscn/.gd

ui/dialog/
  dialog_screen.tscn
  dialogo_acao_input.tscn/.gd

world/
  battle_transition.gd
  world_scene.gd
  troca_fase.tscn/.gd
  shroom-lands.tscn
  city_center.tscn
  cripta/
    cripta.tscn
    game_data.gd
    porta.gd
    scenario.gd
```

## Sistema de Combate

### Estado

Funcional. O combate inicia a partir do overworld, troca para `battleSystem/battle_scene.tscn`, executa turnos, resolve vitória/derrota/fuga e retorna quando aplicável.

### Fluxo overworld -> batalha

1. O player entra na `DangerBox` de um inimigo em uma cena de mundo.
2. `actors/enemy/enemy.gd` monta a lista de inimigos usando `battle_party` ou `battle_resource`.
3. `BattleTransition.request_battle()` guarda:
   - inimigos do encontro;
   - cena de retorno;
   - posição de retorno do player;
   - `encounter_id`.
4. `BattleTransition` também recebe dados visuais temporários:
   - `SpriteFrames` do inimigo;
   - animação/frame/flip/scale do inimigo;
   - `SpriteFrames` do player;
   - animação/frame/flip do player.
5. `BattleTransition.change_scene_with_fade()` troca para `battleSystem/battle_scene.tscn`.
6. `battle_scene.gd` instancia inimigos nos slots fixos e aplica os `SpriteFrames` reais dos atores.

### Battle screen

A batalha real usa layout fixo:

```txt
BattleScene
├── Background
├── EnemySlots
├── PlayerSlots
├── EffectsLayer
├── CursorLayer
├── TurnBasedController
├── Player
└── CanvasLayer/BattleUI
```

Características:

- Fundo fixo espacial/cósmico.
- Inimigos em slots superiores.
- Player em slot inferior central.
- UI inferior com comandos e status.
- Barra de ordem de turno no canto direito.
- Cena de teste isolada preservada em `battleSystem/tests/test_battle_scene.tscn`.

### Turnos

Arquivos principais:

| Arquivo | Responsabilidade |
|---|---|
| `turn_based_controller.gd` | Monta fila por speed/grupos, ativa turnos e detecta fim de batalha |
| `turn_based_agent.gd` | Input, targeting, IA simples de inimigo e animações do ator |
| `character.gd` | Executa ação, anima avanço/recuo e aplica dano/cura |
| `command_menu.gd` | UI de comandos e emissão de eventos |

Grupos usados:

- `turnBasedAgents`
- `player`
- `enemy`
- `commandMenu`
- `turnBasedController`

### Comandos

- `Attack`: usa `basicAttack`.
- Skills/Combo: espaço de UI preservado; ainda não é o sistema final de combos.
- `Run`: toca `run_down`, desloca o player para fora da arena e retorna ao overworld sem marcar o encontro como derrotado.

### Animações

O BattleSystem usa as animações reais dos atores:

- `idle_up`, `idle_down`, `idle_right`
- `attack_up`, `attack_down`, `attack_right`
- `dying`
- `run_down` para fuga do player

Quando o alvo está à esquerda, o sistema usa `attack_right`/`idle_right` com `flip_h = true`.

No fim da batalha:

- Vitória toca `dying` nos inimigos mortos antes de mostrar `Victory` e retornar ao overworld.
- Derrota toca `dying` nos players mortos antes de mostrar `Defeat` e ir para o fluxo provisório de game over.
- Fuga não toca `dying`.

### Resultado

- Vitória:
  - marca `GameData.defeated_encounters[encounter_id]`;
  - retorna para a cena de origem;
  - `world_scene.gd` reposiciona o player e remove inimigos derrotados.
- Fuga:
  - retorna para a cena de origem;
  - não marca o encontro como derrotado;
  - evita retrigger imediato até o player sair da `DangerBox`.
- Derrota:
  - retorna para `main.tscn` como placeholder de game over/save anterior.

## Sistema de Overworld

Arquivos principais:

- `actors/player/player.gd`
- `actors/enemy/enemy.gd`
- `actors/lumen/lumen.gd`
- `world/world_scene.gd`
- `world/troca_fase.gd`
- `world/cripta/porta.gd`
- `world/cripta/game_data.gd`

Regras atuais:

- Player e inimigos usam `CharacterBody2D`.
- Player entra no grupo `player`.
- Inimigos procuram o player com `get_tree().get_first_node_in_group("player")`.
- Inimigos que iniciam combate precisam de `battle_resource` ou `battle_party`.
- Use `encounter_id` explícito quando possível.
- Cenas de mundo que precisam de retorno de batalha devem usar a lógica de `world_scene.gd`.

## Sistema de Diálogo e Porta

- `ui/dialog/dialog_screen.tscn`: diálogo e input.
- `ui/dialog/dialogo_acao_input.tscn/.gd`: popup de resposta textual.
- `world/cripta/porta.gd`: puzzle `PUSH TO OPEN`.

O sistema ainda é prototipal e pode conter paths específicos da cena da cripta. Ao mexer, validar manualmente no editor.

## Dados

### CharacterResource

`battleSystem/resources/character_resource.gd`

Campos:

- `name`
- `maxHealth`
- `currentHealth`
- `maxMana`
- `currentMana`
- `speed`
- `overDriveValue`

Métodos:

- `take_damage`
- `heal`
- `is_dead`

### SkillResource

`battleSystem/resources/skillResource.gd`

Campos:

- `name`
- `targetType`
- `skillType`
- `power`

Skills atuais:

- `Attack.tres`
- `Heal.tres`
- `Slash.tres`

## Convenções

- GDScript com tabs.
- Funções e variáveis em `snake_case`.
- Constantes em `UPPER_SNAKE_CASE`.
- Campos exportados já existentes podem usar camelCase; preservar APIs atuais.
- Não renomear nodes/cenas sem necessidade.
- Não editar UID/import manualmente sem motivo claro.
- Não remover `battleSystem/tests/test_battle_scene.tscn`.

## Testes

Não existe runner automatizado. Validação esperada:

```bash
godot --headless --path . --quit
godot --headless --path . --scene res://battleSystem/tests/test_battle_scene.tscn --quit-after 30
godot --headless --path . --scene res://battleSystem/battle_scene.tscn --quit-after 30
godot --headless --path . --scene res://world/shroom-lands.tscn --quit-after 30
```

Quando Godot não estiver no `PATH`, usar o binário local se existir:

```bash
/opt/godot/godot --headless --path . --quit
```

Também validar manualmente:

1. Rodar `main.tscn`.
2. Entrar em `shroom-lands.tscn`.
3. Encostar no inimigo de entrada.
4. Confirmar transição para battle screen.
5. Confirmar animações `idle`, `attack`, `dying` e `run_down`.
6. Confirmar vitória, fuga e retorno ao overworld.

## Pendências Conhecidas

- Sistema Lumen completo.
- Grimório e combinações de palavras.
- Glossário.
- Game over/save anterior real.
- Persistência completa de HP/MP entre cenas.
- Recompensas de vitória, XP, loot e tela de resultado completa.
- UI final para combos, itens e múltiplos membros de party.

## Backlog

`/backlog/` é local e está ignorado pelo Git. Pode ser usado para planejamento temporário, mas não deve ser tratado como documentação versionada nem subir para o GitHub.
