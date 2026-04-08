**THRONE OF FLUENCY**

Documentação do Projeto

*RPG Educacional para Aprendizado de Inglês*

# **Visão Geral do Projeto**

Throne Of Fluency é um RPG top-down desenvolvido em Godot 4.6, pensado para aplicar clássicos do gênero RPG japonês em solo brasileiro. O jogo tem como objetivo ensinar inglês ao jogador através de vocabulários, desafios e puzzles integrados à narrativa.

Os combates acontecem em turnos e foram projetados para dar tempo ao jogador de pensar antes de agir, criando uma experiência educativa que não sacrifica o engagement.

**Inspirações:** Chrono Trigger, Final Fantasy, The Legend of Zelda

# **Stack Técnica**

| Engine | Godot 4.6 (GL Compatibility renderer) |
| :---- | :---- |
| **Linguagem** | GDScript |
| **Resolução** | 700×550, stretch mode canvas\_items |
| **Pixel Art** | Sprites 16×16 e 48×48, filtro de textura Nearest (sem suavização) |
| **Física** | 2D com CharacterBody2D para jogador e inimigos |

# **Worldbuilding & Lore**

## **O Olimpo das Gemas**

Muito antes dos reinos existirem, os deuses criaram as Gemas Primordiais. Essas gemas não eram apenas pedras mágicas — cada uma controlava um aspecto fundamental da civilização. Elas habitavam um plano celestial chamado O Olimpo das Gemas, um templo flutuante onde cada gema mantinha o equilíbrio do mundo.

Quando todas estavam em harmonia, os povos conviviam em paz, as culturas prosperavam e o conhecimento se espalhava.

### **O Erro do Rei Orc**

O mundo vivia em relativa paz até a ascensão do Rei Orc. Ele acreditava que destruir a Gema da Paz faria os reinos entrarem em guerra e assim ele dominaria tudo. Então ele invadiu o Olimpo das Gemas.

Mas no momento do ataque algo deu errado. Ao golpear o pedestal sagrado, ele atingiu a Gema errada. Não foi a Gema da Paz, mas sim a Gema do Diálogo.

Sem a Gema do Diálogo, os reinos começaram a não se entender, tratados de paz foram quebrados, cidades passaram a falar línguas diferentes e monstros começaram a aparecer. O mundo entrou em uma era de confusão linguística.

## **A Joia do Diálogo**

A gema se partiu em três fragmentos sagrados, cada um com poderes relacionados a diferentes aspectos da comunicação:

### **Auris – Gema da Escuta**

* Poder: Compreender sons, entender palavras faladas, decifrar vozes de criaturas

* No jogo: Desafios de listening

### **Vox – Gema da Conversação**

* Poder: Falar corretamente, comunicar intenções, usar palavras para ativar magias

* No jogo: Diálogos e escolha de palavras

### **Scriptum – Gema da Escrita**

* Poder: Escrever palavras antigas, abrir portões mágicos, registrar conhecimento

* No jogo: Formar palavras e completar frases

# **Os Deuses do Olimpo das Gemas**

Cada deus protege uma Gema Primordial, responsável por manter um aspecto fundamental da realidade. Os deuses não podem interferir diretamente no mundo, mas seus guardiões espirituais e mensageiros ajudam os mortais em suas jornadas.

## **Verbum — Deus da Linguagem**

**Guardião da Gema do Diálogo**

### **Domínios**

* Comunicação e palavras  
* Entendimento entre povos

### **Aparência**

Verbum se manifesta como um pequeno espírito de luz com forma de pergaminho e penas flutuantes. Seu corpo é feito de runas brilhantes, com fragmentos de letras girando ao seu redor. Emana uma pequena aura azul e sua voz ecoa palavras antigas.

### **Personalidade**

Verbum é sábio, paciente e curioso sobre os mortais. Acredita que a linguagem é a maior magia do mundo. Sua frase característica: "Palavras constroem pontes onde espadas apenas levantam muros."

### **Função no Jogo**

Quando a Gema do Diálogo foi destruída, Verbum perdeu grande parte de seu poder. Por isso, ele não consegue restaurar o mundo sozinho. Somente um mortal que aprenda as três artes da linguagem pode reconstruir a gema. Verbum envia Lumen para guiar o jogador.

**Revelação Final:** Verbum não é apenas um deus. Ele é na verdade a consciência da própria Gema do Diálogo. Quando a gema se quebrou, sua essência se separou do cristal.

## **Paxor — Deus da Paz**

**Guardião da Gema da Paz**

### **Domínios**

* Harmonia entre reinos  
* Tratados e acordos  
* Equilíbrio entre raças

### **Aparência**

Um espírito feito de luz branca com asas enormes. Símbolo: Pomba radiante

## **Ignivar — Deus da Coragem**

**Guardião da Gema da Coragem**

### **Domínios**

* Bravura e força interior  
* Inspiração de heróis e aventureiros

### **Aparência**

Um guerreiro feito de chamas douradas. Inspira aventureiros a enfrentar monstros.

## **Sylvara — Deusa da Natureza**

**Guardiã da Gema da Natureza**

### **Domínios**

* Florestas e ecossistemas  
* Criaturas vivas e equilíbrio natural

### **Aparência**

Uma entidade feita de folhas, raízes e flores que florescem em seus passos.

Quando a gema enfraquece: Monstros aparecem, florestas ficam corrompidas.

## **Menthor — Deus do Conhecimento**

**Guardião da Gema do Conhecimento**

### **Domínios**

* Sabedoria e história  
* Aprendizado e intelecto

### **Aparência**

Um ancião feito de estrelas e livros flutuantes. Conhece a história verdadeira das gemas.

## **Aequitas — Deusa da Justiça**

**Guardiã da Gema da Ordem**

### **Domínios**

* Leis e justiça  
* Equilíbrio entre poder e responsabilidade

### **Aparência**

Uma figura de pedra com olhos de cristal que veem através de todas as mentiras.

## **Glacien — Deus do Tempo**

**Guardião da Gema do Tempo**

### **Domínios**

* Passado, presente e futuro  
* Memória e destino  
* Visão de todos os eventos

### **Aparência**

Um ser translúcido com areia do tempo flutuando ao seu redor em padrões celestiais.

# **Lumen — Guia Enviado por Verbum**

Lumen é um pequeno espírito criado por Verbum especificamente para guiar aqueles destinados a restaurar a Gema do Diálogo. Em vez de Verbum aparecer sempre diretamente, ele envia Lumen como seu mensageiro, criando um personagem carismático que explica mecânicas e participa da aventura ao lado do jogador.

## **Aparência**

Lumen é um pequeno ser luminoso que flutua ao redor do jogador. Seu corpo é feito de luz azul brilhante, com pequenas letras flutuando ao seu redor. Símbolos antigos brilham quando ele fala, e duas pequenas asas de energia pura permitem que ele levite constantemente perto do ombro do personagem.

## **Personalidade**

Lumen é curioso, amigável e um pouco atrapalhado. Fica muito empolgado quando o jogador aprende uma palavra nova. Ele ainda está aprendendo sobre o mundo, assim como o jogador, criando uma dinâmica educativa natural.

**Frases típicas:** "Espere\! Acho que já ouvi essa palavra antes\!" "Tente escutar novamente… a resposta está no som." "Verbum ficaria orgulhoso\!"

## **Conexão com Verbum**

Lumen foi criado com um fragmento da energia de Verbum. Por isso ele consegue sentir fragmentos da Gema do Diálogo, perceber palavras antigas e entender idiomas esquecidos. Essa conexão também faz com que Lumen evolua conforme o jogador aprende.

## **Função no Jogo**

### **Tutorial e Mecânicas**

Lumen explica mecânicas novas de forma natural. Exemplo: "Essa porta antiga responde a palavras escritas. Talvez possamos reconstruir a palavra."

### **Dicas de Escuta**

Durante desafios de áudio, Lumen oferece ajuda. Exemplo: "Concentre-se… a primeira letra soa como S."

### **Ajuda com Escrita**

Se o jogador errar muito ao montar palavras: "Talvez devêssemos tentar outra ordem das letras."

### **Orientação de Missões**

Lumen indica onde procurar os fragmentos da gema e fornece contexto sobre os desafios que virão.

## **Evolução de Lumen**

Conforme o jogador aprende mais palavras e coleta os fragmentos da gema, Lumen também evolui:

| Progresso | Mudança em Lumen |
| :---- | :---- |
| Primeiras palavras | Pequenas letras começam a aparecer ao seu redor |
| Fragmento da Escuta (Auris) | Ondas sonoras começam a circular ao seu redor |
| Fragmento da Escrita (Scriptum) | Runas brilhantes começam a orbitar seu corpo |
| Fragmento da Conversação (Vox) | Aura brilhante mais intensa; sua voz ganha poder mágico |

## **Sistema de Energia Limitada**

Por ser uma criação de Verbum recebendo energia limitada, Lumen possui um limite de atividades que pode exercer por período. Isso força o jogador a aprender autonomamente:

* Ficar próximo das gemas recarrega a energia de Lumen  
* Mais próximo \= recarga mais rápida  
* O jogador deve usar o Glossário e aprender sozinho quando Lumen está fraco

# **Sistemas de Jogo**

## **Sistema de Combate**

Os combates são em turnos, projetados para dar ao jogador tempo de pensar antes de agir. O jogador inicia com:

* **Lâmina de Ferro Comum** – Espada equilibrada para força bruta  
* **Grimório de Marfim** – Livro de magias cujas páginas estão "trancadas" pelo caos linguístico

## **Sistema de Magia do Grimório**

Palavras individuais que o jogador aprende ficam registradas no Grimório como um glossário. Combinações de palavras formam magias. Exemplo: throw \+ fire \+ ball \= THROW FIRE BALL (magia de fogo)

Se o jogador tiver pré-montado o vocabulário de um encantamento, pode usá-lo rapidamente como skill. Caso contrário, pode tentar montar as palavras durante a batalha para "adivinhar" as magias.

**Mechânica de Aprendizado:** Quando o jogador acerta uma combinação, apenas uma palavra dessa magia é salva no Grimório. O jogador precisa recitá-la várias vezes até desbloquear a magia inteira, reforçando a aprendizagem.

## **Sistema de Glossário**

Um dicionário interativo que ajuda o jogador a se virar sem Lumen. Fornece contexto das frases e permite que o jogador tente interpretar o significado das palavras por conta própria, incentivando aprendizado autônomo.

# **Estrutura da Demo Inicial**

A demo inicial apresenta um cenário mínimo viável focado no aprendizado da língua:

## **Fase 1: Despertar no Sepulcro do Silêncio**

* Local: Cripta dos Ecos Perdidos  
* Objetivo: Tutorial de mecânicas e primeiro contato com a língua  
* Personagem-guia: Lumen  
* Primeiro desafio: Entender e usar o comando "PUSH TO OPEN" na porta

Nesta fase, o herói desperta como uma armadura vazia ressuscitada. Lumen o encontra e explica sua missão. O herói encontra dois objetos: a Lâmida de Ferro Comum e o Grimório de Marfim. A porta de pedra da cripta será o primeiro teste de compreensão linguística.

## **Fase 2: Aventura em ShorromLands**

* Local: ShorromLands (Floresta de Cogumelos)  
* Objetivo: Coletar a primeira gema (recomenda-se Auris – Gema da Escuta)  
* Exploração: Mundo aberto com NPCs, inimigos e puzzles de linguagem  
* Aprendizado: Vocabulários contextualizados para a floresta

# **Notas Importantes**

## **Design de Aprendizado**

O jogo combina entretenimento com educação através de:

* Vocabulários contextualizados em narrativa  
* Aprendizado através de mecânicas de jogo  
* Sistema de magia que reforça aprendizagem  
* Autonomia de aprendizado incentivada pelo sistema de energia limitada

## **Influências Diretas**

* **Chrono Trigger:** Sistema de combate em turnos e viagens no tempo  
* **Final Fantasy:** Estrutura de magia e customização  
* **The Legend of Zelda:** Exploração de mundo aberto e puzzles integrados

## **Documentação Viva**

Este documento é um trabalho em progresso. Conforme o desenvolvimento avança, será expandido com:

* Detalhes narrativos expandidos  
* Mais cenários e tier zones  
* Mecânicas avançadas  
* Design de diálogos e quests

*Documento Atualizado*

*Todas as informações do projeto compiladas e estruturadas | 2025*