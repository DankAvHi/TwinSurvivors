extends Area2D

@export var damage_amount: float = 5.0      # Урон за один тик
@export var knockback_strength: float = 50.0 # Сила отталкивания
@export var damage_interval: float = 0.5   # Интервал нанесения урона в секундах

var _damage_timer: Timer
var _enemies_in_area: Array[Node2D] = [] # Храним врагов в зоне

func _ready() -> void:
	_damage_timer = $DamageTimer as Timer
	if not _damage_timer:
		printerr("HQD: Узел DamageTimer не найден!")
		return

	_damage_timer.wait_time = damage_interval
	_damage_timer.timeout.connect(_on_DamageTimer_timeout)
	# _damage_timer.start() # Уже стоит Autostart, но можно и так

	# Подключаем сигналы для отслеживания тел в зоне
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_DamageTimer_timeout() -> void:
	# Копируем массив, так как враг может быть удален во время итерации
	var current_enemies = _enemies_in_area.duplicate()
	for body in current_enemies:
		if not is_instance_valid(body): # Если враг уже удален, пропускаем
			_enemies_in_area.erase(body) # Убираем из основного списка, если еще там
			continue

		if body.has_method("take_damage"):
			body.take_damage(damage_amount)
			# print("HQD нанес урон ", body.name)

		if body.has_method("apply_knockback"):
			var direction_to_enemy = (body.global_position - global_position).normalized()
			if direction_to_enemy == Vector2.ZERO: # Если враг точно в центре
				direction_to_enemy = Vector2.RIGHT.rotated(randf_range(0, TAU)) # Случайное направление
			body.apply_knockback(direction_to_enemy, knockback_strength)
			# print("HQD оттолкнул ", body.name)

func _on_body_entered(body: Node2D) -> void:
	# Проверяем, что это враг (например, по группе "enemies")
	if body.is_in_group("enemies") and not _enemies_in_area.has(body):
		_enemies_in_area.append(body)
		# print("Враг ", body.name, " вошел в зону HQD")

func _on_body_exited(body: Node2D) -> void:
	if _enemies_in_area.has(body):
		_enemies_in_area.erase(body)
		# print("Враг ", body.name, " покинул зону HQD")
