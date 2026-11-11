@tool
extends Node3D


@export_tool_button("Load Track") var load_track := func () -> void:
    for child in track.get_children():
        child.queue_free()
    storage_service.load_track(track)

@onready var track: Node3D = $Track

var storage_service: StorageService


func _ready() -> void:
    storage_service = StorageService.new()
