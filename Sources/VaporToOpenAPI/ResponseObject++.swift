import Foundation
import SwiftOpenAPI
import Vapor

func response(
	_ body: Any,
	description: String,
	contentTypes: [MediaType],
	headers: [Any],
	schemas: inout [String: ReferenceOr<SchemaObject>],
	examples: inout [String: ReferenceOr<ExampleObject>]
) throws -> ResponseObject {
	let object = try OpenAPIValue(body).mediaTypeObject(schemas: &schemas, examples: &examples)
	return try ResponseObject(
		description: description,
		headers: Dictionary(
			headers.flatMap {
                try OpenAPIValue($0).headers(schemas: &schemas)
			}
		) { _, s in s }.nilIfEmpty,
		content: ContentObject(
			dictionaryElements: contentTypes.map { ($0, object) }
		)
	)
}

func responses(
	default defaultResponse: Any?,
    successCode: ResponsesObject.Key,
	types: [MediaType],
	headers: [Any],
	errors errorResponses: [Int: Any],
	descriptions: [Int: String],
	errorTypes: [MediaType],
	errorHeaders: [Any],
	schemas: inout [String: ReferenceOr<SchemaObject>],
	examples: inout [String: ReferenceOr<ExampleObject>]
) -> ResponsesObject? {
	var responses: [ResponsesObject.Key: ResponsesObject.Value] = Dictionary(
		errorResponses.compactMap {
			try? (
				ResponsesObject.Key.code($0.key),
				.value(
					response(
						$0.value,
						description: descriptions[$0.key] ?? Abort(HTTPResponseStatus(statusCode: $0.key)).reason,
						contentTypes: errorTypes,
						headers: errorHeaders,
						schemas: &schemas,
						examples: &examples
					)
				)
			)
		} + descriptions.filter { errorResponses[$0.key] == nil }.compactMap {
			(
				ResponsesObject.Key.code($0.key),
				.value(
					ResponseObject(description: $0.value)
				)
			)
		}
	) { _, new in new }
	if let defaultResponse {
		responses[successCode] = try? .value(
			response(
				defaultResponse,
				description: descriptions[200] ?? "Success",
				contentTypes: types,
				headers: headers,
				schemas: &schemas,
				examples: &examples
			)
		)
	}
	guard !responses.isEmpty else { return nil }
	return ResponsesObject(responses)
}
