# Feature Specification: Grimório — Coletar Palavras, Preparar e Lançar Magias

**Feature Branch**: `feat/grimorio-foundation`

**Created**: 2026-06-02

**Status**: Draft

**Input**: User description: "Grimório: coletar palavras, preparar magias e save/load completo (issue #45) — steps 4-6, completando o vertical slice drop → coletar → preparar → cast em cima da foundation já commitada em 4aab1fd."

## Clarifications

### Session 2026-06-02

- Q: A tab "Grimório" dentro do inventário usa a mesma cena do autoload `WorldGrimoire`, uma view própria, ou substitui os outros caminhos? → A: Tab do inventário incorpora a mesma cena de `WorldGrimoire`; tecla G e botão HUD abrem a cena standalone. Uma única implementação visual de abas.
- Q: Como o anúncio de palavras ganhas se integra à tela de vitória existente (pop-up bloqueante, inline, toast, ou linha discreta)? → A: Inline na mesma tela de vitória, em seção própria abaixo dos drops de item (ex: "Palavras aprendidas: fire"). Um único passo, ritmo de combate preservado.
- Q: Que tipo de feedback aparece na aba Preparar quando a combinação de palavras não bate com nenhuma receita? → A: Mensagem inline persistente em `Label` abaixo do botão confirmar (ex: "Essa combinação não forma nenhuma magia"). Limpa quando a seleção muda. Sem dismiss explícito.
- Q: `known_words` e `prepared_spells` precisam de mecanismo extra para sobreviver à troca de cena dentro da mesma sessão? → A: Não — persistência intra-sessão é automática via autoload (`GameData` já vive entre cenas). Save/load cobre apenas a camada entre sessões.
- Q: Quando o grimório fica acessível ao jogador (sempre, gated pela primeira palavra, ou evento narrativo)? → A: Sempre disponível desde `main.tscn`. Catálogo vazio mostra mensagem amigável ("Você ainda não conhece nenhuma palavra. Vença batalhas para aprender."). Sem gate.

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Ganhar uma palavra ao vencer uma batalha (Priority: P1)

Ao derrotar um inimigo configurado para soltar palavras, o jogador recebe a(s) palavra(s) e elas passam a fazer parte do seu vocabulário conhecido. A tela de vitória anuncia visivelmente cada palavra ganha em inglês para reforçar a aprendizagem.

**Why this priority**: Sem aquisição de palavra, todo o resto do grimório fica inacessível — é o gatilho que alimenta as receitas, a preparação e o cast. É também o ponto onde o caráter educacional do jogo aparece pela primeira vez, então a entrega visível ao jogador é essencial.

**Independent Test**: Configurar um encontro de teste com `word_drops` contendo uma palavra ainda não conhecida, vencer a batalha e confirmar que (a) a tela de vitória anuncia a palavra, (b) a palavra aparece como conhecida na próxima vez que o grimório for aberto, (c) o save persiste a palavra ganha.

**Acceptance Scenarios**:

1. **Given** o jogador ainda não conhece a palavra "fire" **e** um inimigo com `word_drops` contendo "fire" está no encontro, **When** o jogador vence a batalha, **Then** a tela de vitória mostra "+1 palavra: fire" e "fire" passa a constar em `known_words`.
2. **Given** o jogador já conhece a palavra "fire" **e** o encontro dropa "fire" novamente, **When** o jogador vence a batalha, **Then** o sistema não duplica a palavra em `known_words` e a tela de vitória não anuncia "+1 palavra" para palavras já conhecidas.
3. **Given** o encontro não tem `word_drops` configurado, **When** o jogador vence a batalha, **Then** a tela de vitória mantém o fluxo atual de XP/gold/drops sem nenhuma menção a palavras.
4. **Given** o jogador vence uma batalha com palavras dropadas, **When** o jogo é fechado e reaberto, **Then** as palavras ganhas continuam em `known_words`.

---

### User Story 2 — Preparar uma magia combinando palavras conhecidas (Priority: P1)

Com pelo menos as palavras necessárias para uma receita, o jogador abre o grimório no overworld, vai à aba de preparação, seleciona 2 ou 3 palavras conhecidas e confirma. Se a combinação bate com uma receita registrada, a magia entra no rol de magias preparadas. Caso contrário, o jogo informa que a combinação não forma uma magia válida.

**Why this priority**: É a ponte entre coletar palavras e usá-las em combate. Sem preparação, palavras viram só itens de catálogo. Também é o momento onde o jogador exercita a combinação criativa de vocabulário, que é o coração da proposta educacional.

**Independent Test**: Com `known_words` já contendo {fire, ball} (via dev console ou save preparado), abrir o grimório pela tecla `G`, navegar para a aba Preparar, selecionar "fire" e "ball", confirmar, e validar que `prepared_spells` agora contém `fireball_recipe` e que esta passa a aparecer na lista de Receitas como preparada.

**Acceptance Scenarios**:

1. **Given** o jogador conhece "fire" e "ball" mas ainda não preparou Bola de Fogo, **When** abre o grimório, vai à aba Preparar, seleciona "fire" + "ball" e confirma, **Then** a magia Bola de Fogo é adicionada às magias preparadas e o jogo confirma o sucesso.
2. **Given** o jogador conhece apenas uma palavra de uma receita (ex: só "fire"), **When** tenta preparar com apenas "fire", **Then** o sistema rejeita a combinação informando que faltam palavras, sem alterar `prepared_spells`.
3. **Given** o jogador seleciona uma combinação de palavras que não corresponde a nenhuma receita registrada (ex: "fire" + "holy"), **When** confirma a preparação, **Then** o sistema informa "combinação inválida" e não adiciona nada a `prepared_spells`.
4. **Given** o jogador já tem Bola de Fogo preparada, **When** prepara "fire" + "ball" novamente, **Then** o sistema não duplica a magia em `prepared_spells`.
5. **Given** o jogador prepara uma magia, **When** o jogo é fechado e reaberto, **Then** a magia continua em `prepared_spells`.

---

### User Story 3 — Lançar magia preparada em batalha (Priority: P1)

Durante o turno do jogador, o menu de comandos oferece a opção "Magia". Selecionando-a, abre um submenu com as magias preparadas no grimório. Escolher uma magia executa-a sobre o alvo, usando a mesma pipeline de qualquer skill já existente (dano/cura, animação, custo de MP).

**Why this priority**: É a entrega final do loop. Sem cast, a preparação não tem consequência em jogo. Completar este caminho fecha o vertical slice e valida toda a cadeia.

**Independent Test**: Iniciar uma batalha com `prepared_spells` já contendo `fireball_recipe` (via cena de teste ou save), abrir o menu de comandos, escolher "Magia", selecionar Bola de Fogo, escolher alvo, e validar que o inimigo recebe o dano correspondente ao `result_skill` da receita e que a animação de skill toca normalmente.

**Acceptance Scenarios**:

1. **Given** o jogador tem Bola de Fogo em `prepared_spells` **e** está no seu turno em batalha, **When** seleciona o comando Magia, **Then** o submenu lista Bola de Fogo como opção selecionável.
2. **Given** o jogador seleciona Bola de Fogo no submenu Magia **e** escolhe um inimigo válido, **When** a ação é confirmada, **Then** a magia executa com a mesma pipeline de skill (animação, dano, consumo de MP).
3. **Given** o jogador não tem nenhuma magia em `prepared_spells`, **When** abre o menu de comandos em batalha, **Then** o botão Magia aparece desabilitado ou abre um submenu vazio com mensagem informativa, sem travar o turno.
4. **Given** o jogador não tem MP suficiente para a magia, **When** tenta selecioná-la, **Then** o sistema impede o uso com feedback claro (consistente com o tratamento atual de skills sem MP).

---

### User Story 4 — Consultar palavras e receitas conhecidas (Priority: P2)

Fora de batalha, o jogador pode abrir o grimório (tecla `G`, aba dentro do inventário, ou botão na HUD) e consultar duas listas: as palavras que já aprendeu (com tradução em PT e classe gramatical) e as receitas existentes — completas para as quais ele tem todas as palavras, parcialmente reveladas (`??? + ball`) para as quais ele tem só algumas, e ocultas para aquelas em que ele não conhece nenhuma palavra.

**Why this priority**: Reforça o aprendizado (revisão do vocabulário) e dá ao jogador uma direção sobre que palavras procurar. É essencial para a experiência educacional mas não bloqueia o loop drop→cast, então fica abaixo dos três P1.

**Independent Test**: Com um save contendo um subconjunto parcial de palavras (ex: {fire, holy}), abrir o grimório e validar que (a) a aba Palavras lista as duas com tradução e tipo, (b) a aba Receitas mostra `holy_light_recipe` como parcial (`holy + ???`) e `fireball_recipe` como parcial (`fire + ???`).

**Acceptance Scenarios**:

1. **Given** o jogador está no overworld e conhece pelo menos uma palavra, **When** pressiona `G`, **Then** o grimório abre pausando o tree (mesmo padrão do inventário).
2. **Given** o grimório está aberto, **When** o jogador pressiona `G` novamente, **Then** o grimório fecha e o tree volta a rodar.
3. **Given** o jogador abre o inventário pela tecla `I`, **When** clica na tab "Grimório", **Then** o grimório é exibido no contexto do inventário sem fechá-lo.
4. **Given** o jogador está no overworld, **When** clica no botão de grimório na HUD, **Then** o grimório abre da mesma forma que pela tecla `G`.
5. **Given** o jogador tem 3 palavras conhecidas, **When** abre a aba Palavras, **Then** as 3 aparecem listadas com texto em inglês, tradução em PT e tipo gramatical (quando configurado).
6. **Given** uma receita registrada cujo jogador conhece zero palavras, **When** o jogador abre a aba Receitas, **Then** essa receita não aparece (fica oculta até que pelo menos uma palavra seja conhecida).
7. **Given** uma receita cujo jogador conhece parte das palavras, **When** o jogador abre a aba Receitas, **Then** a receita aparece com palavras conhecidas visíveis e desconhecidas mascaradas como `???`.

---

### Edge Cases

- **Conflito grimório × diálogo/menu de batalha**: a tecla `G` deve ser ignorada (ou o grimório recusar abrir) enquanto um diálogo está em curso, durante batalha, ou em qualquer cena que pause o overworld. Mesmo princípio do guard atual do inventário.
- **Save corrompido ou ausente**: o grimório deve abrir mesmo sem nenhuma palavra/receita conhecida (estado limpo, sem crash), exibindo mensagem de catálogo vazio. Este caminho já é parcialmente coberto pelo save/load existente, mas precisa ser validado end-to-end depois das mudanças de UI.
- **Receita sem `result_skill` configurada**: deve ser tratada como dado inválido — não aparecer na aba Receitas e gerar log de aviso, sem quebrar a tela.
- **Word drop com referência nula** (ex: `.tres` movido/deletado): batalha vence normalmente; entrada nula é ignorada e logada, sem crash.
- **Tentativa de preparar a mesma receita duas vezes**: `prepared_spells` permanece com uma única entrada; o usuário recebe feedback de que a magia já está preparada.
- **Cast com MP insuficiente**: tratamento idêntico ao de skills hoje — não permite seleção / mostra feedback. (Não inventar fluxo novo.)
- **Inimigo dropando palavra que o jogador já conhece**: palavra não é re-adicionada; tela de vitória opcionalmente omite o anúncio para evitar ruído.

## Requirements *(mandatory)*

### Functional Requirements

#### Aquisição de palavra (User Story 1)
- **FR-001**: O sistema MUST permitir associar uma lista de palavras a um encontro como recompensa de vitória.
- **FR-002**: O sistema MUST adicionar a `known_words` toda palavra dropada e ainda não conhecida quando o jogador vence a batalha.
- **FR-003**: O sistema MUST evitar duplicatas em `known_words` — palavras já conhecidas não são re-adicionadas.
- **FR-004**: O sistema MUST exibir na tela de vitória existente, para cada palavra recém-adquirida, uma indicação textual em PT-BR contendo a palavra em inglês. O anúncio MUST aparecer inline em uma seção própria posicionada abaixo dos drops de item (ex: "Palavras aprendidas: fire"), sem introduzir pop-up bloqueante adicional nem passo extra de confirmação.
- **FR-005**: O sistema MUST persistir `known_words` no save automático após a vitória.

#### Preparação de magia (User Story 2)
- **FR-006**: O sistema MUST permitir ao jogador selecionar de 2 a 3 palavras conhecidas para tentar preparar uma magia.
- **FR-007**: O sistema MUST verificar a seleção contra o registro central de receitas de forma independente de ordem (multiset) e adicionar a magia correspondente a `prepared_spells` em caso de match.
- **FR-008**: O sistema MUST informar ao jogador, em PT-BR, quando a combinação selecionada não corresponde a nenhuma receita. O feedback MUST ser uma mensagem inline persistente em um `Label` posicionado abaixo do botão de confirmar (ex: "Essa combinação não forma nenhuma magia"), que limpa automaticamente quando a seleção de palavras muda, sem exigir dismiss explícito do jogador.
- **FR-009**: O sistema MUST recusar a preparação se alguma palavra selecionada não estiver em `known_words`.
- **FR-010**: O sistema MUST evitar duplicar entradas em `prepared_spells` quando o jogador prepara uma magia que já está preparada.
- **FR-011**: O sistema MUST persistir `prepared_spells` no save automático após uma preparação bem-sucedida.

#### Tela do grimório (User Stories 2 e 4)
- **FR-012**: O sistema MUST oferecer três caminhos de acesso ao grimório no overworld: tecla `G` (toggle), tab dedicada dentro do inventário, e botão clicável na HUD. Os três caminhos MUST exibir exatamente a mesma cena/UI de grimório (single source) — a tab do inventário incorpora a cena do autoload `WorldGrimoire`; tecla G e botão HUD abrem a mesma cena em modo standalone.
- **FR-013**: O sistema MUST pausar o tree do jogo enquanto o grimório está aberto, no mesmo padrão do inventário.
- **FR-014**: O sistema MUST recusar abrir o grimório enquanto outra UI bloqueante estiver ativa (diálogo, batalha, menu de game over).
- **FR-015**: O sistema MUST exibir todas as palavras de `known_words` na aba Palavras, com texto em inglês, tradução em PT e classe gramatical quando definida.
- **FR-016**: O sistema MUST exibir, na aba Receitas, todas as receitas para as quais o jogador conhece pelo menos uma palavra, mascarando as palavras desconhecidas como `???`.
- **FR-017**: O sistema MUST ocultar da aba Receitas qualquer receita cujo jogador não conhece nenhuma das palavras.
- **FR-018**: O sistema MUST diferenciar visualmente, na aba Receitas, receitas já preparadas das ainda não preparadas.
- **FR-019**: Todos os textos de interface do grimório MUST estar em PT-BR e usar a fonte default do Godot na gameplay (CuteFantasy apenas decorativa).
- **FR-019a**: O grimório MUST estar acessível desde o início do jogo, sem gate condicional. Quando `known_words` está vazio, a aba Palavras MUST exibir uma mensagem de catálogo vazio em PT-BR orientando o jogador a vencer batalhas para aprender palavras (ex: "Você ainda não conhece nenhuma palavra. Vença batalhas para aprender.").

#### Cast em batalha (User Story 3)
- **FR-020**: O sistema MUST adicionar um botão Magia ao menu de comandos de batalha, posicionado entre os comandos existentes Skills e Combo.
- **FR-021**: O submenu Magia MUST listar as magias atualmente em `GameData.prepared_spells`.
- **FR-022**: Selecionar uma magia preparada MUST executar a `SkillResource` correspondente (`result_skill` da receita) usando exatamente a mesma pipeline já em uso para skills (targeting, animação, dano/cura, consumo de MP).
- **FR-023**: O botão Magia MUST refletir estado vazio (desabilitado ou submenu com mensagem) quando `prepared_spells` está vazio, sem travar o fluxo de turno.

#### Save/load completo (transversal, fecha o step 3 da issue)
- **FR-024**: O sistema MUST persistir e restaurar end-to-end, num único ciclo de fechar e reabrir o jogo: party (HP/MP/level/XP), gold, inventário, encontros derrotados, estado da porta da cripta, `known_words` e `prepared_spells`.
- **FR-025**: O sistema MUST tolerar save ausente ou corrompido carregando os defaults sem crash, e validar este caminho após as adições de UI desta spec.

### Key Entities

- **WordResource** (já existente): palavra ensinada pelo jogo. Atributos: texto em inglês, tradução em PT, classe gramatical opcional, ícone opcional. Identidade conceitual pelo `text_en`.
- **SpellRecipeResource** (já existente): receita pré-definida que mapeia uma combinação não-ordenada de 2 a 3 `WordResource` a uma `SkillResource` resultante. Atributos: lista de palavras, skill resultante, descrição/lore.
- **SkillResource** (já existente, sem mudança): skill executada em batalha. Reutilizada como `result_skill` da receita.
- **BattleRewardResource** (existente, ganha campo novo): pacote de recompensas de vitória — XP, gold, drops de item, e agora também drops de palavra (`word_drops: Array[WordResource]`).
- **GameData** (existente, ganha métodos/integração): autoload que detém `known_words`, `prepared_spells` e o registro central `ALL_SPELL_RECIPES`, além de orquestrar save/load.
- **Tela do Grimório** (novo, autoload `WorldGrimoire`): UI que apresenta abas Palavras, Receitas e Preparar, com regras de acesso e visibilidade descritas em FR-012 a FR-019.
- **Comando Magia** (novo, integrado ao `CommandMenu`): entrada de menu em batalha que conecta `prepared_spells` à pipeline de cast.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Um jogador novo consegue executar o loop completo "vencer batalha com drop → preparar magia → lançar magia em batalha" em até 3 minutos a partir do momento em que abre o grimório pela primeira vez.
- **SC-002**: 100% das palavras configuradas como `word_drops` num encontro vitorioso aparecem em `known_words` ao final da tela de vitória.
- **SC-003**: 100% das receitas com todas as palavras conhecidas aparecem como preparáveis na aba Receitas; 0% das receitas sem nenhuma palavra conhecida aparecem na lista.
- **SC-004**: Após fechar e reabrir o jogo, 100% do estado salvo (party, inventário, gold, encontros, porta, palavras, magias preparadas) é restaurado idêntico ao snapshot anterior.
- **SC-005**: Em 100% dos casos de save ausente, corrompido ou com referência inválida, o jogo carrega no estado default sem crash e mantém todos os fluxos do grimório funcionais.
- **SC-006**: O grimório abre e fecha em até 200 ms percebidos pelo jogador (não bloqueia o tree por mais que um único frame perceptível) nos três pontos de acesso (tecla, tab, botão HUD).
- **SC-007**: O comando Magia, quando `prepared_spells` está vazio, nunca trava o turno do jogador — em 100% das tentativas o jogador pode voltar e escolher outro comando.

## Assumptions

- O save mora em `user://save.json`, conforme já implementado nos steps 1-3 da branch atual. Esta spec não introduz novo backend de persistência.
- Persistência intra-sessão (entre cenas dentro da mesma execução do jogo) de `known_words` e `prepared_spells` é automática via autoload `GameData`, no mesmo padrão de `defeated_encounters` e `gold`. Nenhum mecanismo adicional é introduzido — save/load é estritamente a camada entre sessões.
- As receitas vivem no registro central `GameData.ALL_SPELL_RECIPES`. Novas receitas no futuro serão registradas lá; esta spec não introduz mecanismo de plugin/dinâmico para receitas.
- O conjunto inicial de palavras e receitas (5 palavras, 2 receitas) já commitado na branch é suficiente para validar a spec; conteúdo adicional não é objetivo aqui.
- Drops de palavra acontecem apenas via vitória em batalha nesta spec. NPCs, baús, quests e outras fontes ficam fora (não-objetivo da issue #45).
- O cast em batalha reaproveita a pipeline atual de `SkillResource` sem alterações estruturais — qualquer comportamento que skills já têm (animação, MP, alvo) aplica-se igualmente às magias do grimório.
- A UI do grimório segue o padrão visual e comportamental já estabelecido pelo inventário do overworld (pausar tree, fonte default, toggle por tecla). Não há redesign do shell de UI nesta spec.
- O fluxo de game over real continua fora do escopo; esta spec assume o placeholder atual (retorno para `main.tscn`) sem mudanças.
- Múltiplos slots de save, edição/remoção de spells preparadas e combinação livre de palavras durante a batalha são explicitamente diferidos para issues de continuação.
