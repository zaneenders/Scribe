import Foundation

public enum FileMessageType: Codable, Sendable {
    case request(String)
    case file(data: String)
}

public struct FilesMessage: Codable, Sendable {
    public let type: FileMessageType

    public init(request: String) {
        self.type = .request(request)
    }

    public init(file: String) {
        self.type = .file(data: file)
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
            let msg: FilesMessage = try? decoder.decode(
                FilesMessage.self, from: data)
        else {
            return nil
        }
        self = msg
    }

    public var json: String {
        let encoder = JSONEncoder()
        let data = try! encoder.encode(self)
        let jsonString = String(data: data, encoding: .utf8)!
        return jsonString
    }
}
