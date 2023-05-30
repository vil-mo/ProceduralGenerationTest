extends TileMap

var size = Vector2(22, 22)
var tiles_amount = 3

var k = 6
var noise := FastNoiseLite.new()


func _ready() -> void:
	generate_room()

func generate_room():
	noise.seed = randi()
	
	for x in size.x:
		for y in size.y:
			var value = tiles_amount * (noise.get_noise_2d(x * k, y * k) + 1) / 2
			
			set_cell(0, Vector2i(x, y), 0, Vector2i(floor(value), 0))
