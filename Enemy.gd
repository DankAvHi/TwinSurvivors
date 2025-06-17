extends CharacterBody2D

@export var speed: float = 100.0
@export var player_node_path: NodePath
@export var attack_damage: float = 10.0
@export var attack_cooldown: float = 1.0 # Секунд между атаками

var player: CharacterBody2D
var animated_sprite: AnimatedSprite2D
var damage_zone: Area2D
var attack_cooldown_timer: Timer
var can_attack: bool = true
var _player_is_in_damage_zone: bool = false # Флаг нахождения игрока в зоне

func _ready() -> void:
	animated_sprite = $Animation as AnimatedSprite2D # Убедись, что узел называется AnimatedSprite2D
	if animated_sprite:
		animated_sprite.play("default") # Предполагается, что "default" - анимация ожидания/появления
	else:
		printerr("Враг '", name, "': узел AnimatedSprite2D не найден или имеет неверный тип.")

	# Находим узлы для атаки
	damage_zone = $DamageZone as Area2D
	attack_cooldown_timer = $AttackCooldownTimer as Timer

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

	move_and_slide()

func _on_DamageZone_body_entered(body: Node2D) -> void:
	if body == player:
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
