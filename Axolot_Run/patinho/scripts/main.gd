extends Node2D
## MAIN: o "diretor" do jogo. Cuida das regras gerais:
## carregar fases, contar vidas e tempo, reagir quando o patinho morre ou
## ganha, e reiniciar.
##
## Quem faz o quê:
##   Duck  (duck.gd)  -> se mexe, detecta colisão, avisa com sinais
##   Level (level.gd) -> descreve o mapa; é instanciada dentro de LevelHolder
##   HUD   (hud.gd)   -> desenha vidas, tempo e mensagens
##   Main  (este)     -> junta tudo

enum State { PLAYING, DYING, WON, GAME_OVER }

## Lista de fases, na ordem. Para adicionar uma fase nova, selecione o nó
## Main, abra o Inspetor e arraste a cena da fase para esta lista.
@export var levels: Array[PackedScene] = []

var state := State.PLAYING
var current_level := 0
var lives := 3
var elapsed := 0.0
var level: Node2D  # a fase que está rodando agora

@onready var level_holder: Node2D = $LevelHolder
@onready var duck: Node2D = $Duck
@onready var hud: CanvasLayer = $HUD
@onready var respawn_timer: Timer = $RespawnTimer


func _ready() -> void:
	load_level(0)


func _process(delta: float) -> void:
	if state == State.PLAYING:
		elapsed += delta
		hud.set_time(elapsed)


## Troca a fase atual pela fase de número `index` (começa em 0).
func load_level(index: int) -> void:
	current_level = index
	respawn_timer.stop()

	if level != null:
		level.queue_free()
	level = levels[index].instantiate()
	level_holder.add_child(level)

	lives = level.lives
	elapsed = 0.0
	state = State.PLAYING

	duck.setup(level)
	duck.respawn(level.get_start_position())

	hud.set_level_name(level.level_name)
	hud.set_lives(lives)
	hud.set_time(0.0)
	hud.hide_message()


# ---------------------------------------------------------------------------
# Teclas: "confirm" (ENTER/ESPAÇO) e "restart" (R) ficam no Mapa de Entrada.
# ---------------------------------------------------------------------------
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart"):
		load_level(current_level)
	elif event.is_action_pressed("confirm"):
		_confirm()
	# Celular: tocar na tela também confirma (quando o jogo pede ENTER).
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		if state == State.WON or state == State.GAME_OVER:
			_confirm()


func _confirm() -> void:
	if state == State.WON:
		var next := current_level + 1
		load_level(next if next < levels.size() else 0)
	elif state == State.GAME_OVER:
		load_level(current_level)


# ---------------------------------------------------------------------------
# Reações aos sinais do patinho.
# (As ligações estão em main.tscn, aba "Nó" > "Sinais" do editor.)
# ---------------------------------------------------------------------------
func _on_duck_died(cause: String) -> void:
	state = State.DYING
	lives -= 1
	hud.set_lives(lives)

	match cause:
		"car":
			hud.show_message("Ai! Foi atropelado!", false)
		"edge":
			hud.show_message("A tábua levou o patinho embora!", false)
		_:
			hud.show_message("Plof!", false)

	respawn_timer.start()  # quando acabar, chama _on_respawn_timer_timeout


func _on_respawn_timer_timeout() -> void:
	if lives <= 0:
		state = State.GAME_OVER
		hud.show_message("Fim de jogo!\n\nAperte ENTER para tentar de novo")
	else:
		hud.hide_message()
		duck.respawn(level.get_start_position())
		state = State.PLAYING


func _on_duck_reached_goal() -> void:
	state = State.WON
	var extra := "Aperte ENTER para jogar de novo"
	if current_level + 1 < levels.size():
		extra = "Aperte ENTER para a próxima fase"
	hud.show_message("Parabéns!\nO patinho chegou ao outro lago!\n\nTempo: %.1f s\n\n%s" % [elapsed, extra])
