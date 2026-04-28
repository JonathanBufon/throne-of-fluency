# Throne of Fluency

RPG top-down em pixel art desenvolvido em Godot 4.6. O objetivo é ensinar inglês ao jogador
de forma orgânica através de vocabulário, puzzles e combate por turnos integrados à narrativa.
Inspirado em Chrono Trigger, Final Fantasy e The Legend of Zelda.

## Stack Técnica

- **Engine:** Godot 4.6 (GL Compatibility renderer)
- **Linguagem:** GDScript
- **Resolução:** 700×550, stretch mode `canvas_items`
- **Sprites:** Pixel art 16×16 e 48×48, filtro `Nearest` (sem suavização)
- **Física:** CharacterBody2D para jogador e inimigos

## Estrutura do Projeto

Convenção: scripts co-localizados com suas cenas; assets organizados por tipo.

```
throne-of-fluency/
├── actors/               — Entidades jogáveis e inimigos (cena + script juntos)
│   ├── player/
│   │   ├── player.tscn           — Cena do herói (CharacterBody2D)
│   │   └── player.gd             — Movimento e animação do herói
│   └── enemy/
│       ├── enemy.tscn            — Cena de inimigo (CharacterBody2D)
│       └── enemy.gd              — IA básica de inimigo (segue o jogador)
├── assets/               — Recursos visuais e de áudio
│   ├── fonts/                    — Fontes TTF (ex: CuteFantasy-5x9.ttf)
│   ├── sprites/
│   │   ├── characters/           — Spritesheets de personagens (Knights, Orcs, etc.)
│   │   ├── player/               — Spritesheet do herói jogável
│   │   └── world/                — Tiles e sprites de cenário (dungeon, shroomLands, green)
│   ├── test/                     — Assets usados apenas em testes
│   └── ui/                       — Sprites de interface (UI_Icons, UI_Frames, etc.)
├── battleSystem/         — Sistema de combate por turnos (autocontido)
│   ├── core/                     — Lógica central da batalha
│   │   ├── turn_based_controller.tscn/.gd  — Gerencia ordem de turnos e fim de batalha
│   │   ├── turn_based_agent.tscn/.gd       — Lógica por personagem (targeting, input, IA)
│   │   └── character.gd                    — Script raiz do nó de personagem (StaticBody2D)
│   ├── ui/                       — Cenas e scripts de interface de batalha
│   │   ├── command_menu.tscn/.gd           — Menu de ações do jogador
│   │   ├── command_button.tscn             — Botão reutilizável do menu de comandos
│   │   ├── player_status_display.tscn/.gd  — HUD de status dos jogadores
│   │   ├── player_stats_container.tscn/.gd — Painel HP/MP/OverDrive por personagem
│   │   ├── turn_order_bar.tscn/.gd         — Barra lateral de ordem de turnos
│   │   └── character_display_container.tscn
│   ├── data/                     — Recursos .tres prontos para uso em cenas
│   │   ├── skills/               — Attack.tres / Heal.tres / Slash.tres
│   │   └── characters/           — enemy1-3.tres / player1-2.tres / focus_player_stats.tres
│   ├── resources/                — Definições de Resource (.gd)
│   │   ├── character_resource.gd — CharacterResource: HP, MP, speed, overDrive
│   │   └── skillResource.gd      — SkillResource: name, targetType, skillType, power
│   └── tests/
│       └── test_battle_scene.tscn — Cena de teste isolada do sistema de batalha
├── ui/                   — Interfaces de jogo
│   └── dialog/
│       ├── dialog_screen.tscn          — Diálogo com NPC (modos DIALOG e INPUT)
│       ├── dialogo_acao_input.tscn     — Popup de input linguístico
│       └── dialogo_acao_input.gd       — Script do popup (sem acento no nome)
├── world/                — Mapas, cenários e scripts de mundo
│   ├── fase_cripta.tscn          — Fase 1: Cripta dos Ecos Perdidos (cena principal)
│   ├── cenario1.tscn             — Cenário de transição (ShroomLands)
│   ├── exit_cripta.tscn          — Saída da cripta
│   ├── fim_da_fase.tscn          — Trigger de fim de fase (Area2D)
│   ├── testes.tscn               — Cena de testes gerais
│   ├── porta.gd                  — Lógica da porta com puzzle linguístico
│   ├── fim_da_fase.gd            — Detecta player e troca de cena
│   └── scenario.gd               — Script de cenário (stub)
└── main.tscn             — Cena principal de entrada
```

## Arquitetura de Sistemas

### Sistema de Combate por Turnos

**Estado:** Funcional. Batalha inicia, processa turnos de jogadores e inimigos, termina com vitória ou derrota.

**Arquitetura de arquivos (`battleSystem/`):**

| Arquivo | Responsabilidade |
|---|---|
| `battleSystem/resources/skillResource.gd` | `SkillResource` — dados de habilidade: `name`, `targetType`, `skillType`, `power` |
| `battleSystem/resources/character_resource.gd` | `CharacterResource` — dados de personagem: HP, MP, speed, overDrive. Métodos `take_damage`, `heal`, `is_dead` |
| `battleSystem/core/turn_based_agent.gd` | `TurnBasedAgent` — Node filho de cada personagem. Gerencia targeting, input de seleção, sinais de turno |
| `battleSystem/core/turn_based_controller.gd` | `TurnBasedController` — Gerencia a ordem de turnos, detecta fim de batalha, emite `battle_won`/`battle_lost` |
| `battleSystem/core/character.gd` | Script do nó raiz de cada personagem (StaticBody2D). Aplica animação + efeito da skill (dano ou cura) |
| `battleSystem/ui/command_menu.gd` | `CommandMenu` — UI do turno do jogador. Emite `command_selected(command: Resource)` |
| `battleSystem/ui/player_status_display.gd` | HUD de status dos jogadores — lista `PlayerStatsContainer` por jogador |
| `battleSystem/ui/player_stats_container.gd` | Painel de HP/MP/OverDrive de um personagem, com polling de mudanças |
| `battleSystem/ui/turn_order_bar.gd` | Barra lateral com a ordem de turnos atual |

**Grupos Godot em uso:**
- `"turnBasedAgents"` — todos os agentes (jogadores + inimigos)
- `"player"` — agentes do tipo PLAYER
- `"enemy"` — agentes do tipo ENEMY
- `"commandMenu"` — o CommandMenu da cena
- `"turnBasedController"` — o TurnBasedController da cena

**Fluxo de turno:**
1. `TurnBasedController` chama `agent.set_active(true)` no próximo da fila
2. **Jogador:** `player_turn_started` → `CommandMenu` aparece → jogador escolhe comando → `command_selected` → jogador seleciona alvo com setas → `ui_accept` → `target_selected` → `character.gd` aplica efeito → `turn_finished`
3. **Inimigo:** `set_active(true)` ataca automaticamente um jogador vivo aleatório → `turn_finished`
4. Após cada turno, `TurnBasedController` verifica fin de batalha, depois avança a fila

**Como invocar a batalha de outra cena:**
```gdscript
# Instanciar a cena de batalha (use test_battle_scene.tscn como base)
# Conectar aos sinais do TurnBasedController para saber o resultado:
var controller: TurnBasedController = get_tree().get_first_node_in_group("turnBasedController")
controller.battle_won.connect(_on_battle_won)
controller.battle_lost.connect(_on_battle_lost)
```
> Para integração completa (passar inimigos dinâmicos do overworld), crie um Autoload `BattleTransition`
> que armazene os dados do encontro antes de trocar de cena, e leia esses dados no `_ready` da cena de batalha.

**Campos de `SkillResource`:**
- `name: String` — nome exibido no menu
- `targetType: Target_Type` — `ENEMIES` (0) ou `PLAYERS` (1)
- `skillType: Skill_Type` — `DAMAGE` (0) ou `HEAL` (1)
- `power: int` — quantidade de dano ou cura

**Habilidades disponíveis:**
| Arquivo | Nome | Alvo | Efeito | Power |
|---|---|---|---|---|
| `data/skills/Attack.tres` | Attack | Inimigos | Dano | 15 |
| `data/skills/Slash.tres` | Slash | Inimigos | Dano | 22 |
| `data/skills/Heal.tres` | Heal | Jogadores | Cura | 25 |

**Fluxo do turno do jogador:**
1. `TurnBasedAgent` emite `player_turn_started` → `CommandMenu` aparece com opções do personagem
2. Jogador escolhe Ataque, Habilidade ou Fuga → `command_selected` é emitido
3. `CommandMenu` se oculta enquanto o jogador seleciona alvo
4. `undo_command_selected` (ui_cancel) cancela o targeting e reabre o menu

> **Atenção:** O botão "Fuga" chama `get_tree().quit()` — ainda é um placeholder.

### Sistema de Diálogo (`dialog_screen.gd`)

Dois modos de operação, ambos pausam o jogo (`get_tree().paused = true`):

- **Modo DIALOG** — Exibe sequência de falas com animação de texto (typewriter). Avança com `ui_accept`. Emite `dialog_finished` ao encerrar.
  ```gdscript
  dialog.start_dialog([
      {"title": "Lumen", "dialog": "Hello, hero.", "faceset": "res://..."},
  ])
  ```

- **Modo INPUT** — Exibe prompt e aguarda o jogador digitar uma resposta. Retorna `bool` (correto/errado). Emite `input_submitted`.
  ```gdscript
  var correto = await dialog.start_input("Porta", "PUSH TO OPEN", "", "push to open")
  ```

### Sistema de Porta (`porta.gd`)

- Detecta proximidade do jogador via `Area2D` (grupo `"player"`).
- Exige ação `interact` (InputMap) para ativar.
- Chama `dialog.ask()` no node `UI/Dialogo_Acao_Input` — o path é hardcoded em `world/porta.gd`, verificar nas cenas.

### Sistema de Inimigo (`enemy.gd`)

- IA simples: segue o jogador via `CharacterBody2D`.
- Referencia o jogador com `get_tree().get_first_node_in_group("player")`.

## Lore Essencial

**Mundo:** Lexicon — governado por deuses que guardam os pilares do saber. As tensões
negativas destruíram o vínculo da ordem e jogaram o mundo no Delírio.

**A Joia do Diálogo** foi quebrada pelo Rei Orc e fragmentada em três:
- **Auris** — Gema da Escuta
- **Vox** — Gema da Comunicação
- **Scriptum** — Gema da Escrita

Quanto mais próximo de uma gema, maior o poder linguístico na região (Tier Zone).

**Verbum** — Deus supremo. Perdeu a voz, mas criou Lumen para resgatar o mundo através do herói.

**Herói** — Armadura vazia sem memórias. Tabula rasa que representa a estrutura gramatical
a ser preenchida com conhecimento. Inicia com a Lâmina de Ferro Comum e o Grimório de Marfim.

**Lumen** — Centelha de luz criada por Verbum. Assistente do jogador. Não fala com sons,
projeta conceitos na mente do herói. Falas sempre em inglês com tradução em português.

## Sistemas de Jogo

### Combate por Turnos
Projetado para dar tempo ao jogador de pensar antes de agir. Nunca deve ser frenético.

### Sistema Lumen
Lumen oferece dicas e traduz frases captadas de NPCs, inimigos, placas e interações do mundo.
**Energia limitada** — recarrega ficando próxima ao jogador que porta as gemas. Isso força
o jogador a também aprender de forma autônoma.

### Sistema de Magia do Grimório
Palavras aprendidas ficam registradas no Grimório. Combinações de palavras formam magias:
- `throw` + `fire` + `ball` → magia **Throw Fire Ball**

O jogador pode pré-montar encantamentos para usar como skill rápida no combate,
ou tentar adivinhar combinações durante a batalha. Ao acertar, apenas **uma palavra**
da magia é salva — o jogador precisa recitar várias vezes para desbloquear a magia completa.
Isso reforça a repetição como método de aprendizado.

### Sistema de Glossário
Dicionário interativo para o jogador se virar sem Lumen. Fornece contexto das frases
e incentiva a interpretação autônoma do vocabulário.

## Demo Inicial

**Fase 1 — Cripta dos Ecos Perdidos** (`fase_cripta.tscn`)
Tutorial. O herói desperta, encontra Lumen, aprende os controles e as mecânicas básicas.
Primeiro desafio linguístico: interpretar "PUSH TO OPEN" na porta de pedra.

**Fase 2 — ShroomLands (Floresta de Cogumelos)**
Primeiro cenário de exploração livre. NPCs, inimigos e puzzles de linguagem.
Objetivo: coletar a primeira gema (Auris — Gema da Escuta).

## Convenções de Código

- Nodes em PascalCase: `PlayerCharacter`, `LumenCompanion`
- Scripts em snake_case: `player_controller.gd`, `combat_manager.gd`
- Signals descritivos no passado: `vocabulary_learned`, `gem_collected`
- Lógica de combate, diálogo e movimento em scripts separados
- Vocabulário e puzzles em `.json` ou `.tres` — nunca hardcoded no código
- Grupos Godot em uso: `"player"`, `"commandMenu"`
- InputMap actions em uso: `left`, `right`, `up`, `down`, `interact`, `ui_accept`

## O que NÃO fazer

- Nunca suavizar sprites — sempre filtro `Nearest`
- Nunca hardcodar textos em inglês no código
- Nunca misturar lógica de UI com lógica de gameplay
- Combate nunca deve ser apressado — o tempo de reflexão é parte do design
- Nunca referenciar nodes por path hardcoded sem documentar a estrutura de cena esperada

## Pendente / Expansão Futura

### Crítico (bloqueante)
- [ ] Substituir `get_tree().quit()` no botão Fuga por lógica real de fuga/escape
- [ ] Renomear `diálogo_acao_input.gd` (tem acento no nome — pode causar problemas cross-platform)
- [ ] Integração overworld→batalha: Autoload `BattleTransition` para passar dados de encontro dinamicamente

### Sistema
- [ ] Sistema Lumen: energia, proximidade com gemas, tradução de frases
- [ ] Sistema de Grimório: registro de palavras, combinações → magias
- [ ] Sistema de Glossário: dicionário interativo

### Conteúdo
- [ ] Documentar o Pantéon de Deuses (além de Verbum)
- [ ] Tabela de combinações de palavras → magias
- [ ] Narrativa expandida: heróis antigos, evento da quebra da Joia, papel dos Orcs
- [ ] Mais Tier Zones e cenários pós-ShroomLands
- [ ] Diálogos dinâmicos, progressão adaptativa, sistema de quests
