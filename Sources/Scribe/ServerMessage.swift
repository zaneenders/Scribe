import Foundation

public enum MessageType: Codable, Sendable {
    case message(String)
    case disconnect
}

public struct ServerMessage: Codable, Sendable {
    public let type: MessageType

    public init(msg: String) {
        self.type = .message(msg)
    }

    public init() {
        self.type = .disconnect
    }

    public init(json: String) {
        let data = json.data(
            using: .utf8)!
        let decoder = JSONDecoder()
        let msg: ServerMessage = try! decoder.decode(
            ServerMessage.self, from: data)
        self = msg
    }

    public var json: String {
        let encoder = JSONEncoder()
        let data = try! encoder.encode(self)
        let jsonString = String(data: data, encoding: .utf8)!
        return jsonString
    }
}
