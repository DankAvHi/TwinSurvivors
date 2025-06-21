extends CharacterBody2D

@export var hqd_weapon_scene: PackedScene # Сюда перетащим сцену HQD.tscn
const SPEED: float = 300.0
@export var max_health: float = 100.0

var animated_sprite: AnimatedSprite2D
var health_bar: ProgressBar # Добавляем ссылку на ProgressBar
var _current_health: float # Приватная переменная для хранения здоровья

var current_health: float: # Публичное свойство с сеттером
	get: return _current_health
	set(value):
		_current_health = clampf(value, 0.0, max_health)
		if health_bar:
			health_bar.value = _current_health
		emit_signal("health_changed", _current_health, max_health)
		if _current_health <= 0.0 and not is_queued_for_deletion(): # Проверяем, не удаляется ли уже
			_die()

# Сигналы для UI или других систем
signal health_changed(new_health, max_health_value)
signal died

func _ready() -> void:
	animated_sprite = $AnimatedSprite2D as AnimatedSprite2D # Используем $ для краткости
	health_bar = $HealthBar as ProgressBar # Предполагаем, что ProgressBar будет называться "HealthBar"
	if health_bar:
		health_bar.max_value = max_health
	self.current_health = max_health # Устанавливаем начальное здоровье через сеттер

	# Создаем и добавляем оружие HQD
	if hqd_weapon_scene:
		var hqd_instance = hqd_weapon_scene.instantiate()
		add_child(hqd_instance) # HQD будет двигаться вместе с игроком

func take_damage(amount: float) -> void:
	self.current_health -= amount # Уменьшаем здоровье через сеттер
	print("Игрок получил ", amount, " урона. Осталось здоровья: ", _current_health)

func _die() -> void:
	print("Игрок умер!")
	emit_signal("died")
	queue_free() # Пока просто удаляем игрока. Позже можно добавить экран "Game Over"

func _physics_process(delta: float) -> void:
	var current_velocity: Vector2 = velocity # Используем локальную переменную для ясности

	var direction: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if direction != Vector2.ZERO:
		current_velocity = direction * SPEED
		animated_sprite.play("default") # Убедись, что анимация "default" подходит для движения
	else:
		current_velocity = Vector2.ZERO
		# Вместо stop(), возможно, лучше переключаться на анимацию "idle"
		# animated_sprite.play("idle") 
		animated_sprite.stop() # Оставим пока stop() для соответствия оригиналу

	velocity = current_velocity
	move_and_slide()