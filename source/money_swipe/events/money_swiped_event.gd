class_name MoneySwipedEvent

enum Direction {
	UP,
	DOWN,
}

var money: Money
var money_resource: MoneyResource
var direction: Direction


static func create(money: Money, money_resource: MoneyResource, direction: Direction) -> MoneySwipedEvent:
	var event := MoneySwipedEvent.new()
	event.money = money
	event.money_resource = money_resource
	event.direction = direction
	return event
