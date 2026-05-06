# HARNESS.md - Guia de trabalho com IA no Throne of Fluency

Este arquivo orienta agentes de IA e colaboradores ao alterar este projeto. Ele deve ser lido antes de qualquer mudança de código, cena, asset, backlog ou documentação.

O objetivo nao e criar uma arquitetura perfeita. O objetivo e manter o jogo jogavel, compreensivel e evoluindo em passos pequenos.

Prioridade do projeto:

```txt
jogavel > testavel > organizado > escalavel
```

---

## 1. Identidade do projeto

**Throne of Fluency** e um RPG educacional top-down em pixel art, feito em Godot 4.6, no qual o ingles e parte central da jogabilidade. O idioma deve aparecer como mecanismo de mundo: abre portas, guia magias, estrutura puzzles, informa dialogos e da sentido ao combate.

Pilares de design:

- RPG top-down com exploracao e combate por turnos.
- Ensino de ingles por contexto, repeticao e descoberta, nao por licao isolada.
- Combate intencional, com tempo para pensar, inspirado em Final Fantasy e Chrono Trigger.
- Puzzles linguisticos integrados ao cenario, como a porta da cripta com `PUSH TO OPEN`.
- Lumen como guia narrativo e mecanico do jogador.
- Pixel art sem suavizacao, com filtro `Nearest`.

Lore essencial:

- O mundo Lexicon entrou em colapso depois que o Rei Orc quebrou a Gema do Dialogo.
- A Gema do Dialogo se partiu em tres fragmentos: Auris, Vox e Scriptum.
- O heroi e uma armadura vazia guiada por Lumen, centelha criada por Verbum.
- O jogador aprende vocabulario junto com o heroi.

---

## 2. Fontes de verdade

Antes de implementar, consulte as fontes nesta ordem:

1. Estado atual do codigo e das cenas no repositorio.
2. `CLAUDE.md` para arquitetura e pendencias historicas.
3. `README.md` para visao geral publica do projeto.
4. `Throne_Of_Fluency_Documentacao.md` para lore e escopo de produto.
5. `backlog/*.md`, apenas quando existir localmente e a tarefa citar esse planejamento.

Se a documentacao divergir do codigo atual, o codigo atual vence para implementacao. Registre a divergencia no resumo final se ela afetar a tarefa.

`/backlog/` e local, ignorado pelo Git e nao deve subir para o GitHub.

---

## 3. Stack e configuracao real

- Engine: Godot 4.6.
- Renderer: GL Compatibility.
- Linguagem: GDScript.
- Main scene: `main.tscn`.
- Viewport atual no `project.godot`: `800x760`, stretch mode `canvas_items`.
- Fisica 2D: `CharacterBody2D` para player e inimigos de overworld.
- Texturas: pixel art com filtro `Nearest`.

Autoloads registrados:

- `GameData` -> `world/cripta/game_data.gd`
- `BattleTransition` -> `world/battle_transition.gd`

InputMap atual:

- `left`
- `right`
- `up`
- `down`
- `attack`
- `interact`
- Acoes nativas de UI do Godot usadas no combate/dialogo: `ui_accept`, `ui_cancel`, setas de UI quando aplicavel.

Layers 2D atuais:

- `terreno`
- `player`
- `inimigos`
- `fim_da_fase`

Nao invente novos inputs ou layers sem atualizar `project.godot` e documentar a necessidade.

---

## 4. Estrutura real do projeto

Convencao atual: cenas e scripts ficam co-localizados quando pertencem a uma entidade ou sistema.

```txt
actors/
  player/             Player do overworld
  enemy/              Inimigo de overworld e trigger de batalha
  lumen/              Companheiro Lumen

battleSystem/
  battle_scene.tscn   Cena de batalha parametrizavel
  battle_scene.gd
  core/               Controller, agent, character e templates
  data/               .tres de personagens e skills
  resources/          Classes Resource
  tests/              Cena isolada de teste do combate
  ui/                 Menu de comandos, status, ordem de turno

ui/
  dialog/             Dialogo e input linguistico

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

Nao reorganize pastas para seguir templates genericos como `scenes/` e `scripts/`. A estrutura acima e a base atual.

---

## 5. Fluxo de trabalho esperado

Para cada tarefa:

1. Leia este `HARNESS.md`.
2. Leia a documentacao relacionada e, se existir localmente, o backlog citado pela tarefa.
3. Inspecione arquivos reais antes de assumir arquitetura.
4. Liste mentalmente quais cenas, scripts e resources serao tocados.
5. Faca a menor alteracao funcional possivel.
6. Preserve nomes de nos, sinais, grupos e paths existentes.
7. Valide com Godot quando o binario estiver disponivel.
8. Informe o que mudou, como testar e riscos.

Se a tarefa for grande, divida em subtarefas. Uma feature transversal pode tocar mais de um sistema, mas cada alteracao dentro dela deve ser minima e justificada.

Evite:

- refatoracao ampla sem pedido explicito;
- renomear cenas/nos/scripts sem necessidade;
- apagar arquivos ou assets;
- alterar UIDs/imports de Godot manualmente;
- misturar mudancas de gameplay, UI e persistencia quando nao forem necessarias para o mesmo fluxo.

---

## 6. Edicao de cenas `.tscn`

Arquivos `.tscn` sao sensiveis. Edite diretamente apenas quando necessario.

Ao editar cenas:

- preserve `ext_resource`, `sub_resource`, sinais, grupos e nomes de nos existentes;
- nao mude UID/path/import sem motivo claro;
- prefira adicionar poucos nos e conectar sinais de forma explicita;
- confira o diff antes de finalizar;
- nao remova nodes herdados ou instanciados sem entender a cena.

Ao alterar uma cena, o resumo final deve indicar:

```txt
Cena alterada:
Nos adicionados:
Nos removidos:
Sinais conectados:
Como testar:
```

Quando Godot nao estiver no PATH, faca validacao estatica e declare que o teste manual na Godot ainda e necessario.

---

## 7. Sistema de overworld

Arquivos principais:

- `actors/player/player.gd`
- `actors/player/player.tscn`
- `actors/enemy/enemy.gd`
- `actors/enemy/enemy.tscn`
- `actors/lumen/lumen.gd`
- `world/world_scene.gd`
- `world/troca_fase.gd`
- `world/cripta/scenario.gd`
- `world/cripta/porta.gd`

Regras:

- Player e inimigos de overworld usam `CharacterBody2D`.
- O player entra no grupo `player`.
- Inimigos procuram o player via `get_tree().get_first_node_in_group("player")`.
- Cenas de mundo devem usar ou herdar a logica de `world/world_scene.gd` quando precisarem de retorno de batalha, reposicionamento e limpeza de encontros derrotados.
- Transicao normal entre mapas usa `world/troca_fase.gd` e `GameData.spawn_id`.

Nao coloque estado temporario de batalha em cenas de mundo. Use `BattleTransition`.

---

## 8. Fluxo overworld -> batalha -> overworld

Fluxo base implementado no codigo atual.

Arquivos principais:

- `world/battle_transition.gd`
- `actors/enemy/enemy.gd`
- `actors/enemy/enemy.tscn`
- `battleSystem/battle_scene.tscn`
- `battleSystem/battle_scene.gd`
- `battleSystem/core/enemy_battle_template.tscn`
- `world/world_scene.gd`
- `world/cripta/game_data.gd`

Fluxo atual:

1. Player entra na `DangerBox` do inimigo no overworld.
2. `enemy.gd` monta a party de combate usando `battle_party` ou `battle_resource`.
3. `BattleTransition.request_battle()` recebe inimigos, cena de retorno, posicao do player e `encounter_id`.
4. `BattleTransition` recebe dados visuais temporarios dos atores: `SpriteFrames`, animacao, frame, `flip_h` e escala quando aplicavel.
5. `BattleTransition.change_scene_with_fade()` troca para `battleSystem/battle_scene.tscn`.
6. `battle_scene.gd` instancia inimigos a partir de `BattleTransition.enemy_resources`.
7. `battle_scene.gd` aplica os `SpriteFrames` reais do inimigo e do player na battle screen.
8. `TurnBasedController` emite `battle_won` ou `battle_lost`.
9. Vitoria toca `dying` nos inimigos mortos, marca o encontro em `GameData.defeated_encounters` e retorna ao overworld.
10. Fuga toca `run_down` no player, retorna ao overworld sem marcar o encontro como derrotado.
11. Derrota toca `dying` nos players mortos e volta para `main.tscn` como placeholder de game over/save anterior.
12. `world_scene.gd` reposiciona player/Lumen e remove inimigos derrotados.

Regras importantes:

- `battleSystem/tests/test_battle_scene.tscn` deve continuar existindo para debug isolado.
- `TurnBasedController` descobre participantes por grupos, entao nao hardcode quantidade de inimigos.
- Todo inimigo de overworld que dispara batalha deve ter `battle_resource` ou `battle_party`.
- Use `encounter_id` unico quando possivel. O fallback baseado em path existe, mas IDs explicitos sao melhores para cenas editadas.
- Nao limpe `BattleTransition` antes da cena de mundo ler retorno, exceto em derrota/game over.
- A battle screen deve usar tela dedicada com fundo fixo, slots e UI inferior; nao mover o combate para o mapa de exploracao.
- Atores de batalha devem preferir `AnimatedSprite2D` com animacoes reais (`idle_*`, `attack_*`, `dying`, `run_down`) quando vierem do overworld.

---

## 9. Sistema de combate por turnos

Arquivos principais:

- `battleSystem/resources/skillResource.gd`
- `battleSystem/resources/character_resource.gd`
- `battleSystem/core/turn_based_agent.gd`
- `battleSystem/core/turn_based_controller.gd`
- `battleSystem/core/character.gd`
- `battleSystem/ui/command_menu.gd`
- `battleSystem/ui/player_status_display.gd`
- `battleSystem/ui/player_stats_container.gd`
- `battleSystem/ui/turn_order_bar.gd`

Resources:

- `CharacterResource`: dados de personagem, HP, MP, speed, OverDrive.
- `SkillResource`: dados de skill, alvo, tipo e poder.

Grupos usados pelo combate:

- `turnBasedAgents`
- `player`
- `enemy`
- `commandMenu`
- `turnBasedController`

Regras:

- Combate nao deve ser frenetico; preserve o tempo de decisao do jogador.
- `TurnBasedController` gerencia ordem e fim de batalha.
- `TurnBasedAgent` gerencia turno, targeting e IA por participante.
- `CommandMenu` so deve emitir comandos/eventos de UI; a cena/controlador decide consequencias globais.
- Nao remova suporte a `battle_won` e `battle_lost`.
- Ao adicionar skill, prefira `.tres` em `battleSystem/data/skills/`.
- Ao adicionar personagem de batalha, prefira `.tres` em `battleSystem/data/characters/`.
- `Run` e uma fuga funcional: anima o player com `run_down`, move para fora da arena e retorna ao overworld sem derrotar o encontro.
- Ao matar ator com `AnimatedSprite2D`, toque `dying` antes da tela de resultado e transicao de cena.

Ponto tecnico sensivel:

- `TurnBasedController._set_after_all_ready()` usa um pequeno delay para esperar agentes entrarem nos grupos. Se mudar spawn dinamico, garanta que inimigos sejam instanciados antes da montagem da fila.

---

## 10. Dialogo, porta e conteudo linguistico

Arquivos principais:

- `ui/dialog/dialog_screen.tscn`
- `ui/dialog/dialogo_acao_input.tscn`
- `ui/dialog/dialogo_acao_input.gd`
- `world/cripta/porta.gd`
- `world/cripta/cripta.tscn`

Regras:

- O puzzle da porta da cripta usa o conceito `PUSH TO OPEN`.
- Textos em ingles devem existir por motivo de gameplay ou narrativa.
- Evite hardcodar grandes blocos de texto educacional em scripts; prefira `.tres`, `.json` ou recursos dedicados quando o conteudo crescer.
- Quando hardcode temporario for inevitavel para prototipo, documente no resumo e mantenha localizado.
- Dialogos de Lumen devem favorecer ingles com apoio em portugues, conforme docs de produto.

Atencao:

- `porta.gd` pode depender de paths especificos da cena. Se mexer na cena, valide essa estrutura.

---

## 11. Autoloads e estado global

Use autoload apenas para estado ou comunicacao global real.

`GameData`:

- `spawn_id` para retorno entre cenas de mundo.
- `cripta_porta_aberta`.
- `defeated_encounters`.
- Deve guardar estado persistente simples do jogo.

`BattleTransition`:

- Payload temporario entre overworld e batalha.
- Guarda inimigos do encontro, cena de retorno, posicao do player, resultado e fade de transicao.
- Nao deve virar deposito permanente de progresso.

Regra pratica:

- Se o dado precisa sobreviver entre cenas por progresso do jogo, considere `GameData`.
- Se o dado existe apenas para atravessar uma transicao de batalha, use `BattleTransition`.
- Se o dado pertence a um personagem, skill ou inimigo, prefira `Resource`.

---

## 12. Assets e estilo visual

Regras:

- Nunca suavizar pixel art; preserve `Nearest`.
- Nao editar assets importados manualmente sem necessidade.
- Nao redistribuir ou duplicar asset pack fora do projeto.
- UI deve usar os assets em `assets/ui/` quando fizer sentido.
- Sprites de personagens ficam em `assets/sprites/characters/` e `assets/sprites/player/`.
- Tiles e cenario ficam em `assets/sprites/world/`.

Se adicionar asset:

- coloque na pasta coerente;
- explique origem/licenca se nao for asset ja existente;
- valide import no Godot quando possivel.

---

## 13. Backlog

Backlog fica em `backlog/`, mas e local e ignorado pelo Git.

Convenção:

```txt
NNN-slug-curto.md
```

Status:

- `Proposto`
- `Aprovado`
- `Em progresso`
- `Concluido`
- `Descartado`

Quando implementar uma tarefa do backlog:

- leia o arquivo inteiro antes de alterar codigo;
- preserve criterios de aceite ou explique mudancas;
- nao force add de arquivos de backlog;
- nao inclua backlog em commits ou PRs;
- se descobrir divergencia entre backlog e codigo atual, mencione no resumo.

---

## 14. Pronto para entrega

Uma tarefa so deve ser considerada pronta quando:

- a alteracao e pequena o suficiente para revisar;
- os arquivos tocados fazem sentido para o escopo;
- nao ha mudancas acidentais em `.tscn`, `.import`, UID ou assets;
- o fluxo principal afetado tem uma forma clara de teste manual;
- Godot foi executado sem erro, quando disponivel;
- se Godot nao estiver disponivel, isso foi declarado;
- riscos restantes foram listados.

Formato recomendado para resposta final:

```md
O que foi alterado:
- ...

Arquivos principais:
- ...

Como testar na Godot:
1. ...
2. ...
3. ...

Riscos:
- ...
```

Mantenha a resposta proporcional ao tamanho da mudanca.

---

## 15. Debug

Ao corrigir bug, investigue antes de alterar.

Checklist:

```md
Sintoma:

Esperado:

Hipoteses:

Arquivos provaveis:

Correcao minima:

Como validar:
```

Nao reescreva sistemas inteiros para corrigir sintomas pequenos.

---

## 16. Git e commits

Antes de commitar:

- rode `git status --short`;
- confira `git diff --stat`;
- garanta que so arquivos do escopo estao staged;
- use mensagem em Conventional Commits quando possivel.

Exemplos:

```txt
feat(battle): integrate overworld battle return flow
fix(enemy): prevent battle retrigger after fleeing
docs: update project harness
```

Nao misture docs, refactor e feature grande no mesmo commit sem necessidade.

---

## 17. O que nao fazer

Nao:

- reescrever o projeto inteiro;
- trocar a estrutura de pastas por uma arquitetura generica;
- criar autoload para qualquer variavel;
- hardcodar textos educacionais extensos em scripts;
- remover `test_battle_scene.tscn`;
- remover sinais de batalha sem substituir consumidores;
- quebrar o fluxo `GameData.spawn_id` de troca de fase;
- mexer em player, inimigo, batalha, UI e persistencia na mesma tarefa sem declarar que a feature e transversal;
- prometer que algo foi testado na Godot se o binario nao foi executado.

---

## 18. Prompt recomendado para tarefas

```md
Leia o HARNESS.md e, se existir localmente, o backlog relacionado antes de alterar.

Tarefa:
[descrever]

Objetivo no jogo:
[resultado esperado]

Critérios de aceite:
- ...

Regras:
- fazer a menor alteração funcional possível
- preservar cenas, grupos, sinais e inputs existentes
- não refatorar fora do escopo
- informar como testar na Godot
```

---

## 19. Lacunas conhecidas

Estas areas existem como produto planejado, mas ainda precisam de arquitetura consolidada:

- Sistema Lumen: energia, proximidade com gemas e traducao contextual.
- Sistema de Grimorio: palavras aprendidas e combinacoes para magias.
- Sistema de Glossario: dicionario interativo.
- Persistencia completa de HP/MP do player entre overworld e batalha.
- Game over real para derrota.
- XP/loot/tela de vitoria completa.

Ao trabalhar nessas areas, prefira primeiro um prototipo pequeno, jogavel e isolado. Depois consolide dados em `.tres` ou `.json` quando o comportamento estiver claro.
