extends Node2D
## O PATINHO (jogador).
##
## O que este script faz:
##   - lê as teclas (ou o deslize do dedo) e pula de tile em tile;
##   - morre se encostar num carro (nó "Hitbox") ou se ficar sobre a lama
##     sem estar em cima de uma tábua (nó "Feet" + mapa de tiles);
##   - é carregado junto quando está em cima de uma tábua;
##   - avisa o jogo (Main) com os sinais `died` e `reached_goal`.
##
## Este script NÃO sabe nada sobre vidas, tempo ou mensagens: isso é com o Main.
## Cena: res://scenes/duck.tscn

## Avisa que o patinho morreu. `cause` pode ser "car", "mud" ou "edge".
signal died(cause: String)
## Avisa que o patinho chegou ao lago de chegada.
signal reached_goal

## Tamanho de cada pulo, em pixels (igual ao tamanho do tile).
@export var tile_size := 64
## Duração da animação do pulinho, em segundos.
@export var hop_time := 0.12
## Distância mínima (px) para um arrasto contar como "deslizar" no celular.
@export var swipe_min_distance := 24.0

## Quantos frames de física esperamos depois de cada pulo antes de checar se
## o patinho caiu na lama. Motivo: a Godot demora um frame para avisar que o
## patinho encostou numa tábua; sem essa espera ele morreria ao pular nela.
const GRACE_FRAMES := 3

## false = patinho "congelado" (morto, ganhou ou esperando). Só se mexe se true.
var active := false

## A fase atual (scripts/level.gd). Definida pelo Main em setup().
var level: Node2D
## Retângulo onde o patinho pode andar (em pixels).
var play_area := Rect2()
## Tábuas que estão debaixo dos "pés" do patinho agora.
var planks: Array[Area2D] = []

var _grace := 0
var _tween: Tween
var _press_pos := Vector2.ZERO

@onready var sprite: Sprite2D = $Sprite2D


## Chamado pelo Main quando uma fase é carregada.
func setup(level_node: Node2D) -> void:
	level = level_node
	play_area = level.get_play_area()


## Coloca o patinho no ponto `pos` e deixa ele pronto para jogar.
func respawn(pos: Vector2) -> void:
	_stop_tween()
	position = pos
	scale = Vector2.ONE
	modulate = Color.WHITE
	sprite.rotation = 0.0
	planks.clear()
	_grace = GRACE_FRAMES
	active = true


# ---------------------------------------------------------------------------
# Controles
# ---------------------------------------------------------------------------
# As ações "move_up", "move_down"... estão em Projeto > Configurações do
# Projeto > Mapa de Entrada (setas e WASD).
func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return

	if event.is_action_pressed("move_up"):
		try_move(Vector2i.UP)
	elif event.is_action_pressed("move_down"):
		try_move(Vector2i.DOWN)
	elif event.is_action_pressed("move_left"):
		try_move(Vector2i.LEFT)
	elif event.is_action_pressed("move_right"):
		try_move(Vector2i.RIGHT)

	# Celular / mouse: deslizar na direção desejada. Toque rápido = pra frente.
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_press_pos = event.position
		else:
			_handle_swipe(event.position - _press_pos)


func _handle_swipe(d: Vector2) -> void:
	if d.length() < swipe_min_distance:
		try_move(Vector2i.UP)
	elif absf(d.x) > absf(d.y):
		try_move(Vector2i.RIGHT if d.x > 0.0 else Vector2i.LEFT)
	else:
		try_move(Vector2i.DOWN if d.y > 0.0 else Vector2i.UP)


## Pula um tile na direção `dir` (por exemplo Vector2i.UP).
func try_move(dir: Vector2i) -> void:
	if not active:
		return

	var target := position + Vector2(dir) * tile_size
	if not play_area.has_point(target):
		return  # não deixa sair da tela

	# Em terra firme o patinho "encaixa" no centro do tile. Na lama ele fica
	# onde está, porque a tábua pode estar parada em qualquer posição.
	if level.get_terrain(target) != "mud":
		target.x = (floorf(target.x / tile_size) + 0.5) * tile_size

	position = target
	sprite.rotation = atan2(float(dir.x), float(-dir.y))  # vira pra direção do pulo
	_grace = GRACE_FRAMES
	_play_hop()

	if level.get_terrain(position) == "goal":
		_win()


# ---------------------------------------------------------------------------
# Física: tábuas, lama e borda da tela
# ---------------------------------------------------------------------------
func _physics_process(delta: float) -> void:
	if not active:
		return

	# 1) Em cima de uma tábua? Então anda junto com ela.
	_remove_dead_planks()
	if not planks.is_empty():
		position.x += planks[0].speed * delta

	# 2) Espera um pouquinho depois de cada pulo (veja GRACE_FRAMES).
	if _grace > 0:
		_grace -= 1
		return

	# 3) Lama sem tábua = plof.
	if level.get_terrain(position) == "mud" and planks.is_empty():
		kill("mud")
		return

	# 4) A tábua levou o patinho pra fora da tela.
	if position.x < play_area.position.x or position.x > play_area.end.x:
		kill("edge")


func _remove_dead_planks() -> void:
	for i in range(planks.size() - 1, -1, -1):
		if not is_instance_valid(planks[i]):
			planks.remove_at(i)


# Estes métodos são chamados pelos sinais dos nós Hitbox e Feet.
# (As ligações estão em duck.tscn, aba "Nó" > "Sinais" do editor.)
func _on_hitbox_area_entered(_area: Area2D) -> void:
	# Hitbox só enxerga a camada "perigo" (carros e caminhões).
	kill("car")


func _on_feet_area_entered(area: Area2D) -> void:
	# Feet só enxerga a camada "tabua".
	planks.append(area)


func _on_feet_area_exited(area: Area2D) -> void:
	planks.erase(area)


# ---------------------------------------------------------------------------
# Morrer / ganhar / animações
# ---------------------------------------------------------------------------
## Mata o patinho. `cause`: "car" (atropelado), "mud" (caiu na lama),
## "edge" (a tábua levou ele pra fora da tela).
func kill(cause: String) -> void:
	if not active:
		return
	active = false
	_stop_tween()
	_tween = create_tween()
	if cause == "car":
		modulate = Color(1.0, 0.45, 0.45)
		_tween.tween_property(self, "scale", Vector2(1.7, 0.2), 0.25)  # achatado
	else:
		_tween.tween_property(self, "scale", Vector2.ZERO, 0.4)  # afunda
	died.emit(cause)


func _win() -> void:
	active = false
	_stop_tween()
	_tween = create_tween()
	_tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.15)
	_tween.tween_property(self, "scale", Vector2.ONE, 0.15)
	reached_goal.emit()


func _play_hop() -> void:
	_stop_tween()
	scale = Vector2(1.25, 0.8)  # "amassadinho" do pulo
	_tween = create_tween()
	_tween.tween_property(self, "scale", Vector2.ONE, hop_time)


func _stop_tween() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
