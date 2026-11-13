extends Node2D
## FAIXA: uma "esteira" de carros, caminhões ou tábuas que andam em fila.
##
## Como usar no editor:
##   1. Instancie res://scenes/lane.tscn dentro da fase.
##   2. Coloque a faixa na altura da linha (o Y do nó é o centro da linha).
##   3. Arraste carros/tábuas (cenas car.tscn, truck.tscn, plank.tscn...)
##      para dentro da faixa e posicione-os só no eixo X (Y = 0).
##   4. Ajuste `speed` e `spacing` no Inspetor.
##
## Todos os filhos da faixa se movem juntos. Quando um sai da tela, ele volta
## para o fim da fila, do outro lado, então o trânsito nunca acaba.
## Se aparecer carro "do nada" na tela, é porque faltam carros na fila:
## adicione mais (copie com Ctrl+D) até cobrir a tela inteira.

## Velocidade em pixels por segundo. Positivo = vai para a direita,
## negativo = vai para a esquerda.
@export var speed := 100.0

## Distância (em pixels) entre o centro de um carro e o do próximo.
## 0 = a faixa descobre sozinha olhando os dois primeiros filhos.
@export var spacing := 0.0

## Largura da área de jogo em pixels (15 tiles x 64 = 960).
@export var area_width := 960.0

## Quanto o objeto pode passar da borda da tela antes de voltar pra fila.
## Deve ser maior que metade do objeto mais largo.
@export var margin := 200.0

## Se ligado, os objetos viram para o lado em que estão andando. Use para
## carros e caminhões (desenhados virados pra direita). Desligue para tábuas.
@export var flip_by_direction := true


func _ready() -> void:
	var objects := get_children()
	if spacing <= 0.0:
		spacing = _detect_spacing(objects)

	for obj in objects:
		# Objetos com variável `speed` (as tábuas) recebem a velocidade da faixa.
		if "speed" in obj:
			obj.speed = speed
		if flip_by_direction and speed < 0.0:
			obj.scale.x = -1.0


func _physics_process(delta: float) -> void:
	var objects := get_children()
	for obj in objects:
		obj.position.x += speed * delta

	for obj in objects:
		if speed > 0.0 and obj.position.x > area_width + margin:
			# saiu pela direita -> vai para trás do último da fila (esquerda)
			obj.position.x = _edge_x(objects, obj, true) - spacing
		elif speed < 0.0 and obj.position.x < -margin:
			# saiu pela esquerda -> vai para trás do último da fila (direita)
			obj.position.x = _edge_x(objects, obj, false) + spacing


## Retorna o X do objeto que está mais à esquerda (want_min = true) ou mais à
## direita (want_min = false), ignorando `skip`.
func _edge_x(objects: Array, skip: Node2D, want_min: bool) -> float:
	var result := INF if want_min else -INF
	for obj in objects:
		if obj == skip:
			continue
		result = minf(result, obj.position.x) if want_min else maxf(result, obj.position.x)
	return result


## Calcula o espaçamento pela distância entre os dois primeiros objetos.
func _detect_spacing(objects: Array) -> float:
	if objects.size() < 2:
		return 300.0
	return absf(objects[1].position.x - objects[0].position.x)
