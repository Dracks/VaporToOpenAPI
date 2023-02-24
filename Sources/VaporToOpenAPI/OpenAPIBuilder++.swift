import Swiftgger
import Vapor

extension OpenAPIBuilder {
	
	public func addController(name: String, description: String, externalDocs: APILink? = nil, routes: [Route]) -> OpenAPIBuilder {
		add(
			APIController(
				name: name,
				description: description,
				externalDocs: externalDocs,
				actions: routes.map { $0.apiAction }
			)
		)
	}
}
