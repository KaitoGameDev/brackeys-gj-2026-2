class_name MoneySpawnedEvent

var money: Money
var money_resource: MoneyResource


static func create(money: Money, money_resource: MoneyResource) -> MoneySpawnedEvent:
	var event := MoneySpawnedEvent.new()
	event.money = money
	event.money_resource = money_resource
	return event
