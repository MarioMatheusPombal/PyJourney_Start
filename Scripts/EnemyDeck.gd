extends Node2D

const CARD_SCENE_PATH = "res://Scenes/EnemyCard.tscn"
const CARD_DRAW_SPEED = 0.2
const STARTING_HAND_SIZE = 5

var enemy_deck = ["Soldier", "Archer", "Demon", "Soldier", "Soldier", "Soldier", "Soldier", "Soldier"]
var card_database_reference

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	enemy_deck.shuffle()
	$RichTextLabel.text = str(enemy_deck.size())
	card_database_reference = preload("res://Scripts/CardDatabase.gd")
	for i in range(STARTING_HAND_SIZE):
		draw_card()


func draw_card():
	var card_drawn_name = enemy_deck[0]
	enemy_deck.erase(card_drawn_name)
	
	#If player drew the last card in the deck, disable the deck
	if enemy_deck.size() == 0:
		$Sprite2D.visible = false
		$RichTextLabel.visible = false 
	
	$RichTextLabel.text = str(enemy_deck.size())
	var card_scene = preload(CARD_SCENE_PATH)
	var new_card = card_scene.instantiate()
	var card_image_path = str("res://Sprites/" +card_drawn_name+ ".png")
	new_card.get_node("CardImage").texture = load(card_image_path)
	new_card.attack = card_database_reference.CARDS[card_drawn_name][0]
	new_card.get_node("Attack").text = str(new_card.attack)
	new_card.health = card_database_reference.CARDS[card_drawn_name][1]
	new_card.get_node("Health").text = str(new_card.health)
	new_card.card_type = card_database_reference.CARDS[card_drawn_name][2]
	$"../CardManager".add_child(new_card)
	new_card.name = "Card"
	$"../EnemyHand".add_card_to_hand(new_card, CARD_DRAW_SPEED)
