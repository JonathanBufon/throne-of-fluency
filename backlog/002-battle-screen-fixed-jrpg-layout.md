# [FEAT] Tela de batalha fixa com layout JRPG espacial

**ID:** 002  
**Status:** Proposto  
**Prioridade:** Alta  
**Criado em:** 2026-05-05

---

## 1. Título da feature

Evoluir a batalha instanciável do overworld para uma tela de batalha dedicada, fixa, estilo JRPG clássico, com fundo espacial/cósmico, inimigos em slots superiores, personagens do jogador em slots inferiores e UI inferior clara.

---

## 2. Contexto atual encontrado no projeto

A base de integração overworld -> batalha já existe ou está parcialmente implementada:

- `project.godot` registra `BattleTransition` como autoload em `res://world/battle_transition.gd`.
- `world/battle_transition.gd` guarda `enemy_resources`, `return_scene`, `return_position`, `encounter_id`, `last_result` e faz troca de cena com fade.
- `actors/enemy/enemy.gd` tem perseguição do player, `battle_resource`, `battle_party`, `encounter_id`, guarda contra retrigger após fuga e chama `BattleTransition.request_battle()`.
- `actors/enemy/enemy.tscn` tem `DangerBox` com `Area2D`, `CollisionShape2D` e sinal `body_entered` conectado.
- `battleSystem/battle_scene.tscn` existe como cena real parametrizável, com `EnemySpawnPoints/Spawn1..3`, player, controller e UI.
- `battleSystem/battle_scene.gd` instancia inimigos a partir de `BattleTransition.enemy_resources` usando `battleSystem/core/enemy_battle_template.tscn`.
- `battleSystem/core/turn_based_controller.gd` descobre participantes pelos grupos `player` e `enemy` e emite `battle_won` / `battle_lost`.
- `world/world_scene.gd` reposiciona player/Lumen no retorno e remove encontros derrotados usando `GameData.defeated_encounters`.
- `world/cripta/game_data.gd` já tem `defeated_encounters`, `mark_encounter_defeated()` e `is_encounter_defeated()`.
- `battleSystem/tests/test_battle_scene.tscn` continua existindo como cena isolada de debug.

Ponto importante da auditoria: `world/shroom-lands.tscn` instancia `actors/enemy/enemy.tscn` em `Enemy`, mas não foi encontrada configuração de `battle_resource`, `battle_party` ou `encounter_id` nessa instância. Como `actors/enemy/enemy.tscn` também não define um `CharacterResource` padrão, o inimigo da entrada deve apenas emitir warning e não iniciar batalha até receber dados de combate.

Validação feita: leitura estática dos arquivos. O binário `godot`/`godot4` não foi encontrado no `PATH`, então o fluxo ainda precisa ser validado manualmente no editor.

---

## 3. Problema atual

A base técnica resolve boa parte da transição de cena e do fluxo de turnos, mas a apresentação da batalha ainda é protótipo:

- A cena real de batalha não tem fundo fixo espacial/cósmico.
- O fundo ainda é vazio/transparente, sem identidade visual de arena.
- O player é um único `StaticBody2D` hardcoded na cena.
- Os inimigos têm slots simples, mas não há uma camada visual clara `EnemySlots`.
- Não existe `PlayerSlots` para suportar grupo de 1 a 3 personagens.
- O template de inimigo usa `icon.svg` como placeholder visual.
- `CharacterResource` não carrega sprite/escala/offset visual de batalha.
- A UI existe, mas não está organizada como painel inferior JRPG.
- `CommandMenu` mostra `Attack`, `Skills` e `Run`; o alvo visual desejado pede `Attack`, `Combo`, `Item`.
- `PlayerStatusDisplay` hardcoda `player1.tres` e `player2.tres`, mesmo que a cena real tenha apenas `player1`.
- O destaque de personagem ativo existe pelo `onTurnIconNode` e pelo foco no painel, mas ainda precisa virar um feedback visual claro e integrado ao layout.

---

## 4. Objetivo da nova fase

Transformar a cena real de batalha em uma battle screen fixa, legível e reutilizável, preservando o sistema de turnos e a integração com overworld.

O overworld deve apenas disparar o encontro. A batalha deve montar a apresentação: fundo fixo, slots de inimigos, slots dos players, cursor/feedback e UI inferior.

---

## 5. Resultado visual esperado

- Ao tocar/entrar na `DangerBox` do inimigo no overworld, o jogo troca para `battleSystem/battle_scene.tscn`.
- A batalha abre em uma tela dedicada, sem navegação manual dos personagens.
- O fundo é fixo e tem estética espacial, cósmica, astral, dimensional ou abstrata.
- Inimigos aparecem no topo ou centro-superior.
- Chefes podem ocupar um slot central maior.
- Personagens do jogador aparecem na parte inferior/central.
- O grupo usa posições fixas de batalha, como slots.
- A UI ocupa a parte inferior da tela.
- A UI mostra comandos do personagem ativo, inicialmente `Attack`, `Combo`, `Item` quando existirem dados/sistemas para isso.
- A UI mostra nome, HP, MP e indicador de turno/ação.
- O personagem ativo tem destaque visual claro: seta, colchetes, brilho simples ou destaque no painel.
- O inimigo selecionado tem cursor de alvo claro.

Não é uma batalha tática por grid e não acontece diretamente no mapa de exploração.

---

## 6. Perguntas respondidas pela análise

- **O sistema atual já troca corretamente do overworld para a batalha?** Parcialmente. O fluxo existe em `enemy.gd` + `BattleTransition`, mas depende do inimigo ter `battle_resource` ou `battle_party` configurado. O inimigo de `shroom-lands.tscn` não parece ter isso hoje.
- **O `BattleTransition` já existe e está sendo usado?** Sim. Está registrado em `project.godot` e usado por `enemy.gd`, `battle_scene.gd` e `world_scene.gd`.
- **O inimigo de `shroom-lands.tscn` já possui dados de batalha vinculados?** Não foi encontrado vínculo na cena. Precisa configurar `battle_resource` ou `battle_party` e preferencialmente um `encounter_id` explícito.
- **A batalha atual ainda depende de inimigos hardcoded?** A cena real não depende de inimigos hardcoded, pois lê `BattleTransition.enemy_resources`. A cena de teste ainda tem inimigos hardcoded, o que é aceitável para debug. O visual dos inimigos ainda é hardcoded no template como placeholder.
- **A cena de batalha atual é parametrizável?** Parcialmente. Ela parametriza inimigos por resources e tem 3 spawn points. Ainda não parametriza fundo, slots de players, sprites/escala/offset por personagem ou composição de party.
- **O retorno da batalha para o overworld funciona?** O código existe: vitória/fuga chamam `BattleTransition.change_scene_with_fade(return_scene)`. Precisa validação manual na Godot.
- **O player volta para a posição correta?** `world_scene.gd` usa `BattleTransition.return_position` para mover player e Lumen em vitória/fuga. Precisa validação manual em `shroom-lands.tscn`.
- **O inimigo derrotado deixa de reaparecer?** O suporte existe: vitória chama `GameData.mark_encounter_defeated()` e `world_scene.gd` remove nodes com `encounter_id`. Em `shroom-lands.tscn`, o fallback por path deve funcionar, mas um `encounter_id` explícito é mais seguro.
- **O sistema atual suporta fundo fixo?** Não de forma estruturada. Pode adicionar um `Sprite2D`/`TextureRect` ou cena de background, mas ainda não existe nó/background configurável.
- **O sistema atual suporta spawn visual em slots?** Parcialmente para inimigos via `EnemySpawnPoints`. Não existe estrutura clara para `PlayerSlots`.
- **A UI atual está preparada para o layout desejado?** Parcialmente. Há `CommandMenu`, `PlayerStatusDisplay` e `TurnOrderBar`, mas estão posicionados como protótipo e ainda não formam um painel inferior JRPG coeso.
- **O sistema atual diferencia bem cena de teste e cena real de batalha?** Sim. Existem `battleSystem/battle_scene.tscn` para fluxo real e `battleSystem/tests/test_battle_scene.tscn` para teste isolado.
- **O que falta para chegar no visual desejado?** Fundo fixo, slots formais de player/inimigo, dados visuais nos resources ou templates, UI inferior reorganizada, cursor/feedback melhor, configuração do inimigo de `shroom-lands.tscn` e validação manual do fluxo.

---

## 7. Arquitetura proposta

Manter `BattleTransition`, `TurnBasedController`, `TurnBasedAgent`, `CommandMenu`, `PlayerStatusDisplay` e `TurnOrderBar`. A mudança deve ser principalmente de composição de cena e pequenos contratos de dados visuais.

Estrutura alvo da cena real:

```text
BattleScene
├── Background
├── EnemySlots
│   ├── EnemySlot1
│   ├── EnemySlot2
│   └── EnemySlot3
├── PlayerSlots
│   ├── PlayerSlot1
│   ├── PlayerSlot2
│   └── PlayerSlot3
├── EffectsLayer
├── CursorLayer
├── TurnBasedController
└── BattleUI
    ├── CommandPanels
    ├── PartyStatusPanel
    └── TurnOrderBar
```

Proposta incremental:

- `Background`: começar com `Sprite2D` ou `TextureRect` fixo, com textura exportada no script da batalha.
- `EnemySlots`: substituir ou renomear a intenção de `EnemySpawnPoints`, preservando compatibilidade no script durante a migração.
- `PlayerSlots`: criar slots para instanciar/posicionar personagens do jogador sem depender de posição hardcoded.
- `EffectsLayer`: manter ações simples por enquanto; depois centralizar animações e VFX.
- `CursorLayer`: camada para seta/colchetes/highlights sem misturar com agentes.
- `BattleUI`: organizar `CommandMenu`, status e turn order em uma área inferior previsível.

Exemplo de contrato futuro:

```gdscript
@export var battle_background: Texture2D
@export var player_resources: Array[CharacterResource]
```

Para sprites de batalha, avaliar uma extensão pequena de `CharacterResource`:

```gdscript
@export var battle_sprite: Texture2D
@export var battle_sprite_region: Rect2
@export var battle_scale := Vector2.ONE
@export var battle_offset := Vector2.ZERO
@export var is_boss := false
```

Se isso aumentar demais o escopo, criar primeiro templates específicos simples e migrar para resources depois.

---

## 8. Arquivos que precisam ser analisados

- `project.godot`
- `actors/enemy/enemy.gd`
- `actors/enemy/enemy.tscn`
- `world/shroom-lands.tscn`
- `world/battle_transition.gd`
- `world/world_scene.gd`
- `world/cripta/game_data.gd`
- `battleSystem/battle_scene.tscn`
- `battleSystem/battle_scene.gd`
- `battleSystem/tests/test_battle_scene.tscn`
- `battleSystem/core/enemy_battle_template.tscn`
- `battleSystem/core/turn_based_agent.tscn`
- `battleSystem/core/turn_based_agent.gd`
- `battleSystem/core/turn_based_controller.gd`
- `battleSystem/core/character.gd`
- `battleSystem/resources/character_resource.gd`
- `battleSystem/resources/skillResource.gd`
- `battleSystem/ui/command_menu.tscn`
- `battleSystem/ui/command_menu.gd`
- `battleSystem/ui/Player_Status_Display.tscn`
- `battleSystem/ui/player_status_display.gd`
- `battleSystem/ui/player_stats_container.tscn`
- `battleSystem/ui/player_stats_container.gd`
- `battleSystem/ui/turn_order_bar.tscn`
- `battleSystem/ui/turn_order_bar.gd`
- Assets em `assets/sprites/characters/`, `assets/sprites/player/` e `assets/ui/`

---

## 9. Arquivos que provavelmente serão modificados

- `battleSystem/battle_scene.tscn`
- `battleSystem/battle_scene.gd`
- `battleSystem/core/enemy_battle_template.tscn`
- `battleSystem/resources/character_resource.gd`
- `battleSystem/ui/command_menu.tscn`
- `battleSystem/ui/command_menu.gd`
- `battleSystem/ui/Player_Status_Display.tscn`
- `battleSystem/ui/player_status_display.gd`
- `battleSystem/ui/player_stats_container.tscn`
- `battleSystem/ui/player_stats_container.gd`
- `battleSystem/ui/turn_order_bar.tscn`
- `world/shroom-lands.tscn`
- Possível novo arquivo: `battleSystem/backgrounds/space_battle_background.tscn`
- Possíveis novos assets: textura de fundo espacial/cósmico em pasta coerente de `assets/`

Modificar `world/shroom-lands.tscn` apenas para configurar o encontro de teste, preservando nodes, sinais, groups e recursos existentes.

---

## 10. Etapas de implementação

### Fase 1 — Auditoria do estado atual

Confirmar em Godot:

- `shroom-lands.tscn` abre sem erros.
- O inimigo de entrada persegue o player.
- `DangerBox` detecta o player.
- A instância do inimigo tem `battle_resource` ou `battle_party`.
- `BattleTransition` recebe `return_scene`, `return_position`, `encounter_id` e inimigos.
- `battle_scene.tscn` instancia inimigos antes do controller montar a fila.
- Vitória/fuga retornam ao overworld.
- Inimigo derrotado é removido.

Resultado esperado:

- Lista do que funciona.
- Lista do que está parcial.
- Lista do que falta.
- Registro de erros do console, se houver.

### Fase 2 — Separar claramente Overworld Encounter de Battle Screen

Manter o overworld como disparador:

- Cena de retorno.
- Posição de retorno.
- ID do encontro.
- Lista de inimigos.
- Dados de batalha dos inimigos.

Manter a batalha como apresentadora/controladora:

- Fundo fixo.
- Slots de players.
- Slots de inimigos.
- Controller de turnos.
- Vitória, derrota e fuga.
- Retorno ao overworld.

Critério interno: nenhuma lógica visual da battle screen deve entrar em `enemy.gd` ou nas cenas de mundo.

### Fase 3 — Criar layout fixo de batalha

Refatorar `battleSystem/battle_scene.tscn` para a estrutura visual alvo.

Implementação mínima:

- Adicionar `Background` fixo.
- Adicionar `EnemySlots`.
- Adicionar `PlayerSlots`.
- Adicionar `EffectsLayer`.
- Adicionar `CursorLayer`.
- Reorganizar UI em uma área inferior.

Preservar:

- `TurnBasedController`.
- Grupos usados pelos agents.
- `CommandMenu`.
- `PlayerStatusDisplay`.
- `TurnOrderBar`.
- Cena de teste isolada.

### Fase 4 — Spawn em slots fixos

Migrar o spawn improvisado para slots formais:

- Inimigos comuns: usar 1, 2 ou 3 slots superiores.
- Chefe grande: usar slot central com escala/offset diferenciado.
- Players: usar até 3 slots inferiores.

Primeiro corte aceitável:

- 1 player atual em slot inferior central.
- 1 a 3 inimigos em slots superiores.
- Preparar nomes e estrutura para 3 players sem exigir party completa ainda.

### Fase 5 — UI inferior estilo JRPG

Reorganizar UI para painel inferior:

- Área de comandos do personagem ativo.
- `Attack`.
- `Combo` como placeholder desabilitado ou ausente até existir sistema de combo.
- `Item` como placeholder desabilitado ou ausente até existir inventário.
- Status de grupo com nome, HP, MP e OverDrive/turno.
- `TurnOrderBar` visível sem competir com o painel de status.

Não implementar inventário ou combos reais nesta feature, a menos que já existam dados prontos.

### Fase 6 — Cursor e feedback visual

Adicionar feedback simples e legível:

- Personagem ativo com seta acima do sprite e destaque no painel.
- Inimigo selecionado com cursor vermelho ou colchetes.
- Comando selecionado com foco visual do botão.
- Personagem esperando turno sem destaque.
- Personagem sem HP com modulação/estado visual simples.

O feedback deve usar nós existentes quando possível (`onTurnIconNode`, `targetIconNode`) antes de criar sistema novo.

### Fase 7 — Validação usando `shroom-lands.tscn`

Configurar o inimigo de entrada de `shroom-lands.tscn` como encontro manual de teste:

- Definir `battle_resource` ou `battle_party`.
- Definir `encounter_id` explícito, por exemplo `shroom_lands_entry_enemy_001`.
- Preservar comportamento de perseguição.

Teste manual:

1. Rodar a cena principal ou `shroom-lands.tscn`.
2. Aproximar o player do inimigo da entrada.
3. Confirmar perseguição.
4. Entrar na `DangerBox`.
5. Confirmar troca para battle screen fixa.
6. Confirmar fundo espacial/cósmico.
7. Confirmar inimigo no slot superior.
8. Confirmar player no slot inferior.
9. Usar `Attack`.
10. Confirmar ação do inimigo.
11. Vencer.
12. Confirmar retorno para `shroom-lands.tscn`.
13. Confirmar player em posição coerente.
14. Confirmar que o inimigo derrotado não reaparece.

---

## 11. Critérios de aceite

- [ ] `battleSystem/battle_scene.tscn` tem fundo fixo espacial/cósmico visível.
- [ ] A batalha não acontece no mapa de exploração.
- [ ] `BattleTransition` continua sendo o canal entre overworld e batalha.
- [ ] `battle_scene.gd` continua lendo inimigos de `BattleTransition.enemy_resources`.
- [ ] Inimigos aparecem em slots superiores/centrais.
- [ ] Player aparece em slot inferior/central.
- [ ] A estrutura da cena prevê até 3 slots de inimigos e até 3 slots de players.
- [ ] A UI ocupa a parte inferior de forma clara.
- [ ] A UI mostra comandos do personagem ativo.
- [ ] A UI mostra nome, HP e MP dos personagens suportados.
- [ ] O personagem ativo tem destaque visual claro.
- [ ] O inimigo selecionado tem cursor/feedback claro.
- [ ] `battleSystem/tests/test_battle_scene.tscn` não foi removida.
- [ ] O inimigo de `shroom-lands.tscn` mantém perseguição ao player.
- [ ] O inimigo de `shroom-lands.tscn` tem dados de batalha configurados.
- [ ] Vitória retorna para o overworld.
- [ ] Fuga retorna para o overworld sem marcar encontro como derrotado.
- [ ] Derrota mantém o comportamento atual de placeholder para `main.tscn` ou registra decisão diferente.
- [ ] Inimigo derrotado não reaparece no retorno.

---

## 12. Riscos e pontos de atenção

- Arquivos `.tscn` são sensíveis. Preservar `ext_resource`, `sub_resource`, sinais, grupos e nomes de nodes.
- `TurnBasedController._set_after_all_ready()` espera `0.1s` antes de conectar sinais e montar fila. O spawn dinâmico deve continuar ocorrendo antes disso.
- A cena real tem só um player instanciado, mas `PlayerStatusDisplay` lista `player1` e `player2`. A UI pode mostrar personagem sem agente se isso não for ajustado.
- `CharacterResource` guarda stats, mas não guarda visual. Adicionar campos visuais pode exigir atualizar `.tres` existentes.
- O template de inimigo usa `icon.svg`; sem campo visual, todos os inimigos continuarão iguais.
- Adicionar `Combo` e `Item` como botões funcionais exigiria sistemas que ainda não existem. Melhor tratar como desabilitados/fora de escopo inicial.
- `world/shroom-lands.tscn` usa `world/cripta/scenario.gd`, que estende `world_scene.gd`. Funciona por herança, mas o nome/path histórico pode confundir futuras análises.
- `DangerBox` em `actors/enemy/enemy.tscn` está com `collision_layer = 4`, que corresponde ao layer nomeado `fim_da_fase`, e `collision_mask = 2` para player. Como `Area2D` detecta por mask, pode funcionar, mas a layer nomeada não comunica bem a intenção.
- A validação de retorno depende de `BattleTransition.clear()` acontecer depois de `world_scene.gd` ler o resultado.
- `GameData.defeated_encounters` não é persistência em disco; ao reiniciar o jogo, encontros derrotados voltam.

---

## 13. O que está fora de escopo

- Reescrever o sistema de turnos do zero.
- Transformar a batalha em grid/tática.
- Fazer batalha no mapa de exploração.
- Remover `battleSystem/tests/test_battle_scene.tscn`.
- Remover perseguição do inimigo no overworld.
- Implementar sistema completo de combo.
- Implementar inventário/itens completo.
- Implementar XP, loot ou tela final de vitória completa.
- Implementar game over final.
- Persistência em disco de encontros derrotados.
- Criar arquitetura definitiva de party/roster para todo o jogo.
- Refatorar todas as cenas de mundo.

---

## 14. Definição de pronto

- [ ] Diagnóstico da Fase 1 validado no editor Godot.
- [ ] `shroom-lands.tscn` tem um encontro de teste configurado.
- [ ] `battle_scene.tscn` tem fundo fixo visualmente aprovado para protótipo.
- [ ] Slots de inimigos e players estão nomeados e estáveis.
- [ ] Inimigos vindos do overworld aparecem nos slots corretos.
- [ ] UI inferior mostra comandos e status sem sobreposição.
- [ ] Cursor/destaque do personagem ativo e alvo selecionado está visível.
- [ ] Ataque básico continua funcionando.
- [ ] Inimigo continua agindo no turno.
- [ ] Vitória, fuga e derrota preservam o comportamento atual esperado.
- [ ] Retorno para `shroom-lands.tscn` foi testado manualmente.
- [ ] Inimigo derrotado não reaparece após vitória.
- [ ] `godot --headless --path . --quit` foi executado sem erro, se Godot estiver no `PATH`.
- [ ] Se Godot não estiver disponível, foi feita validação estática e o teste manual pendente foi declarado.

---

## 15. Registro da Fase 1 — Auditoria estática

**Data:** 2026-05-05
**Status:** Parcial, aguardando validação manual na Godot
**Validação executada:** leitura estática dos arquivos, pois `godot`/`godot4` não foi encontrado no `PATH`.

### O que funciona ou já está estruturado

- `BattleTransition` está registrado em `project.godot` como autoload.
- `BattleTransition.request_battle()` guarda inimigos, cena de retorno, posição do player e `encounter_id`.
- `BattleTransition.change_scene_with_fade()` centraliza a troca de cena com fade.
- `actors/enemy/enemy.gd` mantém comportamento de patrulha/perseguição e procura o player pelo grupo `player`.
- `actors/enemy/enemy.gd` já tem `battle_resource`, `battle_party` e `encounter_id`.
- `actors/enemy/enemy.gd` monta a party de batalha e chama `BattleTransition.request_battle()` ao detectar player na `DangerBox`.
- `actors/enemy/enemy.tscn` possui `DangerBox` com `Area2D`, `CollisionShape2D` e sinal `body_entered` conectado.
- `battleSystem/battle_scene.gd` instancia inimigos dinamicamente a partir de `BattleTransition.enemy_resources`.
- `battleSystem/battle_scene.tscn` possui três pontos de spawn para inimigos em `EnemySpawnPoints`.
- `battleSystem/battle_scene.gd` conecta `battle_won`, `battle_lost` e `run_requested`.
- Vitória marca encontro derrotado via `GameData.mark_encounter_defeated()`.
- Fuga retorna ao overworld sem marcar encontro como derrotado.
- `world/world_scene.gd` reposiciona player/Lumen no retorno de vitória/fuga.
- `world/world_scene.gd` remove encontros derrotados ao entrar na cena.
- `battleSystem/tests/test_battle_scene.tscn` continua preservada para debug isolado.

### O que está parcial

- `world/shroom-lands.tscn` instancia o inimigo de teste, mas a instância não tem `battle_resource`, `battle_party` ou `encounter_id` configurados no arquivo.
- O fallback de `encounter_id` por path existe em `enemy.gd`, mas o encontro de teste deveria receber um ID explícito para reduzir risco ao editar a cena.
- A cena real de batalha é parametrizável para inimigos, mas ainda não para party de players, fundo, sprites, escala, offset ou tipo chefe.
- O spawn visual existe para inimigos, mas ainda usa `EnemySpawnPoints` genérico, sem a estrutura final `EnemySlots`.
- O player da batalha é hardcoded em `battle_scene.tscn`.
- `PlayerStatusDisplay` exibe `player1.tres` e `player2.tres`, enquanto a cena real instancia apenas um player.
- `CommandMenu` suporta `Attack`, `Skills` e `Run`; ainda não há modelo de UI para `Combo` e `Item`.
- O destaque do personagem ativo existe via `onTurnIconNode` e foco no painel, mas ainda não está integrado ao layout visual desejado.
- O template de inimigo de batalha usa `icon.svg` como placeholder visual.

### O que falta

- Configurar o inimigo da entrada de `shroom-lands.tscn` com `battle_resource` ou `battle_party`.
- Definir `encounter_id` explícito para o inimigo de teste em `shroom-lands.tscn`.
- Validar no editor se `shroom-lands.tscn` abre sem erros.
- Validar no editor se o inimigo persegue o player e se a `DangerBox` detecta colisão.
- Validar no editor se a troca para `battleSystem/battle_scene.tscn` ocorre depois de configurar dados de combate.
- Validar no editor se o spawn dinâmico acontece antes do `TurnBasedController` montar a fila.
- Validar vitória, fuga, derrota e retorno ao overworld.
- Validar se o inimigo derrotado é removido no retorno.
- Criar fundo fixo da batalha.
- Criar slots formais para inimigos e players.
- Reorganizar a UI inferior.
- Definir como sprites de batalha serão vinculados a personagens e inimigos.

### Riscos encontrados

- Sem dados de batalha no inimigo de `shroom-lands.tscn`, o fluxo para antes da troca de cena e emite warning.
- `DangerBox` usa `collision_layer = 4`, que no projeto está nomeada como `fim_da_fase`; a `collision_mask = 2` deve detectar player, mas a layer comunica intenção errada.
- `TurnBasedController` depende de um delay curto para montar sinais e fila; qualquer mudança no spawn dinâmico precisa preservar essa ordem.
- `PlayerStatusDisplay` pode mostrar status de personagem que não está na batalha real.
- `CharacterResource` não tem dados visuais; resolver sprites apenas na cena/template pode criar hardcode.
- Sem Godot no `PATH`, não há confirmação de parse, import, sinais ou colisões em runtime.

### Registro de erros do console

Não houve execução da Godot nesta auditoria. Erros de console ainda precisam ser coletados no editor ou com `godot --headless --path . --quit` quando o binário estiver disponível.

---

## 16. Registro da Fase 2 — Separação Overworld Encounter x Battle Screen

**Data:** 2026-05-05
**Status:** Implementação mínima aplicada, aguardando validação manual na Godot
**Validação executada:** revisão estática e diff dos arquivos alterados.

### Decisão aplicada

A Fase 2 manteve a separação já existente:

- O overworld continua responsável apenas por detectar o player e montar o payload do encontro.
- `BattleTransition` continua sendo o canal temporário para inimigos, cena de retorno, posição de retorno e `encounter_id`.
- `battleSystem/battle_scene.tscn` continua sendo a tela dedicada de batalha.
- `battleSystem/battle_scene.gd` continua responsável por instanciar inimigos, controlar vitória/derrota/fuga e retornar ao overworld.

### Alteração feita

O inimigo de entrada de `world/shroom-lands.tscn` agora tem dados mínimos de encontro:

- `battle_resource = res://battleSystem/data/characters/enemy1.tres`
- `encounter_id = "shroom_lands_entry_enemy_001"`

Com isso, a `DangerBox` não deve mais parar no warning de inimigo sem `battle_resource`/`battle_party`. Ao detectar o player, `enemy.gd` deve conseguir enviar para `BattleTransition`:

- cena de retorno;
- posição do player;
- ID do encontro;
- lista com o resource de batalha do inimigo.

### Fora desta fase

- Fundo fixo espacial/cósmico.
- Slots visuais formais.
- Reorganização da UI inferior.
- Sprites de batalha por `CharacterResource`.
- Ajuste do placeholder visual do inimigo.
- Validação manual completa do loop vitória/fuga/derrota.

### Teste manual pendente

1. Abrir o projeto na Godot 4.6.
2. Rodar `world/shroom-lands.tscn` ou chegar nela pelo fluxo principal.
3. Aproximar o player do inimigo da entrada.
4. Confirmar perseguição.
5. Entrar na `DangerBox`.
6. Confirmar troca para `battleSystem/battle_scene.tscn`.
7. Confirmar que pelo menos um inimigo é instanciado na batalha.
8. Vencer ou fugir e confirmar retorno para `shroom-lands.tscn`.

### Riscos restantes

- Godot não estava disponível no `PATH`, então sinais, imports e colisões ainda precisam ser confirmados no editor.
- A `DangerBox` ainda usa `collision_layer = 4`, nomeada como `fim_da_fase`; a mask de player está correta para detecção, mas a semântica da layer continua confusa.
- A batalha ainda usa template visual placeholder para o inimigo.

---

## 17. Registro da Fase 3 — Layout fixo de batalha

**Data:** 2026-05-05
**Status:** Implementação estrutural aplicada, aguardando validação visual/manual na Godot
**Validação executada:** revisão estática e diff dos arquivos alterados.

### Alteração feita

`battleSystem/battle_scene.tscn` recebeu uma estrutura inicial de battle screen fixa:

- `Background` com base escura, faixa cósmica simples e pontos de estrela.
- `EnemySlots` com `EnemySlot1`, `EnemySlot2` e `EnemySlot3`.
- `PlayerSlots` com `PlayerSlot1`, `PlayerSlot2` e `PlayerSlot3`.
- `EffectsLayer`.
- `CursorLayer`.
- `CanvasLayer/BattleUI`.
- `CanvasLayer/BattleUI/BottomPanel`.

O player hardcoded da cena foi reposicionado para o slot inferior central atual.

`battleSystem/battle_scene.gd` foi atualizado para:

- ler slots de inimigo em `$EnemySlots`;
- encontrar o menu em `$CanvasLayer/BattleUI/CommandMenu`.

### Preservado

- `TurnBasedController`.
- `CommandMenu`.
- `TurnOrderBar`.
- `PlayerStatusDisplay`.
- Spawn dinâmico de inimigos via `BattleTransition.enemy_resources`.
- Cena de teste isolada em `battleSystem/tests/test_battle_scene.tscn`.
- Fluxo de vitória, derrota e fuga.

### Fora desta fase

- Arte final do fundo espacial.
- Sprites reais dos inimigos vindos de `CharacterResource`.
- Spawn dinâmico de players por party.
- Reorganização completa de `CommandMenu`, `PlayerStatusDisplay` e `TurnOrderBar`.
- Implementação real de `Combo` e `Item`.
- Cursor customizado em `CursorLayer`.

### Teste manual pendente

1. Abrir `battleSystem/battle_scene.tscn` na Godot.
2. Confirmar que a cena abre sem warnings de node path.
3. Rodar o fluxo por `shroom-lands.tscn`.
4. Confirmar que o fundo fixo aparece.
5. Confirmar que o player aparece na parte inferior/central.
6. Confirmar que o inimigo instancia nos slots superiores.
7. Confirmar que `CommandMenu`, `PlayerStatusDisplay` e `TurnOrderBar` ainda aparecem e respondem.

### Riscos restantes

- A UI foi apenas agrupada sob `BattleUI`; o layout inferior completo ainda depende da Fase 5.
- O fundo é estrutural/protótipo, não arte final.
- Sem Godot no `PATH`, ainda falta validar se `ColorRect`/anchors e paths renderizam exatamente como esperado no editor.

---

## 18. Registro da Fase 4 — Spawn em slots fixos

**Data:** 2026-05-05
**Status:** Implementação inicial aplicada, aguardando validação manual na Godot
**Validação executada:** revisão estática e diff dos arquivos alterados.

### Alteração feita

`battleSystem/battle_scene.gd` agora usa os slots formais criados na Fase 3:

- O player hardcoded da cena é posicionado em `PlayerSlots/PlayerSlot2` durante `_ready()`.
- Um encontro com 1 inimigo usa `EnemySlots/EnemySlot2`, no centro superior.
- Um encontro com 2 inimigos usa `EnemySlots/EnemySlot1` e `EnemySlots/EnemySlot3`, esquerda e direita.
- Um encontro com 3 inimigos usa `EnemySlot1`, `EnemySlot2` e `EnemySlot3`.
- Encontros com mais de 3 inimigos continuam aceitos no payload, mas excedentes são ignorados com warning por enquanto.

### Preservado

- `BattleTransition.enemy_resources` continua sendo a origem dos inimigos.
- `enemy_battle_template.tscn` continua sendo o template de instância de inimigo.
- O player da cena continua sendo o único player real do primeiro corte.
- A fila do `TurnBasedController` continua dependendo dos grupos `player` e `enemy`.

### Fora desta fase

- Instanciar múltiplos players dinamicamente.
- Diferenciar chefe grande por campo de resource.
- Reposicionar UI e status para múltiplos personagens reais.
- Trocar o placeholder visual do inimigo.
- Adicionar animações de entrada ou movimentação elaborada.

### Teste manual pendente

1. Configurar temporariamente encontros de 1, 2 e 3 inimigos via `battle_party`.
2. Confirmar que 1 inimigo aparece no centro superior.
3. Confirmar que 2 inimigos aparecem nos slots laterais.
4. Confirmar que 3 inimigos aparecem nos três slots.
5. Confirmar que o player aparece no slot inferior central.
6. Confirmar que a ordem de turnos continua incluindo todos os agentes instanciados.

### Riscos restantes

- A formação de chefe grande ainda é apenas implícita: um único inimigo fica no centro, mas não há escala/offset especial.
- A party de players ainda não é dinâmica.
- Sem Godot no `PATH`, a validação de runtime continua manual.

---

## 19. Registro da Fase 5 — UI inferior estilo JRPG

**Data:** 2026-05-05
**Status:** Implementação inicial aplicada, aguardando validação visual/manual na Godot
**Validação executada:** revisão estática e diff dos arquivos alterados.

### Alteração feita

A UI de batalha foi reorganizada para ficar mais próxima de um painel inferior de JRPG:

- `CommandMenu` agora fica ancorado no painel inferior esquerdo.
- O menu principal mostra `Attack`, `Combo`, `Item` e preserva `Run`.
- `Combo` fica desabilitado como placeholder do sistema futuro.
- `Item` fica desabilitado como placeholder do inventário futuro.
- `Run` continua funcional para preservar fuga e retorno ao overworld.
- `PlayerStatusDisplay` foi reposicionado para o painel inferior direito.
- `PlayerStatusDisplay` agora monta status a partir dos `TurnBasedAgent` do grupo `player` presentes na batalha.
- `TurnOrderBar` foi compactado para o canto superior direito, sem competir com o painel inferior.

### Preservado

- `Attack` continua emitindo o comando básico do personagem ativo.
- `Run` continua emitindo `run_requested`.
- O foco do personagem ativo no status continua usando `activate_focus()`.
- A cena de teste isolada continua usando os mesmos componentes de UI.

### Fora desta fase

- Implementar combo real.
- Implementar inventário real.
- Criar layout final responsivo para múltiplos personagens.
- Redesenhar visualmente os botões e painéis.
- Criar ícones para comandos.

### Teste manual pendente

1. Rodar `battleSystem/battle_scene.tscn`.
2. Confirmar que `Attack`, `Combo`, `Item` e `Run` aparecem no painel inferior.
3. Confirmar que `Combo` e `Item` aparecem desabilitados.
4. Confirmar que `Attack` ainda permite selecionar alvo e causar dano.
5. Confirmar que `Run` ainda retorna ao overworld quando a batalha veio de `BattleTransition`.
6. Confirmar que o status mostra apenas personagens que participam da batalha real.
7. Confirmar que a barra de turnos fica visível e não cobre o painel inferior.

### Riscos restantes

- O layout ainda precisa de ajuste fino visual no editor.
- `Combo` e `Item` são placeholders, sem sistemas por trás.
- O status de múltiplos players reais depende da futura party dinâmica.
- Sem Godot no `PATH`, a validação de foco, anchors e estados disabled continua manual.

---

## 20. Registro da Fase 6 — Cursor e feedback visual

**Data:** 2026-05-05
**Status:** Implementação inicial aplicada, aguardando validação visual/manual na Godot
**Validação executada:** revisão estática e diff dos arquivos alterados.

### Alteração feita

O feedback visual da batalha foi reforçado reaproveitando os nós existentes:

- `TurnBasedAgent` agora guarda o nó visual do personagem (`Sprite2D` ou `AnimatedSprite2D`).
- O personagem ativo recebe modulação mais clara enquanto espera comando/alvo.
- O alvo selecionado recebe modulação avermelhada junto com o cursor de alvo já existente.
- Ao cancelar ou trocar alvo, os alvos anteriores voltam ao estado visual normal.
- Personagens com 0 HP recebem modulação escurecida.
- Depois de dano ou cura em `character.gd`, o estado visual do alvo é atualizado.
- `PlayerStatsContainer` passa a escurecer o painel de status quando o personagem está sem HP.

### Preservado

- `onTurnIconNode` continua sendo o indicador do personagem ativo.
- `targetIconNode` continua sendo o cursor de alvo.
- O fluxo de comandos, seleção de alvo e fim de turno não foi refeito.
- O foco visual do painel de status do personagem ativo foi preservado.

### Fora desta fase

- Cursor novo desenhado em `CursorLayer`.
- Animações complexas de brilho, seta ou colchetes.
- Feedback de comando selecionado além do foco de botão existente.
- Estados visuais específicos para defesa, status negativo ou carregamento.

### Teste manual pendente

1. Rodar uma batalha.
2. Confirmar que o player ativo fica visualmente destacado.
3. Escolher `Attack` e confirmar que o alvo selecionado fica destacado.
4. Trocar alvo, quando houver mais de um inimigo, e confirmar que o destaque muda.
5. Cancelar seleção de alvo e confirmar que o destaque sai.
6. Reduzir HP de um personagem a 0 e confirmar sprite/painel escurecidos.

### Riscos restantes

- Modulação simples pode não ser suficiente como linguagem visual final.
- Como os ícones usam posição calculada no `_ready()`, movimentações maiores de personagem podem exigir reposicionamento dinâmico dos indicadores.
- Sem Godot no `PATH`, a validação visual continua manual.

---

## 21. Registro da Fase 7 — Validação usando `shroom-lands.tscn`

**Data:** 2026-05-05
**Status:** Validação técnica headless executada; validação jogável/manual concluída no editor.
**Godot usado:** `/opt/godot/godot` (`4.6.1.stable.official.14d19694e`).

### Validação executada

Foram executados smoke tests headless para confirmar que as cenas relevantes carregam sem erros de script depois das fases anteriores:

```bash
/opt/godot/godot --headless --path . --scene res://battleSystem/tests/test_battle_scene.tscn --quit-after 30
/opt/godot/godot --headless --path . --scene res://battleSystem/battle_scene.tscn --quit-after 30
/opt/godot/godot --headless --path . --scene res://world/shroom-lands.tscn --quit-after 30
/opt/godot/godot --headless --path . --quit
git diff --check
```

### Resultado encontrado

- `battleSystem/tests/test_battle_scene.tscn` carrega sem erro de script após correção de tipagem em `PlayerStatsContainer`.
- `battleSystem/battle_scene.tscn` carrega sem erro de script quando aberta diretamente.
- Ao abrir `battle_scene.tscn` diretamente, o aviso `battle_scene carregada sem inimigos em BattleTransition.enemy_resources` é esperado, pois a cena real depende dos dados enviados pelo `BattleTransition`.
- `world/shroom-lands.tscn` carrega em modo headless sem erro de script.
- O inimigo de entrada em `shroom-lands.tscn` permanece configurado com `battle_resource` e `encounter_id`.
- A validação estática do diff não encontrou espaços finais ou problemas de whitespace.

### Correção mínima feita durante a validação

O smoke test identificou que Godot não conseguia inferir com segurança o tipo de `is_dead` em `battleSystem/ui/player_stats_container.gd`. A variável foi tipada explicitamente como `bool`, sem alterar comportamento funcional:

```gdscript
var is_dead: bool = characterResource != null and characterResource.is_dead()
```

### Avisos conhecidos

- Ainda aparecem avisos de fallback de UID invalido em recursos de cena/importacao.
- Esses avisos nao bloquearam o parse das cenas e nao foram introduzidos como parte da Fase 7.
- A limpeza dos UID warnings deve ser tratada separadamente para evitar misturar manutencao de asset/import com a validacao do fluxo de batalha.

### Teste manual validado

Validado manualmente no editor em 2026-05-05:

1. O jogo roda pela main scene.
2. O player entra em `shroom-lands.tscn`.
3. O inimigo de entrada persegue o player.
4. Entrar na `DangerBox` dispara `BattleTransition`.
5. A batalha abre com fundo fixo espacial.
6. O inimigo aparece no slot superior correto.
7. O player aparece no slot inferior central.
8. A UI inferior exibe comandos e status.
9. `Attack` causa dano no inimigo.
10. O inimigo consegue agir.
11. Vitoria ou fuga retorna para `shroom-lands.tscn`.
12. A posicao de retorno do player e coerente.
13. O inimigo derrotado nao reaparece quando a regra do encontro e aplicada.

### Conclusao da fase

A Fase 7 confirmou que a estrutura criada nas fases 3 a 6 nao quebrou o carregamento das cenas principais nem o parse do projeto. A validacao manual no editor tambem confirmou o fluxo jogavel completo: movimento ate o inimigo, colisao com a `DangerBox`, transicao para batalha, comandos, acao inimiga, retorno ao overworld e persistencia do inimigo derrotado.
