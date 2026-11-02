extends Node3D


var timer_dict: Dictionary[Car, float] = {}
var times_dict: Dictionary= {}


func _on_area_3d_body_entered(body: Node3D) -> void:
    var now: float = Time.get_unix_time_from_system()
    
    if timer_dict.has(body):
        var prev_time: float = timer_dict.get(body)
        var lap_time: float = now - prev_time
        var times: Array = times_dict.get(body)
        times.push_back(lap_time)
        timer_dict.set(body, now)
        print("Lap Time: ", "%0.2f" % lap_time)
    else:
        timer_dict.set(body, now)
        times_dict.set(body, [])
