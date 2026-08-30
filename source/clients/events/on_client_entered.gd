class_name OnClientEntered

var client_resource: ClientResource

static func create(resource: ClientResource) -> OnClientEntered:
	var event := OnClientEntered.new()
	event.client_resource = resource
	return event