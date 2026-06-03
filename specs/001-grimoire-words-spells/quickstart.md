# Quickstart — Validação manual do grimório

**Feature**: Grimório — Coletar Palavras, Preparar e Lançar Magias
**Date**: 2026-06-02

Roteiro de smoke + golden path para validar a feature após implementação. Não substitui validação visual no editor — complementa.

---

## Pré-requisitos

- Branch `feat/grimorio-foundation` checked out.
- Godot 4.6 instalado (`godot --version`).
- Implementação dos artefatos descritos em `plan.md` concluída.

---

## 1. Smoke headless

Verifica que o projeto carrega sem erros após as mudanças.

```bash
godot --headless --path . --quit
```

Esperado: exit code 0, sem warnings novos sobre autoloads ou scripts.

```bash
godot --headless --path . --scene res://battleSystem/tests/test_battle_scene.tscn --quit-after 30
```

Esperado: cena de teste roda 30 segundos sem crash. Logs sem erros novos.

---

## 2. Golden path manual (editor aberto)

### 2.1 Preparar encontro de teste

Antes de rodar, garantir que pelo menos um `BattleRewardResource.tres` tem `word_drops` populado. Sugestão:

- `battleSystem/data/rewards/orc_grunt_reward.tres` → `word_drops = [ fire.tres, ball.tres ]`

Se o encontro do Orc Grunt está no `shroom-lands.tscn` (verificar antes), as duas palavras estarão prontas para preparar Bola de Fogo logo na primeira vitória.

### 2.2 Fluxo overworld → batalha → vitória

1. Abrir `main.tscn` no editor.
2. Play → entrar no menu principal → começar novo jogo.
3. Navegar até `shroom-lands.tscn` (ou cena que tenha o encontro com `word_drops` configurado).
4. Encostar no inimigo de teste, entrar em batalha.
5. Vencer a batalha.
6. **Confirmar na tela de vitória**:
   - Linha "Palavras aprendidas: fire, ball" aparece após os drops de item.
   - Sem pop-up extra, sem confirmação adicional.

### 2.3 Abrir o grimório (3 caminhos)

Após voltar ao overworld:

1. **Tecla G**: o grimório abre, tree pausa.
2. **Tecla G novamente**: fecha, tree volta a rodar.
3. **Tecla I + clicar na tab "Grimório"**: o conteúdo do grimório aparece dentro do inventário.
4. **Tecla I + tecla Esc**: inventário fecha.
5. **Clicar no botão Grimório na HUD**: abre o grimório standalone.

### 2.4 Conferir abas

Aba **Palavras**:
- `fire` (substantivo) e `ball` (substantivo) listadas com traduções em PT.

Aba **Receitas**:
- `fireball_recipe`: aparece como **disponível** (todas palavras conhecidas).
- `holy_light_recipe`: **não aparece** (zero palavras conhecidas).

Aba **Preparar**:
- Selecionar `fire` + `ball` → clicar Preparar.
- Feedback inline: "Magia preparada: Bola de Fogo."
- Voltar à aba Receitas: `fireball_recipe` agora mostra "Preparada ✓".

### 2.5 Cast em batalha

1. Encostar em outro inimigo (qualquer um) para entrar em batalha.
2. No turno do jogador, confirmar que o botão **Magia** aparece entre Skills e Combo, habilitado.
3. Clicar Magia → submenu lista "Bola de Fogo" com custo de MP.
4. Selecionar Bola de Fogo → escolher inimigo → confirmar.
5. **Confirmar**:
   - Animação de skill toca.
   - Inimigo recebe dano correspondente ao `power` da skill.
   - MP do jogador é consumido.

### 2.6 Persistência

1. Fechar o jogo (CMD+Q / fechar janela).
2. Reabrir, carregar `main.tscn`, continuar.
3. Abrir grimório → palavras `fire` e `ball` continuam listadas.
4. Receita Bola de Fogo continua "Preparada ✓".
5. Entrar em batalha → botão Magia continua listando Bola de Fogo.

---

## 3. Edge cases

### 3.1 Save corrompido

```bash
# Em uma janela separada
echo "lixo aleatório" > "$HOME/.local/share/godot/app_userdata/throne-of-fluency/save.json"
```

Abrir o jogo. Esperado: jogo carrega no estado default (party recém-criado, sem palavras), sem crash. Grimório abre normalmente e mostra mensagens de catálogo vazio em PT-BR.

### 3.2 Grimório vazio

Save novo (deletar `save.json`). Abrir grimório:
- Aba Palavras: "Você ainda não conhece nenhuma palavra. Vença batalhas para aprender."
- Aba Receitas: "Sem palavras, sem receitas conhecidas."
- Aba Preparar: botão Preparar desabilitado; "Aprenda palavras antes de preparar magias."

### 3.3 Conflito com diálogo

Em uma cena com diálogo ativo (ex: porta da cripta no `cripta.tscn`):
- Apertar G durante diálogo → grimório não abre (gate por `_can_open`).

### 3.4 Conflito com batalha

Em batalha, apertar G → grimório não abre (cena atual é `battle_scene.tscn`, não começa com `res://world/`).

### 3.5 Cast sem MP

Reduzir `currentMana` do jogador para 0 (via debugger ou item de teste). Entrar em batalha:
- Botão Magia continua habilitado (lista existe).
- No submenu, Bola de Fogo aparece como `disabled` com tooltip "needs N MP".

### 3.6 Receita parcial

Save manual com apenas `fire` em `known_words`. Abrir grimório → aba Receitas:
- `fireball_recipe`: aparece como "fire + ???".
- `holy_light_recipe`: não aparece (zero palavras).

---

## 4. Critérios de aceitação por User Story (mapeamento rápido)

| User Story | Passo do quickstart |
|---|---|
| US1 — Ganhar palavra em vitória | 2.2 |
| US2 — Preparar magia | 2.4 (aba Preparar) |
| US3 — Cast em batalha | 2.5 |
| US4 — Consultar palavras/receitas | 2.3 + 2.4 |
| Edge: save corrompido | 3.1 |
| Edge: catálogo vazio | 3.2 |
| Edge: conflito com diálogo/batalha | 3.3, 3.4 |
| Edge: MP insuficiente | 3.5 |
| Edge: receita parcial | 3.6 |
| Persistência completa entre sessões | 2.6 |
