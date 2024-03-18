import Foundation

public enum ClientCommand: Codable, Sendable {
    case byte(UInt8, maxX: Int, maxY: Int)
    case connect(String, maxX: Int, maxY: Int)
}

public struct ClientMessage: Codable {
    public let command: ClientCommand

    /// maxX and maxY assume 1,1 base indexing
    public init(byte: UInt8, maxX: Int, maxY: Int) {
        self.command = .byte(byte, maxX: maxX, maxY: maxY)
    }

    public init(connect: String, maxX: Int, maxY: Int) {
        self.command = .connect(connect, maxX: maxX, maxY: maxY)
    }

    public init(json: String) {
        let data = json.data(
            using: .utf8)!
        let decoder = JSONDecoder()
        let msg: ClientMessage = try! decoder.decode(
            ClientMessage.self, from: data)
        self = msg
    }

    public var json: String {
        let encoder = JSONEncoder()
        // encoder.outputFormatting = .prettyPrinted
        let data = try! encoder.encode(self)
        let jsonString = String(data: data, encoding: .utf8)!
        return jsonString
    }
}
