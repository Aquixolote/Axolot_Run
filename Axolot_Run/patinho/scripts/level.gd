extends Node2D
## FASE. Este script vai na raiz de cada cena de fase (level_1.tscn, ...).
##
## Uma fase é composta por:
##   - Ground      : TileMapLayer com o chão (grama, estrada, lama, lagos).
##                   Cada tile do tileset tem um dado personalizado chamado
##                   "terrain" ("grass", "road", "lake", "mud" ou "goal").
##   - Lanes       : as faixas de carros e de tábuas (lane.tscn).
##   - PlayerStart : ponto (Marker2D) onde o patinho nasce.
##
## O Main e o patinho conversam com a fase só pelas funções abaixo.

## Nome mostrado no topo da tela.
@export var level_name := "Fase"
## Quantas vidas o jogador tem nesta fase.
@export var lives := 3
## Tamanho da área de jogo, em tiles.
@export var columns := 15
@export var rows := 11
## Tamanho de cada tile, em pixels.
@export var tile_size := 64

@onready var ground: TileMapLayer = $Ground
@onready var start_point: Marker2D = $PlayerStart


## Retorna o tipo de terreno ("grass", "road", "lake", "mud" ou "goal")
## na posição `world_pos` (em pixels, coordenadas do mundo).
## Retorna "" se não houver tile ali.
func get_terrain(world_pos: Vector2) -> String:
	var cell := ground.local_to_map(ground.to_local(world_pos))
	var data := ground.get_cell_tile_data(cell)
	if data == null:
		return ""
	var terrain: String = data.get_custom_data("terrain")
	return terrain


## Onde o patinho nasce (posição do nó PlayerStart).
func get_start_position() -> Vector2:
	return start_point.global_position


## Retângulo da área de jogo, em pixels.
func get_play_area() -> Rect2:
	return Rect2(global_position, Vector2(columns, rows) * tile_size)
