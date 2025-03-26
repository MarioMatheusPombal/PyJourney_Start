extends Node

const SMALL_CARD_SCALE = 0.6
const CARD_MOVE_SPEED = 0.2
const STARTING_HEALTH = 20
const BATTLE_POS_OFFSET = 25

var battle_timer
var empty_monster_card_slots = []
var opponent_cards_on_battlefield = []
var player_cards_on_battlefield = []
var player_health
var enemy_health

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
	
	player_health = STARTING_HEALTH
	$"../PlayerHealth".text = str(player_health)
	enemy_health = STARTING_HEALTH
	$"../EnemyHealth".text = str(enemy_health)

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
	
	#Check if any free slot, and play monster with highest attack if so
	if empty_monster_card_slots.size() != 0:
		await try_play_card_with_highest_attack()
	
	#Try Attack
	if opponent_cards_on_battlefield.size() != 0:
		var enemy_cards_to_attack = opponent_cards_on_battlefield.duplicate()
		for card in enemy_cards_to_attack:
			if player_cards_on_battlefield.size() == 0:
				await direct_attack(card, "Enemy")
			else:
				var card_to_attack = player_cards_on_battlefield.pick_random()
				await attack(card, card_to_attack, "Enemy")
	
	
	#End turn
	end_opponent_turn()

func attack(attacking_card, defending_card, attacker):
	attacking_card.z_index = 5
	var new_pos = Vector2(defending_card.position.x, defending_card.position.y + BATTLE_POS_OFFSET)
	var tween = get_tree().create_tween()
	tween.tween_property(attacking_card,"position",new_pos, CARD_MOVE_SPEED)
	await waitasecond(0.15)
	var tween2 = get_tree().create_tween()
	tween2.tween_property(attacking_card,"position",attacking_card.card_slot_card_is_in.position, CARD_MOVE_SPEED)
	
	#Card damage
	defending_card.health = max(0, defending_card.health - attacking_card.attack)
	defending_card.get_node("Health").text = str(defending_card.health)
	attacking_card.health = max(0, attacking_card.health - defending_card.attack)
	attacking_card.get_node("Health").text = str(attacking_card.health)
	
	await  waitasecond(1.0)
	attacking_card.z_index = 0
	
	var card_was_destroyed = false
	#Destroy cards
	if attacking_card.health == 0:
		destroy_card(attacking_card, attacker)
		card_was_destroyed = true
	if defending_card.health == 0:
		if attacker == "Player":
			destroy_card(defending_card, "Enemy")
		else:
			destroy_card(defending_card, "Player")
		card_was_destroyed = true
	
	if card_was_destroyed:
		await waitasecond(1.0)
	
func destroy_card(card, card_owner):
	var new_pos
	if card_owner == "Player":
		new_pos = $"../PlayerDiscard".position
	else:
		new_pos = $"../EnemyDiscard".position
	
	var tween = get_tree().create_tween()
	tween.tween_property(card,"position",new_pos, CARD_MOVE_SPEED)

func direct_attack(attacking_card, attacker):
	var new_pos_y
	if attacker == "Enemy":
		new_pos_y = 1080
	else:
		new_pos_y = 0
	var new_pos = Vector2(attacking_card.position.x, new_pos_y)
	attacking_card.z_index = 5
	
	#Animate card to position
	var tween = get_tree().create_tween()
	tween.tween_property(attacking_card, "position", new_pos, CARD_MOVE_SPEED)
	await waitasecond(0.15)
	
	if attacker == "Enemy":
		player_health -= max(0,attacking_card.attack)
		$"../PlayerHealth".text = str(player_health)
	else:
		enemy_health -= max(0, attacking_card.attack)
		$"../EnemyHealth".text = str(enemy_health)
	#Animate card to position
	var tween2 = get_tree().create_tween()
	tween2.tween_property(attacking_card, "position", attacking_card.card_slot_card_is_in.position, CARD_MOVE_SPEED)
	attacking_card.z_index = 0
	await waitasecond(1.0)

func try_play_card_with_highest_attack():
	#Play the card in hard with highest attack
	#Get random empty slot to play the card in
	var enemy_hand = $"../EnemyHand".enemy_hand
	if enemy_hand.size() == 0:
		end_opponent_turn()
		return
	
	var random_empty_monster_card_slot = empty_monster_card_slots.pick_random()
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
	card_with_highest_atk.card_slot_card_is_in = random_empty_monster_card_slot
	opponent_cards_on_battlefield.append(card_with_highest_atk)
	await waitasecond(1.0)

func waitasecond(wait_time):
	#Wait 1 second
	battle_timer.wait_time = wait_time
	battle_timer.start()
	await battle_timer.timeout

func end_opponent_turn():
	#Reset player deck draw
	$"../Deck".reset_draw()
	$"../CardManager".reset_played_monster()
	$"../FinalizarTurnoBotao".disabled = false
	$"../FinalizarTurnoBotao".visible = true
