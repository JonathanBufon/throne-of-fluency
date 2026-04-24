# Throne of Fluency 

RPG educacional top-down em pixel art desenvolvido em Godot 4.6. O jogador aprende inglês de forma orgânica — não por lições, mas porque o idioma é o mecanismo central do jogo: abre portas, desbloqueia magias e dá sentido ao mundo.

---

## Sobre o Jogo

### O Mundo

**Lexicon** era um mundo em harmonia até o dia em que o Rei Orc invadiu o Olimpo das Gemas. Ao tentar destruir a Gema da Paz, ele atingiu a **Gema do Diálogo** — o pilar que sustentava a comunicação entre os povos. A gema se quebrou em três fragmentos:

| Fragmento | Domínio | Desafio no Jogo |
|---|---|---|
| **Auris** | Escuta e compreensão | Challenges de listening |
| **Vox** | Fala e comunicação | Diálogos e escolha de palavras |
| **Scriptum** | Escrita e registro | Formação de palavras e frases |

Sem a Gema do Diálogo, os reinos pararam de se entender. Monstros surgiram. O mundo entrou em colapso linguístico.

### O Herói

Uma armadura vazia, reanimada por **Lumen** — uma centelha de luz criada por Verbum, o Deus da Linguagem. O herói é uma *tabula rasa*: possui poder (a Lâmina de Ferro Comum e o Grimório de Marfim), mas não possui vocabulário. Tudo que ele aprende, o jogador aprende junto.

### Lumen

Assistente do jogador. Não fala com sons — projeta conceitos diretamente na mente do herói. Suas falas são sempre em inglês com tradução em português. Possui **energia limitada**: fica fraco se o jogador não se aproximar das gemas, forçando autonomia no aprendizado.

---

## Mecânicas Principais

### Combate por Turnos

Inspirado em Final Fantasy e Chrono Trigger. O tempo é intencional — o combate nunca deve ser frenético. O jogador tem espaço para pensar antes de agir.

- Ordem de turno baseada em speed dos personagens
- Menu de comandos: Ataque, Habilidades, Fuga
- Sistema de OverDrive que carrega ao receber/causar dano

### Sistema de Magia do Grimório

Palavras aprendidas ficam registradas no Grimório como vocabulário. Combinações de palavras formam magias:

```
throw + fire + ball  →  THROW FIRE BALL (magia de fogo)
```

Se o encantamento estiver pré-montado, pode ser usado como skill rápida no combate. Caso contrário, o jogador pode tentar montar as palavras durante a batalha. Ao acertar, **apenas uma palavra** é salva — o jogador precisa recitar várias vezes para desbloquear a magia completa. Repetição como método de aprendizado.

### Sistema Lumen

Lumen oferece dicas, traduz frases captadas de NPCs, inimigos, placas e objetos do mundo. Sua energia recarrega conforme a proximidade com as gemas. Quanto mais perto, mais rápido. Quando fraco, o jogador precisa usar o Glossário por conta própria.

### Glossário

Dicionário interativo integrado ao jogo. Fornece contexto das palavras e incentiva a interpretação autônoma — não entrega a resposta, mas dá ferramentas para o jogador chegar até ela.

### Puzzles Linguísticos

Integrados ao cenário: portas que respondem a comandos escritos, NPCs que se comunicam em inglês, objetos que exigem compreensão para interagir. O primeiro exemplo é a porta da cripta inicial: **"PUSH TO OPEN"**.

---

## Stack Técnica

| | |
|---|---|
| **Engine** | Godot 4.6 — GL Compatibility renderer |
| **Linguagem** | GDScript |
| **Resolução** | 700×550, stretch mode `canvas_items` |
| **Sprites** | Pixel art 16×16 e 48×48, filtro `Nearest` (sem suavização) |
| **Física** | `CharacterBody2D` para jogador e inimigos |
| **Assets** | Cute Fantasy Characters, Cute Fantasy Dungeons UI, ShroomLands Tileset |

---

## Como Rodar

1. Instale o [Godot 4.6](https://godotengine.org/download)
2. Clone o repositório:
   ```bash
   git clone https://github.com/JonathanBufon/throne-of-fluency.git
   ```
3. Abra o Godot e importe o projeto selecionando `project.godot`
4. Pressione **F5** — a cena principal carrega `world/fase_cripta.tscn`

**Para testar o sistema de combate diretamente:** abra `battleSystem/test_battle_scene.tscn` e rode com **F6**.

---

## Estrutura do Projeto

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

---

## Estado Atual

### Implementado

- Movimentação e animações do jogador (idle, run, 4 direções)
- Cripta dos Ecos Perdidos com tilemaps, colisões e decorações
- Sistema de porta com puzzle de texto
- Inimigo básico com IA de perseguição
- **Sistema de combate por turnos completo:**
  - Ordem de turno dinâmica (TurnBasedController)
  - Menu de comandos com ataque, habilidades e suporte a skills customizadas
  - Recursos de personagem com HP, MP, speed e OverDrive
  - Skills tipadas (DAMAGE / HEAL) com power configurável
  - Detecção de fim de batalha (vitória / derrota)
  - Exibição de status dos jogadores em tempo real
  - Barra de ordem de turno visual

### Em Desenvolvimento

- Sistema Lumen: energia, proximidade com gemas, tradução contextual
- Sistema de Grimório: registro de palavras, combinações → magias
- Sistema de Glossário: dicionário interativo
- Lógica real de fuga no combate
- Transição de batalha (BattleTransition autoload)
- Fase 2: ShroomLands — exploração livre, NPCs, puzzles

---

## Equipe

- **Gabriel Rosario**
- **Jonathan Bufon**
- **Rafael Merisio Neto**

---

## Licença

Projeto acadêmico (ABEX). Os asset packs utilizados possuem licença para uso comercial e não-comercial, com proibição de redistribuição dos assets originais.
