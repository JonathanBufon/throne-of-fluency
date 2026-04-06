# CLAUDE.md

Guia de contexto para assistência de IA no desenvolvimento do projeto Throne Of Fluency.

## Visão Geral

**Throne Of Fluency** é um RPG 2D top-down educacional feito em **Godot 4.6** com **GDScript**. O objetivo é ensinar inglês de forma imersiva — o jogador aprende vocabulário e gramática ao interagir com o mundo do jogo, não através de lições explícitas.

## Stack Técnica

- **Engine:** Godot 4.6 (GL Compatibility renderer)
- **Linguagem:** GDScript
- **Resolução:** 700×550, stretch mode `canvas_items`
- **Pixel art:** Sprites 16×16 e 48×48, filtro de textura `Nearest` (sem suavização)
- **Física:** 2D com CharacterBody2D para jogador e inimigos

## Arquitetura do Projeto

### Diretórios

- `scripts/` — Scripts GDScript reutilizáveis (player.gd, porta.gd)
- `entities/` — Cenas de entidades instanciáveis (player.tscn)
- `scenes/` — Cenas de fases e testes (fase_cripta.tscn, cenario1.tscn, enemy.tscn)
- `interfaces/` — Layouts de UI (battle_base.tscn)
- `assets/images/` — Todos os recursos visuais organizados por categoria

### Cenas Principais

| Cena | Descrição |
|---|---|
| `scenes/fase_cripta.tscn` | Fase inicial. Cripta com paredes, porta com puzzle, escada de saída. É a **main scene** do projeto. |
| `scenes/cenario1.tscn` | Cenário externo (ShroomLands) com vegetação e tilemaps de grama/cliff. |
| `scenes/enemy.tscn` | Inimigo básico que persegue o jogador. |
| `scenes/testes.tscn` | Cena de sandbox para testar mecânicas. |
| `entities/player.tscn` | Jogador com AnimatedSprite2D, Camera2D e CollisionShape2D. Escala 4x. |
| `interfaces/battle_base.tscn` | Layout base de batalha com barra de vida e sprite de inimigo. |

### Scripts Existentes

**`scripts/player.gd`** — Controle do jogador:
- Herda de `CharacterBody2D`
- Velocidade constante: `300.0`
- Input: `left`, `right`, `up`, `down` (WASD + setas), `attack` (espaço), `interact` (E)
- Animações: `idle_down/right/up`, `run_down/right/up`, `attack_down/right/up`, `dying`, `undying`
- Flip horizontal para direção esquerda (reutiliza animações `_right`)
- Usa `last_direction` para manter a animação de idle na última direção

**`scripts/porta.gd`** — Porta com puzzle de texto:
- Detecta proximidade do jogador via Area2D + grupo `"player"`
- Ao pressionar `interact`, exibe um LineEdit para digitar a resposta
- Resposta correta: `"push to open"` (case insensitive)
- Toca animação `"abrir"` e desativa colisão ao abrir

**`scenes/enemy.gd`** — Inimigo perseguidor:
- Herda de `CharacterBody2D`
- Velocidade exportável: `100`
- Persegue o primeiro node no grupo `"player"` via `get_tree().get_first_node_in_group("player")`

## Convenções

### Nomenclatura
- Cenas e scripts em **português** (fase_cripta, porta, cenario1)
- Nomes de animações em **inglês** (idle_down, run_right, attack_up)
- Grupos em **português** ("player" é exceção, usado como "player")
- Input actions em **inglês** (left, right, up, down, attack, interact)

### Padrões de Código
- GDScript com tipagem opcional (usado em player.gd: `var direction := Input.get_vector(...)`)
- `@onready` para referências de nodes filhos
- `@export` para propriedades configuráveis no editor
- `_physics_process` para lógica de movimento
- `_process` para lógica de interação/input

### Estrutura de Animação
- Spritesheet atlas: frames recortados como `AtlasTexture` com regiões `Rect2`
- `SpriteFrames` com animações nomeadas por `prefixo_direção`
- Velocidades: idle/run = 5fps, attack = 10fps, dying = 5fps

## Contexto Narrativo (para referência ao criar conteúdo)

- **Mundo:** Lexicon — um reino onde a comunicação foi destruída
- **Vilões:** Orcs que profanaram a Joia do Diálogo
- **Protagonista:** Armadura vazia reanimada por Lumen (centelha de luz)
- **Companheira:** Lumen — guia que projeta conceitos em inglês na mente do herói
- **Objetivo:** Recuperar fragmentos da Joia, aprendendo inglês no processo
- **Itens:** Lâmina de Ferro Comum (combate), Grimório de Marfim (magias desbloqueadas por vocabulário)
- **Progressão:** Aprender palavras/frases em inglês desbloqueia magias e caminhos
- **Fase atual:** Cripta dos Ecos Perdidos (tutorial, puzzle "PUSH TO OPEN")
- **Próxima fase:** Selvas de Sylvara (cenario1.tscn)

## Dependências e Assets

Os assets visuais são de packs comerciais com licença de uso (proibida redistribuição):
- Cute Fantasy Characters (Knights/Swordman)
- Cute Fantasy Dungeons UI
- ShroomLands Scenario (tiles, props, mushrooms)
- Dungeon Scenario (Dungeon_1, Dungeon_2, Objects, Stairs, Doors, Pressure Plates)
- Player sprite alternativo (usado no enemy.tscn)

## O Que Ainda Precisa Ser Feito

- Sistema de batalha por turnos completo (layout base existe em `battle_base.tscn`)
- Sistema de diálogos com NPCs (Lumen como tutorial)
- Mais puzzles linguísticos além da porta
- Sistema de progressão do Grimório (vocabulário → magias)
- Transição entre cenas (cripta → cenário externo via escada)
- HUD do jogador (vida, inventário)
- Mais tipos de inimigos com IA variada
- Sistema de áudio (música e efeitos sonoros)
