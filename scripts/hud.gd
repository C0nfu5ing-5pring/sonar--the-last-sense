extends CanvasLayer

@onready var health_fill: ColorRect = $Root/HealthBar/Fill
@onready var health_label: Label = $Root/HealthBar/Label
@onready var score_label: Label = $Root/ScoreLabel
@onready var high_score_label: Label = $Root/HighScoreLabel
@onready var coins_label: Label = $Root/CoinsLabel
@onready var kits_label: Label = $Root/KitsLabel
@onready var hint_label: Label = $Root/HintLabel
@onready var game_over_panel: PanelContainer = $Root/GameOverPanel
@onready var game_over_label: Label = $Root/GameOverPanel/VBox/GameOverLabel
@onready var final_score_label: Label = $Root/GameOverPanel/VBox/FinalScoreLabel

var _bar_max_width: float = 200.0


func _ready() -> void:
	_bar_max_width = maxf(1.0, health_fill.offset_right - health_fill.offset_left)
	game_over_panel.visible = false
	GameState.health_changed.connect(_on_health_changed)
	GameState.score_changed.connect(_on_score_changed)
	GameState.high_score_changed.connect(_on_high_score_changed)
	GameState.coins_changed.connect(_on_coins_changed)
	GameState.kits_changed.connect(_on_kits_changed)
	GameState.player_died.connect(_on_player_died)
	GameState.game_restarted.connect(_on_game_restarted)
	_refresh_all()


func _refresh_all() -> void:
	_on_health_changed(GameState.health, GameState.MAX_HEALTH)
	_on_score_changed(GameState.score)
	_on_high_score_changed(GameState.high_score)
	_on_coins_changed(GameState.coins)
	_on_kits_changed(GameState.kits)


func _on_health_changed(health: int, max_health: int) -> void:
	var ratio := clampf(float(health) / float(max_health), 0.0, 1.0)
	health_fill.offset_right = health_fill.offset_left + _bar_max_width * ratio
	if ratio > 0.5:
		health_fill.color = Color(0.25, 0.85, 0.45)
	elif ratio > 0.25:
		health_fill.color = Color(0.95, 0.75, 0.2)
	else:
		health_fill.color = Color(0.9, 0.25, 0.25)
	health_label.text = "HP %d/%d" % [health, max_health]


func _on_score_changed(score: int) -> void:
	score_label.text = "Score: %d" % score


func _on_high_score_changed(high_score: int) -> void:
	high_score_label.text = "High: %d" % high_score


func _on_coins_changed(coins: int) -> void:
	coins_label.text = "Coins: %d" % coins


func _on_kits_changed(kits: int) -> void:
	kits_label.text = "Kits: %d  [E]" % kits


func _on_player_died() -> void:
	game_over_panel.visible = true
	game_over_label.text = "SIGNAL LOST"
	final_score_label.text = "Score %d   Best %d\nPress R to retry" % [GameState.score, GameState.high_score]


func _on_game_restarted() -> void:
	game_over_panel.visible = false
	_refresh_all()
