extends CharacterBody2D

@export var speed: float = 100.0
@export var player_node_path: NodePath
@export var attack_damage: float = 10.0
@export var attack_cooldown: float = 1.0 # Секунд между атаками
@export var max_health: float = 100.0

# Сигнал, который будет издан, когда враг умрет
signal died

var player: CharacterBody2D
var animated_sprite: AnimatedSprite2D
var damage_zone: Area2D
var attack_cooldown_timer: Timer
# var health_bar: ProgressBar # Убрали, так как полоска здоровья не нужна
var can_attack: bool = true
var _player_is_in_damage_zone: bool = false # Флаг нахождения игрока в зоне
var _knockback_vector: Vector2 = Vector2.ZERO # Для хранения вектора отталкивания
var _current_health: float # Приватная переменная для хранения здоровья

var current_health: float:
	get: return _current_health
	set(value):
		_current_health = clampf(value, 0.0, max_health)
		if _current_health <= 0.0 and not is_queued_for_deletion():
			_die()

func _ready() -> void:
	# В твоей сцене Enemy.tscn узел называется "Animation", так что эта строка верна
	animated_sprite = $Animation as AnimatedSprite2D
	if animated_sprite:
		animated_sprite.play("default") # Предполагается, что "default" - анимация ожидания/появления
	else:
		printerr("Враг '", name, "': узел AnimatedSprite2D не найден или имеет неверный тип.")

	# Находим узлы для атаки
	damage_zone = $DamageZone as Area2D
	attack_cooldown_timer = $AttackCooldownTimer as Timer
	# health_bar = $HealthBar as ProgressBar # Убрали

	# Устанавливаем начальное здоровье.
	self.current_health = max_health

	if not damage_zone:
		printerr("Враг '", name, "': узел Area2D с именем 'DamageZone' не найден.")
	else:
		damage_zone.body_entered.connect(_on_DamageZone_body_entered)
		damage_zone.body_exited.connect(_on_DamageZone_body_exited) # Подключаем сигнал выхода

	if not attack_cooldown_timer:
		printerr("Враг '", name, "': узел Timer с именем 'AttackCooldownTimer' не найден.")
	else:
		attack_cooldown_timer.wait_time = attack_cooldown
		attack_cooldown_timer.one_shot = true
		attack_cooldown_timer.timeout.connect(_on_AttackCooldownTimer_timeout)

	if player_node_path != null and not player_node_path.is_empty():
		var potential_player = get_node_or_null(player_node_path)
		if potential_player is CharacterBody2D:
			player = potential_player
		else:
			printerr("Враг '", name, "': узел по пути '", player_node_path, "' не является CharacterBody2D или не найден.")
	# Опционально: добавить поиск игрока по группе, если player_node_path не сработал
	if not is_instance_valid(player):
		var players_in_group = get_tree().get_nodes_in_group("player")
		if players_in_group.size() > 0 and players_in_group[0] is CharacterBody2D:
			player = players_in_group[0]
			print("Враг '", name, "' нашел игрока '", player.name, "' через группу.")
		elif player_node_path == null or player_node_path.is_empty(): # Сообщаем об ошибке, только если NodePath не был задан
			printerr("Враг '", name, "': PlayerNodePath не назначен и игрок не найден в группе 'player'.")

func _physics_process(delta: float) -> void:
	if is_instance_valid(player):
		var direction_to_player: Vector2 = (player.global_position - global_position).normalized()
		velocity = direction_to_player * speed

		# Логика атаки, если игрок в зоне
		if _player_is_in_damage_zone and can_attack:
			_try_attack_player()
	else:
		velocity = Vector2.ZERO

	# Применяем отталкивание, если оно есть
	if _knockback_vector != Vector2.ZERO:
		velocity += _knockback_vector
		_knockback_vector = Vector2.ZERO # Сбрасываем после применения

	move_and_slide()

func _on_DamageZone_body_entered(body: Node2D) -> void:
	if body == player and is_instance_valid(player): # Добавим проверку на валидность игрока
		_player_is_in_damage_zone = true

func _on_DamageZone_body_exited(body: Node2D) -> void:
	if body == player:
		_player_is_in_damage_zone = false

func _on_AttackCooldownTimer_timeout() -> void:
	can_attack = true

func _try_attack_player() -> void:
	if is_instance_valid(player) and player.has_method("take_damage"):
		player.take_damage(attack_damage)
		can_attack = false
		attack_cooldown_timer.start()
		print("Враг '", name, "' атаковал игрока. Перезарядка...")

func take_damage(amount: float) -> void:
	self.current_health -= amount
	# print("Враг '", name, "' получил ", amount, " урона. Осталось здоровья: ", _current_health)
	_show_damage_effect()

func _die() -> void:
	emit_signal("died")
	# Здесь можно запустить анимацию смерти, создать эффекты и т.д.
	# После анимации смерти нужно будет удалить врага:
	queue_free()

func apply_knockback(direction: Vector2, strength: float) -> void:
	# Накапливаем вектор отталкивания, он применится в _physics_process
	_knockback_vector += direction.normalized() * strength

func _show_damage_effect() -> void:
	if not animated_sprite:
		return
	var tween = create_tween()
	# Делаем спрайт ярко-белым (эффект вспышки), затем возвращаем в норму
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(animated_sprite, "modulate", Color(2, 2, 2, 1), 0.1)
	tween.tween_property(animated_sprite, "modulate", Color.WHITE, 0.1)
