class_name TrackEditorUtils
extends Object


static var grid_size: float = 8.0
static var delta_height: float = 3.0
static var sqrt_three: float = sqrt(3)
static var hex_coordinates_offset: Vector3i = Vector3i(10_000, 1_000, 10_000)


static func hex_coords_to_world_coords(hex_coords: Vector3i) -> Vector3:
    var hex_coords_without_offset = hex_coords - TrackEditorUtils.hex_coordinates_offset
    var world_coordinates: Vector3 = Vector3.ZERO
    world_coordinates.x = (hex_coords_without_offset.x + hex_coords_without_offset.z / 2.0) * TrackEditorUtils.grid_size * TrackEditorUtils.sqrt_three
    world_coordinates.y = hex_coords_without_offset.y * delta_height
    world_coordinates.z = hex_coords_without_offset.z * 1.5 * TrackEditorUtils.grid_size
    return world_coordinates


static func hex_coordinates_to_location_id(hex_coords: Vector3i) -> int:
    var location_id: int = (hex_coords.x << 32) | (hex_coords.y << 16) | hex_coords.z
    return location_id


static func location_id_to_hex_coordinates(location_id: int) -> Vector3i:
    var hex_coords: Vector3i = Vector3i(
        (location_id >> 32) & 0b1111111111111111,
        (location_id >> 16) & 0b1111111111111111,
        location_id & 0b1111111111111111)
    return hex_coords
