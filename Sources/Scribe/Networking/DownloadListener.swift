@globalActor
actor DownloadManager {
    static let shared: DownloadManager = DownloadManager()

    init() {}
}

actor DownloadConnection {

    var writer: ((String) async throws -> Void)!
    private let address: String
    init(_ address: String) {
        self.address = address
        print("DownloadConnection[\(address)] init")
    }
    deinit {
        print("DownloadConnection[\(address)] deinit")
    }

    func setWriter(_ writer: @Sendable @escaping (String) async throws -> Void)
    {
        self.writer = writer
    }

    func read(_ json: String) async throws {
        print("DownloadConnection[\(address)]: \(json)")
    }
}
