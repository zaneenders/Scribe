import Foundation

public enum MessageType: Codable, Sendable {
    case frame(Frame)
    case disconnect
    case upload(data: String)
}

public struct ServerMessage: Codable, Sendable {
    public let type: MessageType

    public init(frame: Frame) {
        self.type = .frame(frame)
    }

    public init(upload: String) {
        self.type = .upload(data: upload)
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
