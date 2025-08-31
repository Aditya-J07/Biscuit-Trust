extends Node2D

@onready var botwin: Sprite2D = $botwin
@onready var playerwin: Sprite2D = $playerwin
@onready var outcome: Label = $outcome
@onready var camera: Camera2D = $Camera2D
@onready var click: AudioStreamPlayer2D = $Click
@onready var lost: AudioStreamPlayer2D = $Lost
@onready var win: AudioStreamPlayer2D = $Win
@onready var playerscore: Label = $playerscore
@onready var botscore: Label = $botscore
@onready var keep_button: TextureButton = $keep
@onready var scene: AnimationPlayer = %scene  # AnimationPlayer with "transition"

var playerpoints = 10
var botpoints = 10
var trust = 0
var game_over = false

# New variables for keep limit and reward
const MAX_INITIAL_KEEPS = 5
var keeps_left = MAX_INITIAL_KEEPS
var consecutive_shares = 0

func _ready():
	update_ui()
	outcome.text = "Click Keep or Share"
	playerwin.visible = false
	botwin.visible = false
	keep_button.visible = true  # start with keep visible

func _on_share_pressed():
	if game_over: return
	trust += 1
	consecutive_shares += 1

	# Every 2 shares = +1 keep
	if consecutive_shares % 2 == 0:
		keeps_left += 1
		if keeps_left > 0:
			keep_button.visible = true

	playround("share")
	click.play()

func _on_keep_pressed():
	if game_over: return
	if keeps_left <= 0:
		outcome.text = "No keeps left!"
		return

	trust -= 1
	keeps_left -= 1
	consecutive_shares = 0  # reset share streak

	if keeps_left <= 0:
		keep_button.visible = false

	playround("keep")
	click.play()

func playround(playerchoice: String):
	var botchoice = bot_decision()
	var result = ""

	var player_can_share = playerchoice == "share" and playerpoints > 0
	var bot_can_share = botchoice == "share" and botpoints > 0

	if player_can_share and bot_can_share:
		result = "both shared a biscuit! no change"
		flash_icons(true, true)

	elif player_can_share and not bot_can_share:
		playerpoints -= 1
		botpoints += 1
		result = "you shared, bot kept... you -1, bot +1"
		flash_icons(false, true)
		lost.play()
		shake_screen()

	elif not player_can_share and bot_can_share:
		botpoints -= 1
		playerpoints += 1
		result = "bot shared, you kept... you +1, bot -1"
		flash_icons(true, false)
		win.play()

	else:
		if playerchoice == "share" and playerpoints == 0 and botchoice != "share":
			result = "you tried to share but have 0 biscuits"
		elif botchoice == "share" and botpoints == 0 and playerchoice != "share":
			result = "bot tried to share but has 0 biscuits"
		else:
			result = "both kept biscuits! no change"

	check_game_over(result)

func check_game_over(result: String):
	if playerpoints <= 0:
		playerpoints = 0
		update_ui("bot wins! you lost all biscuits.")
		game_over = true
		await get_tree().create_timer(3.5).timeout
		scene.play("transition")
		await scene.animation_finished
		get_tree().change_scene_to_file("res://scenes/start.tscn")

	elif botpoints <= 0:
		botpoints = 0
		update_ui("you win! bot lost all biscuits.")
		game_over = true
		await get_tree().create_timer(3.5).timeout
		scene.play("transition")
		await scene.animation_finished
		get_tree().change_scene_to_file("res://scenes/start.tscn")

	else:
		update_ui(result)

func flash_icons(player_flash: bool, bot_flash: bool) -> void:
	if player_flash:
		playerwin.visible = true
	if bot_flash:
		botwin.visible = true
	await get_tree().create_timer(2.5).timeout
	playerwin.visible = false
	botwin.visible = false

func update_ui(result: String = "") -> void:
	playerscore.text = "you: %d (keeps : %d)   " % [playerpoints, keeps_left]
	botscore.text = "bot: %d" % botpoints
	outcome.text = result

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
		var offset = Vector2(randf_range(-10, 10), randf_range(-10, 10))
		tween.tween_property(camera, "offset", offset, 0.05)
		tween.tween_property(camera, "offset", Vector2.ZERO, 0.05)
