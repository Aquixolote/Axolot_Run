# Patinho Atravessa

Leve o patinho do lago de baixo até o lago de cima: atravesse a estrada sem ser
atropelado e pule nas tábuas pra cruzar a vala de lama.

Este projeto foi montado do jeito "normal" da Godot: cada coisa é uma **cena**
separada que você abre e edita no editor. Os scripts são curtos e comentados em
português.

## Como abrir
1. Instale a **Godot 4.3 ou mais nova** (precisa ser 4.3+ por causa do `TileMapLayer`).
2. Abra a Godot → **Importar** → escolha o `project.godot` desta pasta.
3. Aperte **F5** pra jogar.

**Controles:** setas ou WASD (pular), ENTER/ESPAÇO (continuar), R (reiniciar).
No celular: deslize o dedo; toque rápido = pra frente.

---

## O que tem em cada pasta

```
scenes/    as cenas (.tscn) - é aqui que você edita visualmente
  main.tscn         jogo completo (junta tudo)
  level_1.tscn ... level_6.tscn   as 6 fases: chão + faixas de carros e tábuas
  duck.tscn         o patinho
  car.tscn          carro        truck.tscn   caminhão
  plank.tscn        tábua longa  plank_short.tscn   tábua curta
  lane.tscn         "faixa": esteira que move carros/tábuas em fila
  hud.tscn          corações, tempo e mensagens
scripts/   a lógica (.gd), cada um ligado a uma cena
resources/ tileset.tres - a "paleta" de tiles usada pra pintar o chão
sprites/   os desenhos (PNG)
```

## As 6 fases

A dificuldade sobe aos poucos: mais faixas, carros mais rápidos, tábuas mais
espaçadas. Há também faixas mais lentas no meio, pra você ter que ler o trânsito.

| Fase | Nome | Estrada | Lama | O que muda |
|---|---|---|---|---|
| 1 | Do lago ao lago | 3 faixas | 2 faixas | introdução: tudo devagar |
| 2 | Trânsito pesado | 4 faixas | 2 faixas | uma faixa de estrada a mais, carros até 170 |
| 3 | Rio largo | 3 faixas | 3 faixas | lama mais longa, tábuas mais espaçadas |
| 4 | Duas travessias | 2 faixas | 2 + 2 faixas | você atravessa a lama duas vezes, com a estrada no meio |
| 5 | Hora do rush | 4 faixas | 3 faixas | carros até 220, caminhão rápido |
| 6 | Desafio final | 4 faixas | 4 faixas | tudo rápido: exige pular no ritmo certo |

Todas foram testadas: um robô joga cada fase na Godot (com a física de verdade)
e consegue zerar sem morrer. Ou seja, nenhuma fase é impossível.
Ao vencer a fase 6, o ENTER volta pra fase 1.

## Como as peças se encaixam

```
Main (main.tscn)  ........ regras: vidas, tempo, trocar de fase
├─ LevelHolder ........... a fase (level_1.tscn) entra aqui quando o jogo começa
│    └─ Level1
│        ├─ Ground ....... TileMapLayer: o chão pintado
│        ├─ PlayerStart .. onde o patinho nasce
│        └─ Lanes ........ faixas; cada uma tem carros OU tábuas dentro
├─ Duck (duck.tscn) ...... o jogador
├─ HUD (hud.tscn) ........ interface
└─ RespawnTimer .......... pausa depois que o patinho morre
```

Como eles conversam (aba **Nó → Sinais** no editor mostra isso):
- O **Duck** avisa o **Main** com os sinais `died` e `reached_goal`. O Main cuida
  de vidas, mensagens e de renascer o patinho.
- O Duck pergunta à **fase** qual é o terreno sob ele (`get_terrain`). O terreno
  vem do dado `terrain` de cada tile: `grass`, `road`, `lake`, `mud` ou `goal`.
- As **faixas** movem os carros/tábuas. As tábuas guardam a velocidade da faixa e
  o Duck a usa pra andar junto.

## Regras do jogo (resumo)
- **Carro** encostou no corpo do patinho → morre.
- **Lama** (tile `mud`) sem tábua debaixo dos pés → morre.
- Tábua levou o patinho pra fora da tela → morre.
- Pisar num tile `goal` → vitória.

---

## Receitas: como mudar as coisas

### Trocar um desenho (sprite)
Substitua o PNG em `sprites/` **mantendo o nome**, ou troque a textura no
Inspetor do nó Sprite2D da cena.

| Arquivo | O que é | Observação |
|---|---|---|
| `duck.png` | patinho | desenhe virado pra **cima**, 64x64 |
| `car_*.png` | carros | viradas pra **direita**, 128x64 |
| `truck.png` | caminhão | virado pra **direita**, 192x64 |
| `plank_2.png` / `plank_3.png` | tábuas | 128x64 / 192x64 |
| `heart.png` | vida | 32x32 |
| `tileset.png` | **chão**: 8 tiles de 64x64 lado a lado | veja abaixo |

Ordem dos tiles em `tileset.png` (da esquerda pra direita):
grama · grama com flor · estrada · estrada com faixa · lago · lago com vitória-régia ·
**lama** · **lago de chegada**. Se trocar a imagem, mantenha 8 tiles de 64x64 nessa ordem.

Se mudar o **tamanho** do PNG de um carro/tábua, ajuste também o `CollisionShape2D`
dele (a caixa de colisão) na cena.

### Mudar a velocidade ou a distância entre carros
Abra `level_1.tscn`, clique numa faixa (`Lanes/Lane_Row7_Cars`, por exemplo) e
mexa no Inspetor:
- `Speed`: pixels por segundo (negativo = vai pra esquerda)
- `Spacing`: distância entre o centro de um carro e o do próximo
- `Flip By Direction`: liga pra carros (viram pro lado em que andam), desliga pra tábuas

### Adicionar ou remover carros
Clique num carro dentro da faixa e aperte **Ctrl+D** para duplicar; arraste pelo
eixo X. Para trocar a cor, selecione o `Sprite2D` do carro e troque a `Texture`
(`car_blue.png`, `car_green.png`...). Mantenha carros suficientes pra cobrir a tela;
se um carro aparecer "do nada", falta carro na fila.

### Criar uma faixa nova
1. Em `Lanes`, adicione uma instância de `lane.tscn` (Ctrl+Shift+A, ou arraste o arquivo).
2. Posicione o **Y** no centro da linha: `linha × 64 + 32` (linha 7 → Y = 480).
3. Arraste `car.tscn`, `truck.tscn`, `plank.tscn`… para dentro da faixa e espalhe no X.
4. Preencha `Speed` e `Spacing`.

### Pintar o chão
Selecione o nó `Ground`, abra o painel **TileMap** (embaixo) e pinte. Cada tile já
sabe o que é (estrada, lama, chegada…), então a regra do jogo muda junto com a pintura.
Se pintar lama onde não há tábuas, o patinho vai morrer ali.

### Criar uma fase nova (a 7, por exemplo)
1. Abra a fase mais parecida com a que você quer (ex.: `level_6.tscn`) →
   **Cena → Salvar cena como…** → `level_7.tscn`.
2. Mude `Level Name`, `Lives`, pinte o chão e mexa nas faixas.
   Regra: toda linha de **estrada** precisa de uma faixa com carros e toda linha
   de **lama** precisa de uma faixa com tábuas (lama sem tábua mata o patinho).
3. Abra `main.tscn`, selecione o nó `Main` e, no Inspetor, aumente a lista `Levels`
   arrastando `level_7.tscn` pra ela. Ao vencer a fase 6, o ENTER leva pra 7.

Dica pra não criar fase impossível: pule você mesmo várias vezes. Se der pra
passar sem sorte, está boa. Tábuas curtas e muito espaçadas + muita velocidade
são o que mais deixa a fase injusta.

### Mais vidas
Mude `Lives` na fase e duplique um coração dentro de `HUD/TopBar/Hearts` (em `hud.tscn`).

### Deixar mais fácil ou difícil
Em `duck.tscn`, o `CollisionShape2D` dentro de `Hitbox` é a "área de dano" do
patinho (menor = mais fácil). O `Feet` é o quadradinho que precisa estar em cima da tábua.

### Mudar as teclas
**Projeto → Configurações do Projeto → Mapa de Entrada** (`move_up`, `move_down`,
`move_left`, `move_right`, `confirm`, `restart`).

---

## Camadas de colisão
Estão nomeadas em Configurações do Projeto → Nomes de Camada → Física 2D:

| Camada | Quem está nela | Quem enxerga |
|---|---|---|
| 1 `patinho` | Hitbox e Feet do patinho | — |
| 2 `perigo` | carros e caminhões | `Hitbox` do patinho |
| 3 `tabua` | tábuas | `Feet` do patinho |

Um objeto novo perigoso (um trem, por exemplo) só precisa estar na camada 2.

## Mini-glossário Godot
- **Cena (.tscn):** uma árvore de nós salva num arquivo; pode ser usada dentro de outras ("instanciar").
- **Nó:** cada bloquinho da árvore (Sprite2D, Area2D, Label…).
- **Inspetor:** painel da direita com as propriedades do nó selecionado. As
  variáveis `@export` dos scripts aparecem lá.
- **Sinal:** aviso que um nó manda quando algo acontece (ex.: "morri"). Outro nó
  se liga nele e reage.
- **Descrição do nó:** passe o mouse sobre os nós principais no editor para ler
  uma explicação (campo `editor_description`).
