extends Area2D
## TÁBUA. Fica em cima da lama e leva o patinho junto.
##
## A tábua em si não se move: quem move é a Faixa (scripts/lane.gd), que
## também preenche a variável `speed` abaixo. O patinho (duck.gd) lê esse
## valor para andar na mesma velocidade da tábua.
##
## Esta cena está na camada de colisão "tabua" (camada 3).

## Velocidade horizontal em pixels por segundo. Preenchida pela Faixa.
var speed := 0.0
