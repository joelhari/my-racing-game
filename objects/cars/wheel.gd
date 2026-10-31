class_name Wheel
extends RayCast3D


@export var wheel_radius: float = 0.275
@export var accelerates: bool = false
@export var breaks: bool = true

@export_group("Suspension")
@export var spring_strength: float = 10000.0
@export var spring_damping: float = 200.0
@export var rest_dist: float = 0.42
@export var over_extend: float = 0.2

@export_group("Tire")
@export var grip_curve: Curve
@export var static_firction: float = 5
@export var dynamic_friction: float = 1


@onready var mesh: Node3D = get_child(0)


func _ready() -> void:
    target_position.y = -(rest_dist + wheel_radius + over_extend)


func apply_wheel_physics_to_car(
    car: Car,
    accelerate_strength: float,
    break_strength: float,
    skid_mark: GPUParticles3D
) -> void:

    if not is_colliding():
        return


    # update the raycast target position
    target_position.y = -(rest_dist + wheel_radius + over_extend)

    # TODO: Instead of collision point, could use wheel.mesh.global_position
    # TODO: Decide wheater to apply the acceleration force at the center of
    #       the wheel or on the road contact point.
    #var contact: Vector3 = mesh.global_position
    var contact: Vector3 = get_collision_point()
    var contact_normal: Vector3 = get_collision_normal()
    
    #var contact_up: Vector3 = contact_normal
    var contact_forward: Vector3 = (-global_basis.z).slide(contact_normal)
    var contact_lateral: Vector3 = global_basis.x.slide(contact_normal)
    
    var wheel_velocity: Vector3 = car.get_point_velocity(contact)
    var wheel_forward_velocity: float = contact_forward.dot(wheel_velocity)
    var wheel_lateral_velocity: float = contact_lateral.dot(wheel_velocity)
    
    var force_vector: Vector3 = Vector3.ZERO
    
    # --------- Suspension --------------------------------------------------- #
    var spring_up_direction: Vector3 = global_basis.y
    var spring_length: float = global_position.distance_to(contact) - wheel_radius
    var offset: float = rest_dist - spring_length

    # update mesh position
    mesh.position.y = -spring_length

    var spring_force: float = spring_strength * offset

    var relative_velocity: float = spring_up_direction.dot(wheel_velocity)
    var spring_damping_force: float = spring_damping * relative_velocity

    # TODO: When back wheels are larger, e.g. the car is slightly tilted,
    #       applying the force in the spring up direction causes the car to move.
    var normal_force: Vector3 = (spring_force - spring_damping_force) * spring_up_direction
    force_vector += normal_force
    #force_vector += (spring_force - spring_damping_force) * contact_normal
    # ------------------------------------------------------------------------ #

    
    
    # --------- Acceleration ------------------------------------------------- #
    # TODO: With -wheel.global_basis.z, if the car is tilted upwards, the
    #       acceleratio force is tilted upwards too. Probably should go
    #       along the road surface?
    #var forward_direction: Vector3 = -global_basis.z
    
    #var wheel_forward_velocity: float = contact_forward.dot(car.linear_velocity)
    
    # TODO: improve wheels rotation (e.g., rotation when in the air)
    mesh.rotate_x(-wheel_forward_velocity * get_physics_process_delta_time() / wheel_radius)
    
    #if (not (wheel.accelerates and accelerate_input > 0) and
        #not (wheel.breaks and break_input > 0)):
            #return
    
    if accelerates and not is_zero_approx(accelerate_strength):
        force_vector += contact_forward * accelerate_strength
    
    if breaks and not is_zero_approx(break_strength):
        force_vector -= contact_forward * break_strength
    # ------------------------------------------------------------------------ #
    

    
    
    # --------- Lateral ------------------------------------------------- #
    var gravity: float = car.get_gravity().y
    var required_lateral_force: Vector3 = (
        contact_lateral * wheel_lateral_velocity * ((car.mass*gravity)/4.0))
    
    var lateral_force: Vector3 = Vector3.ZERO
    if required_lateral_force.length_squared() <= (static_firction * normal_force).length_squared():
        lateral_force = required_lateral_force
        skid_mark.emitting = false
    else:
        lateral_force = dynamic_friction * normal_force.length() * contact_lateral * -sign(wheel_lateral_velocity)
        skid_mark.global_position = contact + Vector3.UP * 0.01
        skid_mark.look_at(skid_mark.global_position + skid_mark.global_basis.z)
        skid_mark.emitting = true
    
    # TODO: rename this shit
    #var forward_traction: float = 0.05
    #var forward_force: Vector3 = contact_forward * wheel_forward_velocity * forward_traction * ((car.mass*gravity)/4.0)
    
    force_vector += lateral_force #+ forward_force
    # ------------------------------------------------------------------------ #
    
    
    
    #var force_position: Vector3 = contact - global_position
    #apply_force(force_vector, force_position)

    # TODO: Decide wheater to apply the suspension force at the center of
    #       the wheel or on the road contact point.
    contact = mesh.global_position
    var force_position: Vector3 = contact - car.global_position
    car.apply_force(force_vector, force_position)
