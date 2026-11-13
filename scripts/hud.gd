extends CanvasLayer
## HUD: a parte "de cima" da tela (corações, nome da fase, tempo) e a
## mensagem grande do meio ("Parabéns!", "Fim de jogo!"...).
##
## Cena: res://scenes/hud.tscn. Para mexer no visual (fonte, cores, posição),
## abra a cena e edite os nós Label e TextureRect normalmente.

@onready var hearts: HBoxContainer = $TopBar/Hearts
@onready var level_label: Label = $TopBar/LevelLabel
@onready var time_label: Label = $TopBar/TimeLabel
@onready var dim: ColorRect = $Overlay/Dim
@onready var message: Label = $Overlay/Message


## Mostra `count` corações. Quantos cabem é definido pelos nós TextureRect
## dentro de TopBar/Hearts: para ter mais vidas, duplique um coração lá.
func set_lives(count: int) -> void:
	var i := 0
	for heart in hearts.get_children():
		heart.visible = i < count
		i += 1


func set_level_name(text: String) -> void:
	level_label.text = text


func set_time(seconds: float) -> void:
	time_label.text = "Tempo: %.1f s" % seconds


## Mostra uma mensagem grande no meio da tela. `with_dim` escurece o fundo.
func show_message(text: String, with_dim := true) -> void:
	message.text = text
	message.visible = true
	dim.visible = with_dim


func hide_message() -> void:
	message.visible = false
	dim.visible = false
