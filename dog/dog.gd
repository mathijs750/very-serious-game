extends CharacterBody3D

const SPEED := 5.0
const RAY_LENGTH := 1000.0
const ARRIVE_THRESHOLD := 0.05  # how close counts as "arrived"
const ROTATION_SPEED := 10.0  # higher = snappier turning

@export var camera: Camera3D

var target_pos: Vector3
var has_target := false


func _input(event: InputEvent) -> void:
  if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
    if event.pressed:
      _update_target(event.position)
    else:
      has_target = false

func _update_target(mouse_pos: Vector2) -> void:
  if not camera:
    push_warning("No camera attached to dog")
    return
  var space_state := get_world_3d().direct_space_state
  var from := camera.project_ray_origin(mouse_pos)
  var to := from + camera.project_ray_normal(mouse_pos) * RAY_LENGTH
  var query := PhysicsRayQueryParameters3D.create(from, to)
  query.collision_mask = 1
  var result := space_state.intersect_ray(query)
  if result:
    target_pos = result.position
    has_target = true

func _physics_process(delta: float) -> void:
  if has_target:
    $mouse.global_position  = target_pos

  if not is_on_floor():
    velocity += get_gravity() * delta

  if Input.is_action_pressed("left_mouse") and camera:
    _update_target(get_viewport().get_mouse_position())

  if has_target:
    var to_target := target_pos - global_position
    to_target.y = 0.0
    var distance := to_target.length()

    if distance > ARRIVE_THRESHOLD:
      var direction := to_target / distance  # normalized, avoids re-sqrt
      velocity.x = direction.x * SPEED
      velocity.z = direction.z * SPEED

      var target_angle := atan2(direction.x, direction.z)
      $mesh.rotation.y = lerp_angle($mesh.rotation.y, target_angle, ROTATION_SPEED * delta)
    else:
      velocity.x = move_toward(velocity.x, 0, SPEED)
      velocity.z = move_toward(velocity.z, 0, SPEED)
      has_target = false
  else:
    velocity.x = move_toward(velocity.x, 0, SPEED)
    velocity.z = move_toward(velocity.z, 0, SPEED)

  move_and_slide()
