class_name Car
extends RigidBody3D


@export var wheels: Array[Wheel]
var steering_wheels: Array[Wheel]
var accelerating_wheels: Array[Wheel]
@export var skid_marks: Array[GPUParticles3D]
@export var model_scale: float = 1.0

@export_group("Engine")
@export var acceleration: float = 50.0
# for now just limit the speed with this variable
@export var max_speed: float = 60.0
# TODO: use acceleration curve together with gears and rpm
@export var acceleration_curve: Curve
@export var torque_curve: Curve
@export var max_rpm: float = 7_000.0

@export_group("Gear Box")
@export var auto_gear_box: bool = true
@export_range(0.0, 6.0, 0.01) var gear_ratios: Array[float]

@export_group("Drive Train")
@export var final_drive_ratio: float = 4.0
@export var breaking: float = 3500.0
@export var wheel_turn_speed: float = 1.0
@export var wheel_turn_angle_curve: Curve

@onready var engine_sound: AudioStreamPlayer3D = $EngineSound

signal current_car_speed
signal current_car_gear
signal current_car_wheel_angle
signal current_car_rpm
signal current_car_wheel_lateral


# -1 = reverse, 0 = neutral, 1+ forward
var gear: int = 1


func get_point_velocity(point: Vector3) -> Vector3:
    return linear_velocity + angular_velocity.cross(point - global_position)


func _is_wheel_steering(wheel: Wheel) -> bool:
    return wheel.is_steering


func _is_wheel_accelerating(wheel: Wheel) -> bool:
    return wheel.is_accelerating


func _ready() -> void:
    steering_wheels = wheels.filter(_is_wheel_steering)
    accelerating_wheels = wheels.filter(_is_wheel_accelerating)
    current_car_gear.emit(gear)


func _input(event: InputEvent) -> void:
    if event.is_action_pressed("shift_up"):
        _shift_up()
    elif event.is_action_pressed("shift_down"):
        _shift_down()
    elif event.is_action_pressed("action_1"):
        auto_gear_box = !auto_gear_box

func _physics_process(delta: float) -> void:
    
    var accelerate_input: float = Input.get_action_strength("accelerate")
    var break_input: float = Input.get_action_strength("break")
    
    var velocity: float = -global_basis.z.dot(linear_velocity)
    
    var speed_kmh: float = velocity * 3.6 / model_scale
    current_car_speed.emit(speed_kmh)
    
    _do_steering(delta)
    
    var grounded: bool = false
    
    
    # --------- Acceleration ------------------------------------------------- #
    
    # calculate engine rpm to get engine force
    var accelerate_strength: float = 0.0
    
    var wheel_rpm: float = 0.0
    for wheel in accelerating_wheels:
        wheel_rpm += wheel.rpm
    wheel_rpm /= accelerating_wheels.size()
    
    var gear_ratio_idx: int = gear if gear > 0 else 0
    assert(gear_ratio_idx >= 0 and gear_ratio_idx < gear_ratios.size())
    var engine_rpm = wheel_rpm * gear_ratios.get(gear_ratio_idx) * final_drive_ratio
    current_car_rpm.emit(engine_rpm)
    engine_sound.pitch_scale = 1.0 + (engine_rpm / max_rpm) * 1.6
    
    if auto_gear_box:
        if engine_rpm >= max_rpm - 500:
            _shift_up()
        elif gear > 1 and engine_rpm <= 3_300:
            _shift_down()
        
    
    if accelerate_input > 0 and gear != 0:
        var engine_torque: float = (
            torque_curve.sample_baked(engine_rpm)
            if engine_rpm < max_rpm else 
            0.0
        )
        
        accelerate_strength = sign(gear) * accelerate_input * acceleration * engine_torque
    # ------------------------------------------------------------------------ #
        
    # --------- Breaking ----------------------------------------------------- #
    var break_strength: float = 0.0
    if break_input > 0 and not is_zero_approx(velocity):
        break_strength = sign(velocity) * break_input * breaking
    # ------------------------------------------------------------------------ #
    
    
    for i in range(4):
        var wheel = wheels.get(i)
        wheel.force_raycast_update()
        wheel.apply_wheel_physics_to_car(
            self, accelerate_strength, break_strength,
            skid_marks.get(i), delta)
        
        if wheel.is_colliding():
            grounded = true
        
        # TODO: Implement drag and friction
    current_car_wheel_lateral.emit(
        wheels.get(0).wheel_lateral, wheels.get(1).wheel_lateral,
        wheels.get(2).wheel_lateral, wheels.get(3).wheel_lateral)
    
    if grounded:
        center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_AUTO
        center_of_mass = Vector3.ZERO
    else:
        center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
        center_of_mass = Vector3.DOWN * 0.2


func _do_steering(delta: float) -> void:
    assert(steering_wheels.size() > 0)
    var steering_input: float = Input.get_axis("right", "left")
    
    if is_zero_approx(steering_input):
        var wheel_rotation = move_toward(
            steering_wheels.get(0).rotation.y, 0, wheel_turn_speed * delta)
        for wheel in steering_wheels:
            wheel.rotation.y = wheel_rotation
    else:
        # TODO: Implement max turn angle base on car velocity
        var velocity: float = abs(-global_basis.z.dot(linear_velocity))
        var turn_angle = steering_input * deg_to_rad(wheel_turn_angle_curve.sample_baked(velocity))
        var wheel_rotation = move_toward(
            steering_wheels.get(0).rotation.y, turn_angle,
            wheel_turn_speed * delta)
        for wheel in steering_wheels:
            wheel.rotation.y = wheel_rotation
    
    current_car_wheel_angle.emit(steering_wheels.get(0).rotation_degrees.y)


func _shift_up() -> void:
    if gear < gear_ratios.size() - 1:
        gear += 1
        current_car_gear.emit(gear)


func _shift_down() -> void:
    if gear > -1:
        gear -= 1
        current_car_gear.emit(gear)
