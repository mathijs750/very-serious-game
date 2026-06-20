extends Control

var messages: Array[String] = [
  "They love it when I bark and fart 💖💖💖",
  "Woof Woof",
  "I think I'll become a square",
  "Tip: You can always feed me cheese",
  "*Sniff* *Sniff* *Sniff*"
]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
  update_text()

func update_text() -> void:
  %RichTextLabel.text = "[wave amp=50.0 freq=5.0 connected=1]%s[/wave]" % messages.pick_random()
