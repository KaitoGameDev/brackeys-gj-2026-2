class_name RotateMoneyEvent

var money: Money
var money_resource: MoneyResource
var showing_back: bool


static func create(money: Money, money_resource: MoneyResource, showing_back: bool) -> RotateMoneyEvent:
	var event := RotateMoneyEvent.new()
	event.money = money
	event.money_resource = money_resource
	event.showing_back = showing_back
	return event
