# Replace the Button with this setup in your UI scene
extends Button

@onready var gacha_overlay: ColorRect = $GachaOverlay  # Add ColorRect as child, full-screen
@onready var gacha_sprite: TextureRect = $GachaOverlay/TowerSprite  # Child of overlay
@onready var gacha_button: Button = self  # Keep invisible or separate

var pending_pull: bool = false
var revealed_id: String = ""

func _ready() -> void:
	gacha_overlay.visible = false
	gacha_overlay.color = Color(0, 0, 0, 0.7)
	gacha_overlay.size = get_viewport_rect().size
	gacha_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	gacha_sprite.expand_mode = TextureRect.EXPAND_KEEP_SIZE
	gacha_sprite.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	gacha_sprite.position = gacha_overlay.size / 2
	gacha_sprite.size = Vector2(64, 64)  # Adjust size as needed
	
	gacha_button.pressed.connect(_on_gacha_pressed)
	text = "Pull (€%d)" % Gacha.pull_cost
	Gacha.item_pulled.connect(_on_item_pulled)

func _on_gacha_pressed() -> void:
	if Gacha.pull():
		pending_pull = true
	else:
		Utilities.spawn_floating_text("Not enough money!", gacha_button.global_position)

func _on_item_pulled(id: String, is_new: bool) -> void:
	revealed_id = id
	gacha_sprite.texture = InventoryManager.items[id].texture
	gacha_overlay.visible = true
	gacha_button.disabled = true  # Prevent spam
	# Update cost text if separate label
	text = "Pull (€%d)" % Gacha.pull_cost

func _input(event: InputEvent) -> void:
	if pending_pull and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		# Add to inventory
		var new_item = {"id": revealed_id, "rank": Gacha.unlocked_levels[revealed_id]}
		for slot in InventoryManager.slots:
			if slot.get_meta("item", {}).is_empty():
				slot.set_meta("item", new_item)
				InventoryManager._update_slot(slot)
				break
		
		var msg = "Unlocked %s!" % revealed_id if Gacha.unlocked_levels[revealed_id] == 1 else "Leveled %s!" % revealed_id
		Utilities.spawn_floating_text(msg, get_global_mouse_position(), null, true)
		
		gacha_overlay.visible = false
		pending_pull = false
		gacha_button.disabled = false
