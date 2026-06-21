extends CharacterBody3D

signal full_spin_completed(direction: int)  # -1 = clockwise, 1 = counter-clockwise
signal squat_started
signal squat_ended

@export var camera: Camera3D

const SPEED := 5.0
const RAY_LENGTH := 1000.0
const ARRIVE_THRESHOLD := 0.05  # avoid jitter
const ROTATION_SPEED := 10.0  # higher = snappier turning
const SPIN_THRESHOLD := TAU  # 360 degrees in radians

var target_pos: Vector3
var has_target := false
var _last_facing_angle := 0.0
var _accumulated_angle := 0.0
var _spin_direction := 0  # tracks which way we're currently spinning
var is_squatting := false


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

func _track_spin(new_angle: float) -> void:
  var delta_angle := wrapf(new_angle - _last_facing_angle, -PI, PI)
  _last_facing_angle = new_angle

  if abs(delta_angle) < ARRIVE_THRESHOLD:
    return

  var current_dir = sign(delta_angle)

  # if direction flips, reset accumulation so we get full circles
  if _spin_direction != 0 and current_dir != _spin_direction:
    _accumulated_angle = 0.0

  _spin_direction = current_dir
  _accumulated_angle += delta_angle

  if abs(_accumulated_angle) >= SPIN_THRESHOLD:
    full_spin_completed.emit(_spin_direction)
    _accumulated_angle = 0.0

func _start_squat() -> void:
  is_squatting = true
  has_target = false
  target_pos = global_position
  squat_started.emit()

func _end_squat() -> void:
  is_squatting = false
  squat_ended.emit()

func _physics_process(delta: float) -> void:
  if has_target:
    $mouse.global_position  = target_pos

  if not is_on_floor():
    velocity += get_gravity() * delta

  if Input.is_action_pressed("right_mouse"):
    if not is_squatting:
      _start_squat()
  else:
    if is_squatting:
      _end_squat()

  if is_squatting:
    # locked in place: no horizontal movement, but spinning on the spot
    # (via left-click target angle) still tracks and can complete spins
    velocity.x = move_toward(velocity.x, 0, SPEED)
    velocity.z = move_toward(velocity.z, 0, SPEED)

    if Input.is_action_pressed("left_mouse") and camera:
      _update_target(get_viewport().get_mouse_position())

    if has_target:
      var to_target := target_pos - global_position
      to_target.y = 0.0
      if to_target.length() > 0.01:
        var direction := to_target.normalized()
        var target_angle := atan2(direction.x, direction.z)
        $mesh.rotation.y = lerp_angle($mesh.rotation.y, target_angle, ROTATION_SPEED * delta)
        _track_spin($mesh.rotation.y)

    move_and_slide()
    return

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
      _track_spin($mesh.rotation.y)
    else:
      velocity.x = move_toward(velocity.x, 0, SPEED)
      velocity.z = move_toward(velocity.z, 0, SPEED)
      has_target = false
  else:
    velocity.x = move_toward(velocity.x, 0, SPEED)
    velocity.z = move_toward(velocity.z, 0, SPEED)

  move_and_slide()
