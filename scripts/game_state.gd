extends Node

signal score_changed(score: int)
signal high_score_changed(high_score: int)
signal coins_changed(coins: int)
signal kits_changed(kits: int)
signal health_changed(health: int, max_health: int)
signal player_died
signal game_restarted

const SAVE_PATH := "user://sonar_save.cfg"
const MAX_HEALTH := 100
const COIN_VALUE := 10
const KIT_HEAL := 30

var score: int = 0
var high_score: int = 0
var coins: int = 0
var kits: int = 0
var health: int = MAX_HEALTH
var is_game_over: bool = false


func _ready() -> void:
	load_high_score()


func reset_run() -> void:
	score = 0
	coins = 0
	kits = 0
	health = MAX_HEALTH
	is_game_over = false
	score_changed.emit(score)
	coins_changed.emit(coins)
	kits_changed.emit(kits)
	health_changed.emit(health, MAX_HEALTH)
	game_restarted.emit()


func add_score(points: int) -> void:
	if is_game_over or points <= 0:
		return
	score += points
	score_changed.emit(score)
	_try_update_high_score()


func add_coin(amount: int = 1) -> void:
	if is_game_over:
		return
	coins += amount
	coins_changed.emit(coins)
	add_score(COIN_VALUE * amount)


func add_kit(amount: int = 1) -> void:
	if is_game_over:
		return
	kits += amount
	kits_changed.emit(kits)


func try_consume_kit() -> bool:
	if is_game_over or kits <= 0 or health >= MAX_HEALTH:
		return false
	kits -= 1
	health = mini(MAX_HEALTH, health + KIT_HEAL)
	kits_changed.emit(kits)
	health_changed.emit(health, MAX_HEALTH)
	return true


func apply_damage(amount: int) -> void:
	if is_game_over or amount <= 0:
		return
	health = maxi(0, health - amount)
	health_changed.emit(health, MAX_HEALTH)
	if health <= 0:
		_on_death()


func heal(amount: int) -> void:
	if is_game_over or amount <= 0:
		return
	health = mini(MAX_HEALTH, health + amount)
	health_changed.emit(health, MAX_HEALTH)


func _on_death() -> void:
	if is_game_over:
		return
	is_game_over = true
	_try_update_high_score()
	player_died.emit()


func _try_update_high_score() -> void:
	if score > high_score:
		high_score = score
		save_high_score()
		high_score_changed.emit(high_score)


func load_high_score() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		high_score = int(cfg.get_value("progress", "high_score", 0))
	high_score_changed.emit(high_score)


func save_high_score() -> void:
	var cfg := ConfigFile.new()
	cfg.load(SAVE_PATH)
	cfg.set_value("progress", "high_score", high_score)
	cfg.save(SAVE_PATH)
