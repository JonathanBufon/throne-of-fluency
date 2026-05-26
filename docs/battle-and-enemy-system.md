# Sistema de Batalha e Inimigos

Este guia descreve como um inimigo do overworld inicia uma batalha, como os dados chegam ao `battleSystem`, como criar inimigos únicos e como configurar comportamento de IA.

## Visão Geral

O projeto separa três responsabilidades:

- **Inimigo de overworld**: cena em `actors/enemy/enemy.tscn`, controlada por `actors/enemy/enemy.gd`. Cuida de patrulha, perseguição, `DangerBox` e transição para batalha.
- **Modelo de inimigo**: `EnemyModelResource`. Define como uma instância específica entra na batalha: base de stats, nome, IA e visual.
- **Cena de batalha**: `battleSystem/battle_scene.tscn`. Instancia player e inimigos em slots fixos, executa ATB, comandos, IA, recompensas e retorno ao overworld.

O ponto importante: a batalha deve receber **instâncias próprias** de `CharacterResource`. Não reutilize diretamente o mesmo resource para dois inimigos ativos, porque HP, MP e ATB são estado mutável.

## Fluxo de Batalha

1. O player entra na `DangerBox` de um inimigo do overworld.
2. `actors/enemy/enemy.gd` monta a lista de inimigos.
3. Se houver `battle_model` ou `battle_models`, cada modelo cria uma cópia própria de `CharacterResource`.
4. O script coleta os dados visuais do inimigo ou do modelo.
5. `BattleTransition.request_battle()` recebe inimigos, cena de retorno, posição e `encounter_id`.
6. `BattleTransition.set_player_party()` recebe o player atual.
7. `BattleTransition.set_enemy_visuals()` recebe sprites/animações/escala de batalha.
8. A cena muda para `battleSystem/battle_scene.tscn`.
9. `battle_scene.gd` instancia templates de batalha e atribui cada `CharacterResource`.
10. `TurnBasedController` preenche o ATB e ativa players/inimigos quando ficam prontos.
11. `TurnBasedAgent` executa comando do player ou ação de IA do inimigo.
12. Vitória concede recompensas, marca o encontro derrotado e retorna ao overworld.

## Arquivos Principais

- `actors/enemy/enemy.gd`: ponte entre overworld e batalha.
- `world/battle_transition.gd`: canal temporário de dados entre cenas.
- `battleSystem/battle_scene.gd`: instancia slots, aplica visual e fecha resultado.
- `battleSystem/core/turn_based_controller.gd`: ATB, estados de batalha e fim de batalha.
- `battleSystem/core/turn_based_agent.gd`: agente individual, seleção de alvo e IA do inimigo.
- `battleSystem/resources/character_resource.gd`: stats e estado de personagem.
- `battleSystem/resources/enemy_model_resource.gd`: modelo de inimigo/instância.
- `battleSystem/resources/enemy_ai_resource.gd`: configuração de comportamento de IA.
- `battleSystem/resources/battle_reward_resource.gd`: XP, gold e drops.

## Criando um Inimigo

### 1. Criar ou escolher o CharacterResource base

Use um arquivo em `battleSystem/data/characters/`.

Campos importantes:

- `name`
- `maxHealth` / `currentHealth`
- `maxMana` / `currentMana`
- `speed`
- `basicAttack`
- `techs`
- `enemyAI`
- `battleReward`

O `CharacterResource` base representa o tipo de inimigo. Exemplo: `enemy1.tres` pode representar a base de um goblin.

### 2. Criar a IA

Crie um `.tres` em `battleSystem/data/enemy_ai/` usando `EnemyAIResource`.

Campos:

- `targetStrategy`: alvo aleatório ou menor HP.
- `preferSkillWhenAffordable`: usa skill ofensiva quando tiver MP.
- `healAllyHealthRatio`: limite para tentar curar aliado.
- `actionWindupSeconds`: pausa antes de executar ação, para o jogador perceber a intenção.
- `preferredSkillFirstTurn`: primeiro turno em que a skill preferida pode aparecer.
- `preferredSkillCooldownTurns`: intervalo de turnos para repetir skill preferida.
- `actionPattern`: padrão explícito de comandos, útil para bosses.

Exemplos existentes:

- `battleSystem/data/enemy_ai/grunt_pressure.tres`
- `battleSystem/data/enemy_ai/skill_caster.tres`
- `battleSystem/data/enemy_ai/boss_alternating.tres`

### 3. Criar o EnemyModelResource

Crie um `.tres` em `battleSystem/data/enemies/` usando `EnemyModelResource`.

Campos:

- `baseCharacter`: o `CharacterResource` base.
- `displayName`: nome específico da instância, opcional.
- `enemyAI`: IA específica da instância, opcional.
- `battleSpriteFrames`: sprite de batalha específico, opcional.
- `battleAnimation`: animação inicial de batalha, opcional.
- `battleFrameIndex`: frame inicial, opcional.
- `battleFlipH`: orientação inicial.
- `battleScale`: escala do sprite na batalha.

Exemplo:

- `battleSystem/data/enemies/shroom_grunt_pressure.tres`

Esse modelo pode criar um "Shroom Grunt" a partir de `enemy1.tres`, mas com uma IA própria. Outro modelo pode usar o mesmo `enemy1.tres` e ter outro comportamento.

### 4. Configurar a cena do overworld

Na instância de `actors/enemy/enemy.tscn` dentro do mapa:

- Para um inimigo único, preencha `battle_model`.
- Para um encontro com vários inimigos únicos, preencha `battle_models`.
- Use `encounter_id` único para impedir respawn após vitória.

Exemplo atual em `world/shroom-lands.tscn`:

```txt
battle_model = res://battleSystem/data/enemies/shroom_grunt_pressure.tres
encounter_id = shroom_lands_entry_enemy_001
```

## Encontros com Dois Goblins Diferentes

Mesmo que os dois sejam goblins, crie dois modelos:

```txt
battleSystem/data/enemies/goblin_aggressive.tres
battleSystem/data/enemies/goblin_defensive.tres
```

Ambos podem usar o mesmo `baseCharacter`, mas cada um pode ter:

- nome diferente;
- IA diferente;
- escala/sprite/animação diferente;
- recompensa diferente, se o `baseCharacter` também for diferente.

Depois configure `battle_models` no inimigo do overworld:

```txt
battle_models = [
  goblin_aggressive,
  goblin_defensive
]
```

Cada entrada gera uma cópia própria de `CharacterResource`, então HP/MP/ATB não são compartilhados.

## IA do Inimigo

A IA roda em `TurnBasedAgent`.

Ordem atual de decisão:

1. Se `actionPattern` tiver comando válido, usa o comando do padrão.
2. Se houver aliado ferido abaixo de `healAllyHealthRatio` e skill de cura disponível, cura.
3. Se `preferSkillWhenAffordable` estiver ativo e o cooldown permitir, usa skill ofensiva com MP suficiente.
4. Se nada acima resolver, usa `basicAttack`.

Seleção de alvo:

- `RANDOM_PLAYER`: escolhe player vivo aleatório.
- `LOWEST_HP_PLAYER`: escolhe player vivo com menor HP atual.
- Skills de cura miram inimigos aliados feridos.

Ritmo:

- `actionWindupSeconds` dá tempo antes da ação.
- Durante resolução, o controlador pode pausar gauges para reduzir sensação de correria.
- O alvo é marcado antes do ataque para comunicar intenção.

## Visual de Batalha

O visual pode vir de duas fontes:

- Do `EnemyModelResource`, se `battleSpriteFrames` estiver preenchido.
- Do `AnimatedSprite2D` do inimigo do overworld, como fallback.

Se o modelo não especificar animação, o sistema tenta escolher uma animação `idle_*`. Se não houver, usa a primeira animação disponível.

Recomendações:

- Preferir animações `idle_down`, `idle_up`, `idle_right`, `attack_down`, `attack_up`, `attack_right`.
- Definir `battleScale` no modelo quando o sprite tiver escala própria na battle screen.
- Evitar depender do sprite do overworld quando o inimigo precisa de identidade visual própria.

## Recompensas

Recompensas ficam em `BattleRewardResource`.

Campos:

- `experience`
- `gold`
- `drops`
- `dropQuantities`

O `CharacterResource` base aponta para `battleReward`. Na vitória:

1. `battle_scene.gd` coleta os inimigos do grupo `enemy`.
2. `GameData.grant_battle_rewards()` soma XP/gold/drops.
3. XP é aplicado na party.
4. Gold e drops ficam persistidos em `GameData`.
5. A tela de vitória mostra resumo antes de retornar.

Derrota e fuga não concedem recompensa.

## Compatibilidade Legada

`enemy.gd` ainda aceita:

- `battle_resource`
- `battle_party`

Esses campos existem para cenas antigas. Para conteúdo novo, prefira:

- `battle_model`
- `battle_models`

O caminho novo evita compartilhamento de estado e facilita variações por instância.

## Checklist Para Devs

Ao criar inimigo novo:

- Criar/selecionar `CharacterResource` base.
- Criar `EnemyAIResource`.
- Criar `EnemyModelResource`.
- Definir `battle_model` ou `battle_models` no inimigo do overworld.
- Definir `encounter_id` único.
- Validar se o sprite aparece na battle screen.
- Testar vitória, fuga e reentrada.
- Conferir se HP/MP do inimigo reinicia em uma nova batalha.

## Checklist Para Agentes de IA

Ao editar esse sistema:

- Não remover compatibilidade com `battle_resource`/`battle_party` sem migração explícita.
- Não passar `CharacterResource` base direto para batalha quando houver modelo disponível.
- Duplicar recursos mutáveis antes de usar em combate.
- Preservar grupos `turnBasedAgents`, `player` e `enemy`.
- Preservar sinais de `TurnBasedAgent`, especialmente `target_selected`, `turn_finished`, `player_turn_started` e sinais de targeting.
- Não editar `.uid` manualmente.
- Em `.tscn`, preservar `ext_resource`, `sub_resource`, node names e grupos.
- Rodar `git diff --check` antes de finalizar.
- Se Godot estiver disponível, rodar `godot --headless --path . --quit`.

## Teste Manual Recomendado

1. Abrir `world/shroom-lands.tscn`.
2. Entrar na `DangerBox` do inimigo.
3. Confirmar que a batalha abre.
4. Confirmar que o inimigo usa o visual esperado.
5. Confirmar que só o Hero entra como player.
6. Observar o windup do inimigo e o alvo marcado antes da ação.
7. Vencer e confirmar recompensa.
8. Voltar ao overworld e confirmar que o inimigo derrotado não reaparece.

