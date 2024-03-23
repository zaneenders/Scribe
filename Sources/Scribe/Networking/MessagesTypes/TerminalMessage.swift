import Foundation

public enum TerminalCommand: Codable, Sendable {
    case ascii(UInt8, maxX: Int, maxY: Int)
    case connect(String, maxX: Int, maxY: Int)
}

public struct TerminalMessage: Codable {
    public let command: TerminalCommand

    /// maxX and maxY assume 1,1 base indexing
    public init(ascii: UInt8, maxX: Int, maxY: Int) {
        self.command = .ascii(ascii, maxX: maxX, maxY: maxY)
    }

    public init(connect: String, maxX: Int, maxY: Int) {
        self.command = .connect(connect, maxX: maxX, maxY: maxY)
    }

    public init?(json: String) {
        guard
            let data = json.data(
                using: .utf8)
        else {
            return nil
        }
        let decoder = JSONDecoder()
        guard
            let msg: TerminalMessage = try? decoder.decode(
                TerminalMessage.self, from: data)
        else {
            return nil
        }
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
