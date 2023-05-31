extends TileMap

const BASE_LAYER = 0
const GROUND_LAYER = 1
const WALL_LAYER = 2

const BASE_ATLAS = 0
const USED_TERRAIN_SET = 0
const GROUND_TERRAIN = 0
const WALL_TERRAIN = 1

var size := Vector2i(20, 20)

var holes_amount : int = 3
var initial_ground_removing_amount : int = 4
var initial_ground_chance_to_be_removed : float = 0.17
var walls_amount : int = 3
var walls_neghbor_amount : int = 4
var walls_expanding_amount : int = 1
var walls_chance_to_be_expanded : float = 0.2
var connecting_land_connection_wideness : float = 1


const tiles := {
	empty = Vector2i(0, 0),
	ground = Vector2i(1, 0),
	wall = Vector2i(2, 0),
}

const SIDES_AND_CORNERS : Array[int] = [
	TileSet.CELL_NEIGHBOR_RIGHT_SIDE, 
	TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_CORNER,
	TileSet.CELL_NEIGHBOR_BOTTOM_SIDE, 
	TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_CORNER,
	TileSet.CELL_NEIGHBOR_LEFT_SIDE, 
	TileSet.CELL_NEIGHBOR_TOP_LEFT_CORNER,
	TileSet.CELL_NEIGHBOR_TOP_SIDE, 
	TileSet.CELL_NEIGHBOR_TOP_RIGHT_CORNER,
]
const SIDES : Array[int] = [
	TileSet.CELL_NEIGHBOR_RIGHT_SIDE, 
	TileSet.CELL_NEIGHBOR_BOTTOM_SIDE, 
	TileSet.CELL_NEIGHBOR_LEFT_SIDE, 
	TileSet.CELL_NEIGHBOR_TOP_SIDE, 
]

var waiting_time_for_demonstration = 0.5



func generate_room(should_connect_land : bool = true):
	
	
	# Filling all up ========================================================
	for x in range(-5, size.x + 5):
		for y in range(-5, size.y + 5):
			set_cell(BASE_LAYER, Vector2i(x, y), BASE_ATLAS, tiles.empty)
	
	for x in size.x:
		for y in size.y:
			set_cell(BASE_LAYER, Vector2i(x, y), BASE_ATLAS, tiles.ground)
	
	await get_tree().create_timer(waiting_time_for_demonstration).timeout
	# Making holes ==================================================
	
	var ground_cells := get_used_cells_by_id(BASE_LAYER, -1, tiles.ground)
	for i in holes_amount:
		set_cell(BASE_LAYER, ground_cells.pick_random(), BASE_ATLAS, tiles.empty)
	
	#Removing tiles at edges randomly
	
	for i in initial_ground_removing_amount:
		
		await get_tree().create_timer(waiting_time_for_demonstration).timeout
		
		ground_cells = get_used_cells_by_id(BASE_LAYER, -1, tiles.ground)
		
		var to_remove_coords : Array[Vector2i] = []
		
		for cell in ground_cells:
			var sides_maching : Array[Vector2i] = get_neighbors_of_atlas(BASE_LAYER, cell, [tiles.empty], SIDES_AND_CORNERS)
			if randf() < sides_maching.size() * initial_ground_chance_to_be_removed:
				to_remove_coords.append(cell)
		
		for coord in to_remove_coords:
			set_cell(BASE_LAYER, coord, BASE_ATLAS, tiles.empty)
	
	
	await get_tree().create_timer(waiting_time_for_demonstration).timeout
	# Smoothing ======================================
	const what_tile_becomes_if_too_many_sides := {
		tiles.empty : tiles.ground,
		tiles.ground : tiles.empty,
		tiles.wall : tiles.wall
	}
	
	var used_cells := get_used_cells(BASE_LAYER)
	var last_atlas := get_atlas_of_cells(BASE_LAYER, used_cells)
	
	for i in 10:
		var to_remove_coords : Array[Vector2i] = []
		
		for x in size.x:
			for y in size.y:
				var cell := Vector2i(x, y)
				var atlas := get_cell_atlas_coords(BASE_LAYER, cell)
				var sides_maching : Array[Vector2i] = get_neighbors_of_atlas(BASE_LAYER, cell, [atlas], SIDES)
				
				if sides_maching.size() <= 1:
					to_remove_coords.append(cell)
		
		for coord in to_remove_coords:
			set_cell(BASE_LAYER, coord, BASE_ATLAS, what_tile_becomes_if_too_many_sides[get_cell_atlas_coords(BASE_LAYER, coord)])
		
		var current_atlas := get_atlas_of_cells(BASE_LAYER, used_cells)
		if current_atlas == last_atlas:
			break
		last_atlas = current_atlas
	
	await get_tree().create_timer(waiting_time_for_demonstration).timeout
	# Walls instantiating ====================================
	ground_cells = get_used_cells_by_id(BASE_LAYER, -1, tiles.ground)

	for i in walls_amount:
		var current_wall = ground_cells.pick_random()
		set_cell(BASE_LAYER, current_wall, BASE_ATLAS, tiles.wall)
		for j in walls_neghbor_amount - 1:
			var random_neighbor := get_neighbor_cell(current_wall, SIDES_AND_CORNERS.pick_random())
			if tiles.ground == get_cell_atlas_coords(BASE_LAYER, random_neighbor):
				current_wall = random_neighbor
				set_cell(BASE_LAYER, current_wall, BASE_ATLAS, tiles.wall)
	
	# Expanding walls ====================================
	for i in walls_expanding_amount:
		
		await get_tree().create_timer(waiting_time_for_demonstration).timeout
		
		ground_cells = get_used_cells_by_id(BASE_LAYER, -1, tiles.ground)
		
		var to_expand_coords : Array[Vector2i] = []
		
		for cell in ground_cells:
			var wall_neighbors := get_neighbors_of_atlas(BASE_LAYER, cell, [tiles.wall], SIDES_AND_CORNERS)
			
			if randf() < wall_neighbors.size() * walls_chance_to_be_expanded:
				to_expand_coords.append(cell)
		for coord in to_expand_coords:
			set_cell(BASE_LAYER, coord, BASE_ATLAS, tiles.wall)
	
	await get_tree().create_timer(waiting_time_for_demonstration).timeout
	# Smoothing walls ====================================
	ground_cells = get_used_cells_by_id(BASE_LAYER, -1, tiles.ground)
	
	for cell in ground_cells:
		var wall_neighbors : Array[Vector2i] =  get_neighbors_of_atlas(BASE_LAYER, cell, [tiles.wall], SIDES)
		
		if wall_neighbors.size() >= 2:
			set_cell(BASE_LAYER, cell, BASE_ATLAS, tiles.wall)
	
	await get_tree().create_timer(waiting_time_for_demonstration).timeout
	# Filling up ground so that walls not near the empty ======================================
	
	used_cells = get_used_cells(BASE_LAYER)
	last_atlas = get_atlas_of_cells(BASE_LAYER, used_cells)
	
	while true:
		ground_cells = get_used_cells_by_id(BASE_LAYER, -1, tiles.ground)
		
		for cell in ground_cells:
			var wall_neighbors = get_neighbors_of_atlas(BASE_LAYER, cell, [tiles.wall], SIDES_AND_CORNERS)
			if wall_neighbors.size() > 0:
				for empty in get_neighbors_of_atlas(BASE_LAYER, cell, [tiles.empty], SIDES_AND_CORNERS):
					set_cell(BASE_LAYER, empty, BASE_ATLAS, tiles.ground)
		
		var current_atlas := get_atlas_of_cells(BASE_LAYER, used_cells)
		if current_atlas == last_atlas:
			break
		last_atlas = current_atlas
	
	await get_tree().create_timer(waiting_time_for_demonstration).timeout
	# Connecting land =======================================================
	
	if should_connect_land:
		var land : Array[Array] = get_land(BASE_LAYER, [tiles.ground])
		
		land.shuffle()
		
		for i in land.size() - 1:
			var land1 = land[i]
			var land2 = land[i + 1]
			var closest := find_closest_point_between_two_arrays(land1, land2)
			
			for cell in get_used_cells_by_id(BASE_LAYER, -1, tiles.empty):
				var point := Geometry2D.get_closest_point_to_segment(cell, closest[0], closest[1])
				if point.distance_squared_to(cell) <= connecting_land_connection_wideness:
					set_cell(BASE_LAYER, cell, BASE_ATLAS, tiles.ground)
	
	# Removing wall land =======================================================
	
	var wall_land := get_land(BASE_LAYER, [tiles.wall])
	var wall_and_ground_land := get_land(BASE_LAYER, [tiles.wall, tiles.ground])
	for l in wall_and_ground_land:
		for w in wall_land:
			if l == w:
				for cell in l:
					set_cell(BASE_LAYER, cell, BASE_ATLAS, tiles.empty)
	
	await get_tree().create_timer(waiting_time_for_demonstration).timeout
	# Smoothing up again ==================================================
	used_cells = get_used_cells(BASE_LAYER)
	last_atlas = get_atlas_of_cells(BASE_LAYER, used_cells)
	
	for i in 10:
		var to_remove_coords : Array[Vector2i] = []
		
		for x in size.x:
			for y in size.y:
				var cell := Vector2i(x, y)
				var atlas := get_cell_atlas_coords(BASE_LAYER, cell)
				var sides_maching : Array[Vector2i] = get_neighbors_of_atlas(BASE_LAYER, cell, [atlas], SIDES)
				
				if sides_maching.size() <= 1:
					to_remove_coords.append(cell)
		
		for coord in to_remove_coords:
			set_cell(BASE_LAYER, coord, BASE_ATLAS, what_tile_becomes_if_too_many_sides[get_cell_atlas_coords(BASE_LAYER, coord)])
		
		var current_atlas := get_atlas_of_cells(BASE_LAYER, used_cells)
		if current_atlas == last_atlas:
			break
		last_atlas = current_atlas
	
	
	# Making terrains ===========================================================
	
	ground_cells = get_used_cells_by_id(BASE_LAYER, -1, tiles.ground)
	var wall_cells = get_used_cells_by_id(BASE_LAYER, -1, tiles.wall)
	ground_cells.append_array(wall_cells)
	set_cells_terrain_connect(GROUND_LAYER, ground_cells, USED_TERRAIN_SET, GROUND_TERRAIN)
	set_cells_terrain_connect(WALL_LAYER, wall_cells, USED_TERRAIN_SET, WALL_TERRAIN)
	set_layer_enabled(BASE_LAYER, false)

func get_land(layer : int, land_consists_of : Array[Vector2i]) -> Array[Array]:
	var cells : Array[Vector2i] = []
	for a in land_consists_of:
		cells.append_array(get_used_cells_by_id(layer, -1, a))
	
	var analized : Array[Vector2i] = []
	var land : Array[Array] = []
	
	for cell in cells:
		if !cell in analized:
			land.append([])
			finding_land_recurtion(cell, land, land_consists_of)
			analized.append_array(land[-1])
	
	return land

func finding_land_recurtion(cell : Vector2i, land : Array[Array], atlas : Array[Vector2i]):
	if !cell in land[-1]:
		land[-1].append(cell)
		var neighbors = get_neighbors_of_atlas(BASE_LAYER, cell, atlas, SIDES)
		for neighbor in neighbors:
			finding_land_recurtion(neighbor, land, atlas)

func find_closest_point_between_two_arrays(a1 : Array, a2 : Array) -> Array:
	var points : Array[Array] = []
	var min_dist : float = INF
	for p1 in a1:
		for p2 in a2:
			var dist := Vector2(p1).distance_squared_to(p2)
			if dist < min_dist:
				min_dist = dist
				points.clear()
				points.append([p1, p2])
			elif is_equal_approx(dist, min_dist):
				points.append([p1, p2])
	return points.pick_random()

func get_neighbors_of_atlas(layer : int, cell : Vector2i, atlases : Array[Vector2i], neighbors_to_return : Array[int]) -> Array[Vector2i]:
	var neighbors_to_return_matching : Array[Vector2i] = []
	for side in neighbors_to_return:
		var neighbor := get_neighbor_cell(cell, side)
		if get_cell_atlas_coords(layer, neighbor) in atlases:
			neighbors_to_return_matching.append(neighbor)
	return neighbors_to_return_matching

func get_atlas_of_cells(layer : int, cells : Array[Vector2i]) -> Array[Vector2i]:
	var atlas_cells : Array[Vector2i] = []
	atlas_cells.resize(cells.size())
	
	for i in cells.size():
		var atlas : Vector2i = get_cell_atlas_coords(layer, cells[i])
		atlas_cells[i] = atlas
	
	return atlas_cells
