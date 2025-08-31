extends Node2D
@onready var botwin: Sprite2D = $botwin
@onready var playerwin: Sprite2D = $playerwin
@onready var outcome: Label = $outcome
@onready var camera: Camera2D = $Camera2D
@onready var click: AudioStreamPlayer2D = $Click
@onready var lost: AudioStreamPlayer2D = $Lost
@onready var win: AudioStreamPlayer2D = $Win

var playerpoints = 5   # starting biscuits
var botpoints = 5
var trust = 0   # bot's trust in the player

func _ready():
	update_ui()
	outcome.text = "Click on either Keep or Share"

func _on_share_pressed():
	trust += 1      # player builds trust
	playround("share")
	click.playing = true

func _on_keep_pressed():
	trust -= 1      # player loses trust
	playround("keep")
	click.playing = true

func playround(playerchoice: String):
	var botchoice = bot_decision()
	var result = ""

	if playerchoice == "share" and botchoice == "share":
		playerpoints += 1
		botpoints += 1
		result = "Both shared a biscuit! +1 each"
		flash_icons(true, true)

	elif playerchoice == "keep" and botchoice == "share":
		playerpoints += 2
		botpoints -= 1
		result = "Player kept biscuits! Player +2, Bot -1"
		flash_icons(true, false)
		win.playing = true

	elif playerchoice == "share" and botchoice == "keep":
		botpoints += 2
		playerpoints -= 1
		result = "Bot kept biscuits! Bot +2, Player -1"
		shake_screen()
		flash_icons(false, true)
		lost.playing = true

	else:
		result = "Both kept biscuits! No change"

	update_ui(result)


func flash_icons(player_flash: bool, bot_flash: bool) -> void:
	if player_flash:
		$playerwin.visible = true
	if bot_flash:
		$botwin.visible = true

	await get_tree().create_timer(1.0).timeout

	$playerwin.visible = false
	$botwin.visible = false


func update_ui(result: String = "") -> void:
	$playerscore.text = "You: %d" % playerpoints
	$botscore.text = "Bot: %d" % botpoints
	$outcome.text = result
	


func bot_decision() -> String:
	var chance = randf()

	if trust > 3:
		return "share" if chance < 0.8 else "keep"
	elif trust > 0:
		return "share" if chance < 0.5 else "keep"
	else:
		return "share" if chance < 0.2 else "keep"

func shake_screen():
	var tween = create_tween()
	for i in range(3):
		var offset = Vector2(
			randf_range(-10, 10),
			randf_range(-10, 10)
		)
		tween.tween_property(camera, "offset", offset, 0.005)
		tween.tween_property(camera, "offset", Vector2.ZERO, 0.005)
