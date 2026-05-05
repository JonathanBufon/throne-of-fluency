# HARNESS.md — Godot Vibe Coding com IA

## 1. Objetivo do Projeto

Este projeto é um jogo desenvolvido em Godot com apoio de IA.

A IA deve ajudar a implementar, corrigir e evoluir o jogo mantendo consistência entre:

* cenas `.tscn`
* scripts `.gd`
* autoloads
* inputs
* assets
* lógica de gameplay
* organização do projeto

O foco é evoluir o jogo em ciclos pequenos, testáveis e jogáveis.

---

## 2. Regra Principal

Nunca alterar muitas áreas do jogo ao mesmo tempo.

Cada tarefa deve ter um objetivo claro, por exemplo:

* criar movimentação do player
* corrigir pulo
* adicionar inimigo simples
* implementar câmera
* criar HUD
* melhorar feedback visual
* corrigir colisão
* organizar cenas

A IA deve evitar refatorações grandes sem necessidade.

---

## 3. Como a IA deve trabalhar

Para cada tarefa, a IA deve seguir este ciclo:

1. Ler o contexto do projeto.
2. Identificar quais cenas, scripts e recursos serão afetados.
3. Fazer a menor alteração funcional possível.
4. Explicar o que foi alterado.
5. Informar como testar dentro da Godot.
6. Não quebrar funcionalidades existentes.
7. Não remover nós, sinais, inputs ou scripts sem justificar.

---

## 4. Estrutura recomendada do projeto

Usar esta organização como referência:

```txt
res://
  scenes/
    player/
    enemies/
    levels/
    ui/
    props/

  scripts/
    player/
    enemies/
    systems/
    ui/

  assets/
    sprites/
    audio/
    fonts/
    tilesets/

  autoload/
    GameState.gd
    EventBus.gd
    SaveManager.gd

  resources/
    data/
    configs/
```

A IA deve respeitar a estrutura existente. Se ela não existir ainda, pode propor a criação gradual.

---

## 5. Convenções de Godot

### Cenas

Cada entidade importante deve ter sua própria cena:

* Player
* Enemy
* Projectile
* Level
* HUD
* Camera
* Interactable
* Collectible

Evitar colocar tudo em uma única cena gigante.

### Scripts

Cada script deve ter responsabilidade clara.

Exemplo:

```txt
Player.gd
PlayerMovement.gd
PlayerHealth.gd
EnemyAI.gd
HUD.gd
GameState.gd
```

Não misturar movimentação, vida, inventário, câmera e UI no mesmo script se o arquivo começar a ficar grande demais.

---

## 6. Regras para scripts GDScript

A IA deve:

* usar nomes claros
* evitar código mágico sem explicação
* usar `@export` para valores ajustáveis no editor
* validar nós com cuidado antes de acessar
* evitar dependência excessiva de caminhos absolutos
* preferir sinais quando houver comunicação entre sistemas
* não criar singletons/autoloads sem necessidade real

Exemplo bom:

```gdscript
@export var move_speed: float = 240.0
@export var jump_force: float = -420.0
```

Exemplo ruim:

```gdscript
velocity.x = 999
```

---

## 7. Inputs

Antes de usar uma ação de input, verificar se ela existe no projeto.

Inputs sugeridos:

```txt
move_left
move_right
move_up
move_down
jump
attack
dash
interact
pause
```

A IA não deve inventar nomes novos sem atualizar a documentação.

---

## 8. Física e movimentação

Para player 2D, preferir:

```txt
CharacterBody2D
```

Para objetos físicos:

```txt
RigidBody2D
```

Para colisões simples:

```txt
Area2D
StaticBody2D
CollisionShape2D
```

A IA deve preservar a separação entre:

* input
* cálculo de movimento
* animação
* colisão
* estado do personagem

---

## 9. Comunicação entre sistemas

Prioridade de comunicação:

1. chamada direta simples, quando os nós estão próximos
2. sinais, quando há eventos entre objetos
3. autoload/EventBus, apenas para eventos globais
4. GameState, apenas para estado global real

Não usar autoload como depósito de qualquer variável.

---

## 10. Regras para cenas `.tscn`

A IA deve tomar cuidado ao editar arquivos `.tscn`.

Preferência:

* criar scripts e orientar quais nós configurar manualmente
* editar `.tscn` somente quando necessário
* não apagar referências de scripts
* não alterar UID/import/resource path sem necessidade
* preservar grupos, sinais e nomes de nós existentes

Quando alterar uma cena, informar:

```txt
Cena alterada:
Nós adicionados:
Nós removidos:
Sinais conectados:
Como testar:
```

---

## 11. Loop de implementação

Cada tarefa deve terminar com:

```md
## O que foi feito

- ...

## Arquivos alterados

- ...

## Como testar na Godot

1. Abrir a cena ...
2. Clicar em Play
3. Verificar se ...

## Riscos

- ...

## Próximo passo sugerido

- ...
```

---

## 12. Regras para debug

Quando houver bug, a IA deve primeiro investigar antes de alterar.

Checklist:

```md
## Sintoma

O que acontece?

## Esperado

O que deveria acontecer?

## Hipóteses

1. ...
2. ...
3. ...

## Arquivos prováveis

- ...

## Correção mínima

- ...

## Como validar

- ...
```

Não sair reescrevendo o sistema inteiro.

---

## 13. Regras para gameplay

A IA deve priorizar sensação de jogo antes de complexidade.

Antes de adicionar sistemas grandes, validar:

* o player se move bem?
* a câmera acompanha bem?
* o pulo/ataque é responsivo?
* existe feedback visual?
* existe feedback sonoro?
* o objetivo da fase está claro?
* o loop básico é divertido?

---

## 14. Ordem ideal de desenvolvimento

Seguir esta ordem sempre que possível:

```txt
1. Player controlável
2. Câmera
3. Colisão básica
4. Fase de teste
5. Inimigo simples
6. Vida/dano
7. UI mínima
8. Condição de vitória/derrota
9. Feedback visual e sonoro
10. Polimento
11. Conteúdo extra
12. Menus
13. Save/load
```

Não começar por sistemas avançados antes do loop jogável.

---

## 15. Definição de pronto

Uma tarefa só está pronta quando:

* roda dentro da Godot
* não gera erro no console
* pode ser testada em uma cena
* não quebra o que já existia
* tem instrução clara de validação
* os arquivos alterados fazem sentido para a tarefa

---

## 16. O que a IA não deve fazer

A IA não deve:

* reescrever o projeto inteiro
* inventar arquitetura complexa cedo demais
* alterar várias cenas sem necessidade
* apagar arquivos sem pedir
* modificar assets importados manualmente
* criar autoloads para tudo
* misturar UI, gameplay e persistência no mesmo script
* criar sistemas genéricos antes de existir necessidade real
* prometer que algo funciona sem explicar como testar

---

## 17. Prompt padrão para usar com IA

Use este modelo para pedir tarefas:

```md
Você está trabalhando em um projeto Godot.

Leia o HARNESS.md antes de alterar qualquer coisa.

Tarefa:
[descrever tarefa]

Objetivo:
[resultado esperado no jogo]

Regras:
- faça a menor alteração funcional possível
- preserve cenas e scripts existentes
- não refatore fora do escopo
- explique os arquivos alterados
- informe como testar dentro da Godot

Ao final, responda com:
1. O que foi alterado
2. Arquivos modificados
3. Como testar
4. Riscos
5. Próximo passo sugerido
```

---

## 18. Prompt padrão para corrigir bugs

```md
Você está trabalhando em um projeto Godot.

Leia o HARNESS.md antes de alterar qualquer coisa.

Bug:
[descrever o problema]

Comportamento esperado:
[descrever o correto]

Comportamento atual:
[descrever o erro]

Regras:
- investigue antes de alterar
- não reescreva sistemas inteiros
- corrija com o menor patch possível
- preserve scripts, cenas, inputs e sinais existentes

Ao final, responda com:
1. Causa provável
2. Correção aplicada
3. Arquivos alterados
4. Como testar
5. Riscos restantes
```

---

## 19. Prompt padrão para criar uma feature

```md
Você está trabalhando em um projeto Godot.

Leia o HARNESS.md antes de alterar qualquer coisa.

Feature:
[descrever feature]

Contexto:
[explicar onde ela entra no jogo]

Critérios de aceite:
- ...
- ...
- ...

Regras:
- implementar primeiro a versão mais simples jogável
- usar @export para valores ajustáveis
- evitar dependências globais desnecessárias
- não criar arquitetura maior do que a feature exige
- informar como testar

Ao final, responda com:
1. Implementação feita
2. Arquivos alterados
3. Configurações necessárias no editor
4. Como testar
5. Próximo refinamento possível
```

---

## 20. Filosofia do projeto

Este projeto deve evoluir como um jogo jogável, não como uma arquitetura perfeita.

A prioridade é:

```txt
jogável > testável > organizado > escalável
```

A IA deve ajudar a manter ritmo de prototipação sem destruir a base do projeto.

---

## 21. Regra final de segurança

A IA nunca deve mexer em player, inimigo, câmera, HUD, estado global e cena principal na mesma tarefa.

Se uma tarefa parecer grande demais, dividir em subtarefas menores antes de implementar.
