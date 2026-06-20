extends Control

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

var _generation := 0  # bump this any time pending timers should be invalidated


func _ready() -> void:
  update_text()


func update_text() -> void:
  var my_gen := _start_new_cycle()

  %RichTextLabel.text = ""
  await get_tree().create_timer(5.0).timeout

  if not _is_current(my_gen):
    return  # a spin (or another call) happened while we were waiting — abandon this update

  %RichTextLabel.text = "[wave amp=50.0 freq=5.0 connected=1]%s[/wave]" % messages.pick_random()


func _on_dog_full_spin_completed(direction: int) -> void:
  var my_gen := _start_new_cycle()  # invalidates the idle-text timer above

  if direction == 1:
    %RichTextLabel.text = "[wave amp=50.0 freq=-1.0 connected=1]%s[/wave]" % messages_CCW.pick_random()
  else:
    %RichTextLabel.text = "[wave amp=50.0 freq=1.0 connected=1]%s[/wave]" % messages_CW.pick_random()

  await get_tree().create_timer(1.0).timeout

  if not _is_current(my_gen):
    return  # another spin happened before this 1s message finished showing

  update_text()


func _start_new_cycle() -> int:
  _generation += 1
  return _generation


func _is_current(gen: int) -> bool:
  return gen == _generation
