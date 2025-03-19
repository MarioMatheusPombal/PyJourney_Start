extends Node

const SMALL_CARD_SCALE = 0.6
const CARD_MOVE_SPEED = 0.2

var battle_timer
var empty_monster_card_slots = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	battle_timer = $"../BattleTimer"
	battle_timer.one_shot = true
	battle_timer.wait_time = 1.0
	
	empty_monster_card_slots.append($"../CardSlots/CardSlot11")
	empty_monster_card_slots.append($"../CardSlots/CardSlot12")
	empty_monster_card_slots.append($"../CardSlots/CardSlot13")
	empty_monster_card_slots.append($"../CardSlots/CardSlot14")
	empty_monster_card_slots.append($"../CardSlots/CardSlot15")
	

func _on_finalizar_turno_botao_pressed() -> void:
	opponent_turn()

func opponent_turn():
	$"../FinalizarTurnoBotao".disabled = true
	$"../FinalizarTurnoBotao".visible = false
	
	#Wait 1 second
	battle_timer.start()
	await battle_timer.timeout
	
	#If can draw a card, draw then wait 1 second
	if $"../EnemyDeck".enemy_deck.size() != 0:
		$"../EnemyDeck".draw_card()
			#Wait 1 second
		battle_timer.start()
		await battle_timer.timeout
	
	#Check if any free monster card slots, and if no, end turn
	if empty_monster_card_slots.size() == 0:
		end_opponent_turn()
		return
	
	#Try play card and wait 1 sec if played
	await try_play_card_with_highest_attack()
	
	#End turn
	end_opponent_turn()


func try_play_card_with_highest_attack():
	#Play the card in hard with highest attack
	#Get random empty slot to play the card in
	var enemy_hand = $"../EnemyHand".enemy_hand
	if enemy_hand.size() == 0:
		end_opponent_turn()
		return
	
	var random_empty_monster_card_slot = empty_monster_card_slots[randi_range(0, empty_monster_card_slots.size()-1)]
	empty_monster_card_slots.erase(random_empty_monster_card_slot)
	var card_with_highest_atk = enemy_hand[0]
	for card in enemy_hand:
		if card.attack > card_with_highest_atk.attack:
			card_with_highest_atk = card
			
	#Animate card to position
	var tween = get_tree().create_tween()
	tween.tween_property(card_with_highest_atk, "position", random_empty_monster_card_slot.position, CARD_MOVE_SPEED)
	var tween2 = get_tree().create_tween()
	tween2.tween_property(card_with_highest_atk, "scale", Vector2(SMALL_CARD_SCALE, SMALL_CARD_SCALE), CARD_MOVE_SPEED)
	card_with_highest_atk.get_node("AnimationPlayer").play("card_flip")
	
	#REMOVE THE CARD FROM ENEMY HAND
	$"../EnemyHand".remove_card_from_hand(card_with_highest_atk)
	
	#Wait 1 second
	battle_timer.start()
	await battle_timer.timeout

func end_opponent_turn():
	#Reset player deck draw
	$"../Deck".reset_draw()
	$"../CardManager".reset_played_monster()
	$"../FinalizarTurnoBotao".disabled = false
	$"../FinalizarTurnoBotao".visible = true
