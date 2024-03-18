import Scribe

public struct ClientAction: Action {
    let key: AsciiKeyCode
}

public actor ClientProgram: Program {
    public typealias ActionType = ClientAction

    var page: Page
    var status: Status = .working
    private var state: State = .select

    public init() async {
        self.page = Page([["ClientProgram"], ["Not Connected"]])
    }

    private enum State {
        case select
        case connected(Box, Int)
    }

    private final class Box {
        init(host: String = "::1", port: Int = 42169) async throws {
            self.client = try await MessageClient(host: host, port: port)
        }
        let client: MessageClient
    }

    public func getStatus() async -> Status {
        self.status
    }

    public func getFrame(
        with action: ClientAction, _ maxX: Int, _ maxY: Int
    ) async -> Frame {
        switch (action.key, self.state) {
        case (.ctrlC, .select):
            self.status = .close
        case (.ctrlC, .connected(let box, let i)):
            await box.client.close()
            self.page = Page([
                ["ClientProgram"], ["Disconnected \(i) \(box.client.address)"],
            ])
            self.state = .select
        case (.ctrlJ, .select):
            do {
                let box = try await Box()
                let msg = ClientMessage(
                    connect: "Client", maxX: maxX, maxY: maxY)
                let r = try await box.client.send(msg: msg.json)
                let i = 1
                self.state = .connected(box, i)
                self.page = Page([
                    ["ClientProgram"],
                    ["Connected \(i) \(box.client.address) \(r.count)"],
                ])
            } catch {
                self.state = .select
                self.page = Page([["ClientProgram"], ["Failed To Connect"]])
            }
        case (let k, .select):
            self.page = Page([["ClientProgram"], ["Disconnected \(k)"]])
            self.state = .select
        case (let k, .connected(let box, var i)):
            do {
                let msg = ClientMessage(
                    ascii: k.rawValue, maxX: maxX, maxY: maxY)
                let r = try await box.client.send(msg: msg.json)
                i += 1
                self.page = Page([
                    ["ClientProgram"],
                    ["Received \(i) \(box.client.address) \(r.count)"],
                ])
                self.state = .connected(box, i)
            } catch {
                self.state = .select
                self.page = Page([
                    ["ClientProgram"],
                    ["Connection Error: \(box.client.address)"],
                ])
            }
        }
        return page.renderWindow(maxX, maxY)
    }

    public static func processKey(_ key: InputType) -> ClientAction {
        ClientAction(key: key)
    }
}
