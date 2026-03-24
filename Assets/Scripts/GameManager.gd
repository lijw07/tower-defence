extends Node

signal gold_changed(new_amount: int)

const STARTING_GOLD: int = 200

var gold: int = STARTING_GOLD

func add_gold(amount: int) -> void:
	gold += amount
	emit_signal("gold_changed", gold)

func spend_gold(amount: int) -> bool:
	if gold < amount:
		return false
	gold -= amount
	emit_signal("gold_changed", gold)
	return true

func reset() -> void:
	gold = STARTING_GOLD
	emit_signal("gold_changed", gold)
