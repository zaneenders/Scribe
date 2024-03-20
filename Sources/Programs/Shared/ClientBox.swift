import Scribe

internal final class ClientBox {

    let client: MessageClient

    init(
        host: String = "::1", port: Int = 42169,
        _ handle: @escaping (String) -> Void
    ) async throws {
        self.client = try await MessageClient(
            host: host, port: port, handle)
    }
}
