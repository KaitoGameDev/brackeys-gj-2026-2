class_name MoneyDestroyedEvent

var money: Money
var money_resource: MoneyResource


static func create(money: Money, money_resource: MoneyResource) -> MoneyDestroyedEvent:
	var event := MoneyDestroyedEvent.new()
	event.money = money
	event.money_resource = money_resource
	return event
