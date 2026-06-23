extends Control

func _on_play_pressed() -> void:
  get_tree().change_scene_to_file("res://world.tscn")

func _on_credits_pressed() -> void:
  var file := FileAccess.open("res://credits.txt", FileAccess.READ)
  if file:
    %CreditsText.text = file.get_as_text()
  %CreditsPopup.show()

func _on_close_pressed() -> void:
  %CreditsPopup.hide()
