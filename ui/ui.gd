extends Control

signal game_won
signal game_lost

const PATIENCE_MAX := (5 * 60.0)  # in seconds
const PATIENCE_DRAIN_NORMAL := 2.0   # patience units lost per second, not squatting
const PATIENCE_DRAIN_SQUAT := 0.5    # patience units lost per second, while squatting
const POOP_CHARGE_RATE := 0.08       # base poop_energy gain per second while squatting
const POOP_DISCHARGE_RATE := 0.15    # poop_energy lost per second while not squatting

var patience_left := PATIENCE_MAX
var poop_energy := 0.0  # Max 1.0

var is_squatting := false
var spin_multiplier := 1.0  # +1 per spin while squatting, resets when squat ends

var game_over := false

var messages: Array[String] = [
  "They love it when I bark and fart 💖",
  "Did you know: The developers added real wet dog smell to my model",
  "I buried a bone somewhere in the settings menu",
  "Tip: You can always feed me cheese",
  "*Sniff* *Sniff* *Sniff*",
  "*BARK* *BARK* >:D"
]

var messages_CW: Array[String] = [
  "Nyoom only forward",
  "Spinny :p",
  "Righty tighty",
  "Forwards!",
]

var messages_CCW: Array[String] = [
  "Turn back now!",
  "Un-spinny d:",
  "Lefty loosy",
  "Backwards!",
]

var messages_squat: Array[String] = [
  "*strains*",
  "Almost there...",
  "Nnnngh",
  "This might take a while",
]

var _generation := 0  # bump this any time pending timers should be invalidated


func _ready() -> void:
  # update_text()
  pass

func _process(delta: float) -> void:
  if game_over:
    return

  # --- patience drain ---
  var drain_rate := PATIENCE_DRAIN_SQUAT if is_squatting else PATIENCE_DRAIN_NORMAL
  patience_left = max(patience_left - drain_rate * delta, 0.0)
  if patience_left <= 0.0:
    _lose_game()
    return

  # --- poop energy charge / discharge ---
  if is_squatting:
    poop_energy = min(poop_energy + POOP_CHARGE_RATE * spin_multiplier * delta, 1.0)
    if poop_energy >= 1.0:
      _win_game()
      return
  else:
    poop_energy = max(poop_energy - POOP_DISCHARGE_RATE * delta, 0.0)

  _update_meters()


func _update_meters() -> void:
  if has_node("%Avatars"):
    if patience_left / PATIENCE_MAX < 0.75:
      %Avatars.get_child(1).show()
    elif patience_left / PATIENCE_MAX < 0.5:
      %Avatars.get_child(2).show()
    elif patience_left / PATIENCE_MAX < 0.25:
      %Avatars.get_child(3).show()

  if has_node("%PoopMeter"):
    %PoopMeter.set_value(poop_energy)


func _on_line_length_changed(ratio: float) -> void:
  if has_node("%LineMeter"):
    %LineMeter.value = ratio * 100.0



func _win_game() -> void:
  game_over = true
  game_won.emit()
  %ResultLabel.text = "You Win!"
  %EndScreen.show()


func _lose_game() -> void:
  game_over = true
  game_lost.emit()
  %ResultLabel.text = "Game Over!"
  %EndScreen.show()


func _on_restart_pressed() -> void:
  get_tree().change_scene_to_file("res://world.tscn")


func update_text() -> void:
  var my_gen := _start_new_cycle()

  #%DogBubble.hide()
  await get_tree().create_timer(5.0).timeout

  if not _is_current(my_gen):
    return  # a spin (or another call) happened while we were waiting — abandon this update

#  %DogBubble.show()
#  %DogBubble.get_child(0).text = "[wave amp=50.0 freq=5.0 connected=1]%s[/wave]" % messages.pick_random()
  $bark.play()

func _on_dog_full_spin_completed(direction: int) -> void:
  var my_gen := _start_new_cycle()  # invalidates the idle-text timer above

  if is_squatting:
    spin_multiplier += 1.0

#  if direction == 1:
#    %DogBubble.show()
#    %DogBubble.get_child(0).text = "[wave amp=50.0 freq=-1.0 connected=1]%s[/wave]" % messages_CCW.pick_random()
#  else:
#    %DogBubble.show()
#    %DogBubble.get_child(0).text = "[wave amp=50.0 freq=1.0 connected=1]%s[/wave]" % messages_CW.pick_random()
  $bark.play()

  await get_tree().create_timer(1.0).timeout

  if not _is_current(my_gen):
    return  # another spin happened before this 1s message finished showing

  #update_text()


func _on_dog_squat_started() -> void:
  is_squatting = true
  spin_multiplier = 1.0

  var my_gen := _start_new_cycle()  # invalidate idle-text timer
  #%DogBubble.show()
  #%DogBubble.get_child(0).text = "[wave amp=50.0 freq=3.0 connected=1]%s[/wave]" % messages_squat.pick_random()

  await get_tree().create_timer(1.0).timeout
  if not _is_current(my_gen):
    return


func _on_dog_squat_ended() -> void:
  is_squatting = false
  spin_multiplier = 1.0
  #update_text()


func _start_new_cycle() -> int:
  _generation += 1
  return _generation


func _is_current(gen: int) -> bool:
  return gen == _generation
