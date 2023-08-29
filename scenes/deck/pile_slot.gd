class_name PileSlot extends TextureRect

signal card_dropped(player: Player, card: PlayingCard, pile: PileSlot)
signal pile_collected(player: Player, pile: PileSlot)

@onready var current_suit: String
@onready var current_points: float = 0.0
@onready var cards_in_pile: Array[PlayingCard] = []

const GROUP_NAME = "piles"

func _ready():
	modulate.a = 1.0
	self_modulate.a = 0.2
	
	if not is_in_group(GROUP_NAME):
		add_to_group(GROUP_NAME)
		
	card_dropped.connect(on_card_dropped)
	
	
func _can_drop_data(_at_position, data):
	return data.playing_card is PlayingCard and card_can_be_dropped_in_this_pile(data.playing_card)
	

func _drop_data(at_position, data):
	var dropped_card = data.playing_card as PlayingCard
	
	if current_suit.is_empty() and not dropped_card.is_poison:
		current_suit = dropped_card.suit
		self_modulate.a = 0.0
	
	add_points_to_pile(dropped_card.current_value)
	add_card_to_pile(dropped_card)

	data.player.cards_in_hand.erase(dropped_card)
	card_dropped.emit(data.player, dropped_card, self)
	

func card_can_be_dropped_in_this_pile(card: PlayingCard) -> bool:	
	return card.is_poison and not current_suit.is_empty() or \
		(not card.is_poison and current_suit.is_empty() and suit_is_not_active(card.suit)) \
		or card.suit == current_suit


func suit_is_not_active(suit: String) -> bool:
	var suits = get_tree().get_nodes_in_group(GROUP_NAME).map(func(pile: PileSlot): return pile.current_suit)
	
	return suit not in suits


func add_card_to_pile(card: PlayingCard) -> void:
	var card_pile_texture = TextureRect.new()
	card_pile_texture.name = card.suit.capitalize() + card.symbol_value.capitalize()
	card_pile_texture.texture = card.symbol_texture.texture
	card_pile_texture.expand_mode = TextureRect.EXPAND_KEEP_SIZE
	card_pile_texture.size = card.symbol_texture.get_rect().size
	card_pile_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if card.is_poison:
		card_pile_texture.position.y += 21
		
	add_child(card_pile_texture)

	cards_in_pile.append(card)


func add_points_to_pile(value: float) -> void:
	current_points += value
	
	
	
func on_card_dropped(player, _card, _pile):
	if current_points >= 13:
		pile_collected.emit(player, duplicate())
		cards_in_pile.clear()
		current_suit = ""
		current_points = 0.0
		self_modulate.a = 0.2
		
		for child in get_children():
			child.queue_free()
		
