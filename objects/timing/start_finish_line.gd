class_name StartFinishLine
extends Node3D


var timer_dict: Dictionary[Car, float] = {}
var times_dict: Dictionary = {}
var best_time: float = INF

signal lap_completed


func _on_area_3d_body_entered(body: Node3D) -> void:
    var now: float = Time.get_unix_time_from_system()
    
    if timer_dict.has(body):
        var prev_time: float = timer_dict.get(body)
        var lap_time: float = now - prev_time
        var times: Array = times_dict.get(body)
        var new_best: bool = lap_time < best_time
        if new_best:
            best_time = lap_time
        times.push_back(lap_time)
        timer_dict.set(body, now)
        lap_completed.emit(now, lap_time, new_best)
    else:
        timer_dict.set(body, now)
        times_dict.set(body, [])
        lap_completed.emit(now)
