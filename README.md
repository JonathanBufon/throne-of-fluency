# Throne Of Fluency: Unlocking the New World

Um RPG 2D top-down desenvolvido em **Godot 4.6** que ensina inglês de forma orgânica através de gameplay imersivo. Em vez de lições tradicionais de gramática, o jogador **adquire** o idioma ao interagir com o mundo, resolver puzzles linguísticos e progredir na narrativa.

## Sobre o Jogo

Em **Lexicon**, um mundo onde a comunicação foi destruída pela profanação da Joia do Diálogo, o jogador controla uma armadura vazia reanimada por Lumen — uma centelha de luz gramatical enviada pelo deus Verbum. O herói deve recuperar os fragmentos da Joia e, no processo, aprender a Língua de Verbum (inglês) para desbloquear magias e avançar pelo mundo.

### Premissa

O herói é uma *tabula rasa*: possui poder (o Grimório de Marfim) mas não possui compreensão linguística. Conforme o jogador aprende vocabulário e estruturas em inglês, novas magias são desbloqueadas e novos caminhos se abrem. A primeira prova disso é a porta da cripta inicial, que exige compreender o comando **"PUSH TO OPEN"** para sair.

### Mecânicas Principais

- **Exploração top-down** com movimentação em 4 direções (WASD / setas)
- **Puzzles linguísticos** integrados ao cenário (portas que exigem palavras-chave, NPCs que se comunicam em inglês)
- **Sistema de combate** com ataques direcionais
- **Interação contextual** (tecla E) com objetos e NPCs do mundo
- **Progressão de vocabulário** que desbloqueia habilidades no Grimório

## Estrutura do Projeto

```
Throne-Of-Fluency/
├── assets/images/          # Sprites, tilesets e elementos visuais
│   ├── characters/         # Spritesheets dos personagens (Knights, etc.)
│   ├── scenario/           # Tilesets de cenários (dungeon, shroomLands)
│   ├── ui-elements/        # Interface do usuário
│   └── player/             # Spritesheet do jogador alternativo
├── entities/
│   └── player.tscn         # Cena do jogador (CharacterBody2D)
├── scenes/
│   ├── fase_cripta.tscn    # Fase principal: Cripta dos Ecos Perdidos
│   ├── cenario1.tscn       # Cenário externo (Selvas de Sylvara)
│   ├── enemy.tscn          # Cena base do inimigo
│   └── testes.tscn         # Cena de testes
├── scripts/
│   ├── player.gd           # Movimentação e animação do jogador
│   └── porta.gd            # Lógica da porta com puzzle de texto
├── interfaces/
│   └── battle_base.tscn    # Layout base do sistema de batalha
├── main.tscn               # Cena raiz
└── project.godot           # Configuração do projeto Godot
```

## Tecnologias

| Tecnologia | Uso |
|---|---|
| **Godot 4.6** | Engine de jogo (GDScript, renderer GL Compatibility) |
| **GDScript** | Linguagem de scripting para toda a lógica do jogo |
| **Asset Packs** | Cute Fantasy Characters, Cute Fantasy Dungeons UI, ShroomLands Tileset |

## Como Executar

1. Instale o [Godot 4.6](https://godotengine.org/download) ou superior
2. Clone o repositório:
   ```bash
   git clone https://github.com/JonathanBufon/throne-of-fluency.git
   ```
3. Abra o Godot e importe o projeto selecionando o arquivo `project.godot`
4. Pressione **F5** para rodar (a cena principal é `fase_cripta.tscn`)

## Controles

| Tecla | Ação |
|---|---|
| WASD / Setas | Movimentação |
| Espaço | Ataque |
| E | Interagir |

## Estado Atual

O projeto está em **fase inicial de desenvolvimento**. O que já existe:

- Movimentação e animações do jogador (idle, run, attack em 4 direções)
- Cenário da Cripta com tilemaps, paredes com colisão e objetos decorativos
- Cenário externo (ShroomLands) com vegetação e decorações
- Sistema de porta com puzzle de texto (digitar "push to open" para abrir)
- Inimigo básico que persegue o jogador
- Layout inicial do sistema de batalha

## Equipe

- **Gabriel Rosario**
- **Jonathan Bufon**
- **Rafael Merisio Neto**

## Licença

Projeto acadêmico (ABEX). Os asset packs utilizados possuem licença para uso comercial e não-comercial, com proibição de redistribuição.