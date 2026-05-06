# Throne of Fluency

RPG educacional top-down em pixel art desenvolvido em Godot 4.6. O jogador aprende inglês de forma orgânica: o idioma é usado como mecanismo de mundo para abrir portas, estruturar puzzles, dar contexto a diálogos e futuramente formar magias.

## Sobre o Jogo

**Lexicon** entrou em colapso depois que o Rei Orc atingiu a Gema do Diálogo. A gema se partiu em três fragmentos:

| Fragmento | Domínio | Uso no jogo |
|---|---|---|
| Auris | Escuta e compreensão | Challenges de listening |
| Vox | Fala e comunicação | Diálogos e escolha de palavras |
| Scriptum | Escrita e registro | Formação de palavras e frases |

O herói é uma armadura vazia reanimada por **Lumen**, uma centelha criada por Verbum, o Deus da Linguagem. O herói não possui vocabulário próprio: tudo que ele aprende, o jogador aprende junto.

## Stack Técnica

| Item | Valor |
|---|---|
| Engine | Godot 4.6 |
| Renderer | GL Compatibility |
| Linguagem | GDScript |
| Viewport | 800x760, stretch mode `canvas_items` |
| Pixel art | Filtro `Nearest`, sem suavização |
| Física | `CharacterBody2D` para player e inimigos de overworld |

## Como Rodar

1. Instale Godot 4.6.
2. Importe `project.godot`.
3. Pressione F5 para rodar `main.tscn`.

Comandos úteis, quando o binário estiver disponível:

```bash
godot --path .
godot --headless --path . --quit
```

Neste ambiente, o binário também pode existir em:

```bash
/opt/godot/godot --headless --path . --quit
```

Teste isolado de combate:

```txt
battleSystem/tests/test_battle_scene.tscn
```

Abra a cena e rode com F6.

## Estrutura Atual

```txt
actors/
  player/             Player do overworld
  enemy/              Inimigo de overworld, perseguição e gatilho de batalha
  lumen/              Companheiro Lumen

battleSystem/
  battle_scene.tscn   Tela real de batalha fixa estilo JRPG
  battle_scene.gd
  core/               Controller, agents, character e templates
  data/               Recursos .tres de personagens e skills
  resources/          Classes Resource
  tests/              Cena isolada de teste do combate
  ui/                 Menu de comandos, status e ordem de turno

ui/
  dialog/             Diálogo e input linguístico

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

main.tscn
project.godot
```

## Sistemas Implementados

### Overworld

- Player com movimento e animações direcionais.
- Lumen acompanha o player durante exploração.
- Cripta com puzzle linguístico da porta.
- `shroom-lands.tscn` com inimigo de entrada que persegue o player.
- Troca de mapas via `troca_fase`.
- Persistência simples em `GameData`.

### Combate

O combate é iniciado pelo overworld, mas acontece em uma tela dedicada de batalha.

Fluxo atual:

1. O inimigo do overworld detecta o player pela `DangerBox`.
2. `enemy.gd` monta o encontro usando `battle_party` ou `battle_resource`.
3. `BattleTransition` guarda inimigos, cena de retorno, posição de retorno, `encounter_id` e dados visuais dos atores.
4. A cena muda para `battleSystem/battle_scene.tscn`.
5. A batalha usa fundo fixo espacial, slots para inimigos e player, UI inferior e barra de turno.
6. Vitória marca o encontro em `GameData.defeated_encounters` e retorna ao overworld.
7. Fuga toca `run_down`, retorna ao overworld e não marca o inimigo como derrotado.
8. Derrota toca `dying` nos players mortos e retorna para `main.tscn` como fluxo provisório de game over.

Recursos atuais:

- Turnos por `TurnBasedController`.
- Participantes por grupos Godot: `turnBasedAgents`, `player`, `enemy`.
- Menu de comandos com `Attack`, placeholder de skills/combo e `Run`.
- Status de HP/MP do grupo.
- Barra lateral de ordem de turno.
- Feedback visual de personagem ativo, alvo e personagem morto.
- Atores animados com `idle_*`, `attack_*`, `dying` e `run_down` na fuga.
- Inimigos de batalha instanciados a partir do inimigo real que ativou o encontro.

### Dados de Combate

- `CharacterResource`: nome, HP, MP, speed, OverDrive.
- `SkillResource`: nome, tipo de alvo, tipo de skill e poder.
- Skills existentes: `Attack`, `Heal`, `Slash`.
- Personagens de teste em `battleSystem/data/characters/`.

## Sistemas Planejados

- Sistema Lumen: energia, proximidade com gemas e tradução contextual.
- Grimório: registro de palavras aprendidas e combinações para magias.
- Glossário: dicionário interativo.
- Game over real e retorno para save anterior.
- Persistência completa de HP/MP entre overworld e batalha.
- Recompensas de vitória, XP, loot e tela de resultado completa.

## Documentação de Trabalho

- `AGENTS.md`: regras rápidas para agentes e colaboradores.
- `HARNESS.md`: guia operacional detalhado para IA e fluxo de desenvolvimento.
- `CLAUDE.md`: visão técnica e arquitetura atual.
- `Throne_Of_Fluency_Documentacao.md`: documento de produto, lore e design.

`/backlog/` é local e ignorado pelo Git. Use para planejamento temporário, sem subir para o GitHub.

## Equipe

- Gabriel Rosario
- Jonathan Bufon
- Rafael Merisio Neto

## Licença

Projeto acadêmico (ABEX). Os asset packs usados no projeto possuem licença para uso comercial e não-comercial, com proibição de redistribuição dos assets originais.
