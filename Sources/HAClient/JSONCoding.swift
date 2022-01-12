import Foundation

final class JSONCoding {
    static func serialize(_ message: Encodable) -> String {
        let data = try! JSONSerialization.data(
            withJSONObject: message.asDictionary,
            options: .sortedKeys
        )
        return String(decoding: data, as: UTF8.self)
    }

    static func deserialize(_ jsonString: String) -> Any? {
        let jsonData = jsonString.data(using: .utf8)!
        guard let messageWithType = try? JSON.decoder.decode(BaseMessage.self, from: jsonData) else {
            print("Attempting to deserialize a message without type", jsonString)
            return nil
        }

        switch messageWithType.type {
        case .auth_required:
            return try? JSON.decoder.decode(AuthRequired.self, from: jsonData)
        case .auth_ok:
            return try? JSON.decoder.decode(AuthOkMessage.self, from: jsonData)
        case .auth_invalid:
            return try? JSON.decoder.decode(AuthInvalidMessage.self, from: jsonData)
        case .result:
            return try? JSON.decoder.decode(BaseResultMessage.self, from: jsonData)
        }
    }
    
    static func deserializeCommandResponse(type: CommandType, jsonData: Data) -> Any? {
        switch type {
        case .listAreas:
            if let message = try? JSON.decoder.decode(ListAreasResultMessage.self, from: jsonData) {
                return message
            }
        case .listDevices:
            if let message = try? JSON.decoder.decode(ListDevicesResultMessage.self, from: jsonData) {
                return message
            }
        case .listEntities:
            if let message = try? JSON.decoder.decode(ListEntitiesResultMessage.self, from: jsonData) {
                return message
            }
        case .retrieveStates:
            if let message = try? JSON.decoder.decode(CurrentStatesResultMessage.self, from: jsonData) {
                return message
            }
        }
        return nil
    }
}

extension Encodable {
    subscript(key: String) -> Any? {
        return asDictionary[key]
    }

    var asDictionary: [String: Any] {
        return (try? JSONSerialization.jsonObject(with: JSON.encoder.encode(self))) as? [String: Any] ?? [:]
    }
}

struct JSON {
    static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        return encoder
    }()

    static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        return decoder
    }()
}
