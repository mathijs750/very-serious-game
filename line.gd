extends MeshInstance3D

signal line_taut
signal line_length_changed(ratio: float)

@export var dog: Dog

@export_category("Line Properties")
@export var max_distance: float = 10.0
@export var startThickness: float = 0.1
@export var endThickness: float = 0.1
@export var capSmooth: int = 5
@export var drawCaps: bool = true
@export var scaleTexture: bool = true

@export_category("Line Material")
@export var lineMaterial: StandardMaterial3D

var geometry: ImmediateMesh
var camera: Camera3D
var cameraOrigin: Vector3
var _was_taut := false

func _ready() -> void:
  pass

func _process(_delta: float) -> void:
  if Engine.is_editor_hint():
    camera = get_editor_camera()
  else:
    camera = get_viewport().get_camera_3d()

  if camera == null or dog == null:
    return

  cameraOrigin = to_local(camera.get_global_transform().origin)

  var start := global_position
  var end := dog.collar.global_position if dog.collar else dog.global_position
  var distance := start.distance_to(end)

  var ratio = clamp(1.0 - distance / max_distance, 0.0, 1.0)
  line_length_changed.emit(ratio)

  var is_taut := distance >= max_distance
  if is_taut and not _was_taut:
    line_taut.emit()
  _was_taut = is_taut

  var A := to_local(start)
  var B := to_local(end)
  var AB := B - A
  var mid := (A + B) / 2.0
  var orthogonalStart := (cameraOrigin - mid).cross(AB).normalized() * startThickness
  var orthogonalEnd := (cameraOrigin - mid).cross(AB).normalized() * endThickness

  geometry = ImmediateMesh.new()
  geometry.clear_surfaces()
  geometry.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

  if drawCaps:
    cap(A, B, startThickness, capSmooth)

  if scaleTexture:
    var ABLen := AB.length()
    var ABFloor : float = floor(ABLen)
    var ABFrac := ABLen - ABFloor
    geometry.surface_set_uv(Vector2(ABFloor, 0))
    geometry.surface_add_vertex(A + orthogonalStart)
    geometry.surface_set_uv(Vector2(-ABFrac, 0))
    geometry.surface_add_vertex(B + orthogonalEnd)
    geometry.surface_set_uv(Vector2(ABFloor, 1))
    geometry.surface_add_vertex(A - orthogonalStart)
    geometry.surface_set_uv(Vector2(-ABFrac, 0))
    geometry.surface_add_vertex(B + orthogonalEnd)
    geometry.surface_set_uv(Vector2(-ABFrac, 1))
    geometry.surface_add_vertex(B - orthogonalEnd)
    geometry.surface_set_uv(Vector2(ABFloor, 1))
    geometry.surface_add_vertex(A - orthogonalStart)
  else:
    geometry.surface_set_uv(Vector2(1, 0))
    geometry.surface_add_vertex(A + orthogonalStart)
    geometry.surface_set_uv(Vector2(0, 0))
    geometry.surface_add_vertex(B + orthogonalEnd)
    geometry.surface_set_uv(Vector2(1, 1))
    geometry.surface_add_vertex(A - orthogonalStart)
    geometry.surface_set_uv(Vector2(0, 0))
    geometry.surface_add_vertex(B + orthogonalEnd)
    geometry.surface_set_uv(Vector2(0, 1))
    geometry.surface_add_vertex(B - orthogonalEnd)
    geometry.surface_set_uv(Vector2(1, 1))
    geometry.surface_add_vertex(A - orthogonalStart)

  if drawCaps:
    cap(B, A, endThickness, capSmooth)

  geometry.surface_end()
  geometry.surface_set_material(0, lineMaterial)
  mesh = geometry


func find_editor_cameras(nodes: Array, cameras: Array) -> void:
  for child in nodes:
    find_editor_cameras(child.get_children(), cameras)
    if child is Camera3D:
      cameras.push_back(child)


func get_editor_cameras() -> Array[Camera3D]:
  var ei = (EditorScript as Variant).new().get_editor_interface()
  var cameras: Array[Camera3D]
  find_editor_cameras(ei.get_editor_main_screen().get_children(), cameras)
  return cameras


func get_editor_camera() -> Camera3D:
  return get_editor_cameras()[0]


func cap(center: Vector3, pivot: Vector3, thickness: float, smoothing: int) -> void:
  var orthogonal := (cameraOrigin - center).cross(center - pivot).normalized() * thickness
  var axis := (center - cameraOrigin).normalized()
  var array: Array[Vector3] = []
  array.resize(smoothing + 1)
  array[0] = center + orthogonal
  array[smoothing] = center - orthogonal
  for i in range(1, smoothing):
    array[i] = center + orthogonal.rotated(axis, lerp(0.0, PI, float(i) / smoothing))
  for i in range(1, smoothing + 1):
    geometry.surface_set_uv(Vector2(0, float(i - 1) / smoothing))
    geometry.surface_add_vertex(array[i - 1])
    geometry.surface_set_uv(Vector2(0, float(i - 1) / smoothing))
    geometry.surface_add_vertex(array[i])
    geometry.surface_set_uv(Vector2(0.5, 0.5))
    geometry.surface_add_vertex(center)
