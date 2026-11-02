class_name Car
extends RigidBody3D


@export var wheels: Array[Wheel]
var steering_wheels: Array[Wheel]
@export var skid_marks: Array[GPUParticles3D]
@export var model_scale: float = 1.0

@export_group("Engine")
@export var acceleration: float = 4000.0
# for now just limit the speed with this variable
@export var max_speed: float = 60.0
# TODO: use acceleration curve together with gears and rpm
@export var acceleration_curve: Curve

@export_group("Drive Train")
@export var breaking: float = 3500.0
@export var wheel_turn_speed: float = 2.0
@export var wheel_turn_angle_curve: Curve

signal current_car_speed
signal current_car_gear


# -1 = reverse, 0 = neutral, 1+ forward
var gear: int = 1


func get_point_velocity(point: Vector3) -> Vector3:
    return linear_velocity + angular_velocity.cross(point - global_position)


func _ready() -> void:
    steering_wheels = [$WheelFL, $WheelFR]
    current_car_gear.emit(gear)


func _input(event: InputEvent) -> void:
    if event.is_action_pressed("shift_up") and gear < 5:
        gear += 1
        current_car_gear.emit(gear)
    elif event.is_action_pressed("shift_down") and gear > -1:
        gear -= 1
        current_car_gear.emit(gear)


func _physics_process(delta: float) -> void:
    _do_steering(delta)
    
    var accelerate_input: float = Input.get_action_strength("accelerate")
    var break_input: float = Input.get_action_strength("break")
    var accelerate_strength: float = 0.0
    var break_strength: float = 0.0
    
    var velocity: float = -global_basis.z.dot(linear_velocity)
    # TODO: Implement forward gears
    if accelerate_input > 0 and gear != 0 and abs(velocity) < max_speed:
        accelerate_strength = sign(gear) * accelerate_input * acceleration
    if break_input > 0 and not is_zero_approx(velocity):
        break_strength = sign(velocity) * break_input * breaking
    
    current_car_speed.emit(int(velocity * 3.6 * model_scale))
    
    var grounded: bool = false
    
    for i in range(4):
        var wheel = wheels.get(i)
        wheel.force_raycast_update()
        wheel.apply_wheel_physics_to_car(
            self, accelerate_strength, break_strength, skid_marks.get(i))
        
        if wheel.is_colliding():
            grounded = true
        
        # TODO: Implement drag and friction
    
    if grounded:
        center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_AUTO
        center_of_mass = Vector3.ZERO
    else:
        center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
        center_of_mass = Vector3.DOWN * 0.2


func _do_steering(delta: float) -> void:
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
