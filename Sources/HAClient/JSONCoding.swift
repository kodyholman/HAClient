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
            NSLog("Cannot deserialize message. JSON: %@", jsonString)
            return nil
        }

        switch messageWithType.type {
        case .auth_required:
            return try? JSON.decoder.decode(AuthRequired.self, from: jsonData)
        case .auth_ok:
            return try? JSON.decoder.decode(AuthOkMessage.self, from: jsonData)
        case .auth_invalid:
            return try? JSON.decoder.decode(AuthInvalidMessage.self, from: jsonData)
        case .pong:
            return try? JSON.decoder.decode(PongMessage.self, from: jsonData)
        case .result:
            return try? JSON.decoder.decode(BaseResultMessage.self, from: jsonData)
        }
    }
    
    static func deserializeCommandResponse(type: CommandType, jsonData: Data) -> Any? {
        switch type {
        case .ping:
            if let message = try? JSON.decoder.decode(PongMessage.self, from: jsonData) {
                return message
            }
        case .listAreas:
            if let message = try? JSON.decoder.decode(ResultMessage<Area>.self, from: jsonData) {
                return message
            }
        case .listDevices:
            if let message = try? JSON.decoder.decode(ResultMessage<Device>.self, from: jsonData) {
                return message
            }
        case .listEntities:
            if let message = try? JSON.decoder.decode(ResultMessage<Entity>.self, from: jsonData) {
                return message
            }
        case .retrieveStates:
            if let message = try? JSON.decoder.decode(ResultMessage<State>.self, from: jsonData) {
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

public enum JSONProperty: Codable {
    case double(Double)
    case string(String)
    case bool(Bool)
    case null
    case array([JSONProperty])
    case record([String:JSONProperty])
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if container.decodeNil() {
            self = .null
            return
        } else if let doubleVal = try? container.decode(Double.self) {
            self = .double(doubleVal)
            return
        } else if let stringVal = try? container.decode(String?.self) {
            self = .string(stringVal)
            return
        } else if let boolVal = try? container.decode(Bool.self) {
            self = .bool(boolVal)
            return
        } else if let arrayVal = try? container.decode([JSONProperty].self) {
            self = .array(arrayVal)
            return
        } else if let recordVal = try? container.decode([String:JSONProperty].self) {
            self = .record(recordVal)
            return
        }
        
        fatalError("Failed to decode JSON property")
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .null:
            try container.encodeNil()
        case .double(let value):
            try container.encode(value)
        case .string(let value):
            try container.encode(value)
        case .bool(let value):
            try container.encode(value)
        case .array(let value):
            try container.encode(value)
        case .record(let value):
            try container.encode(value)
        }
    }
}
