public struct ClientAction: Action {
    let key: AsciiKeyCode
}

public actor ClientProgram: Program {
    var status: Status = .working
    var state: State = .select

    enum State {
        case select
        case connected(MessageClient, Int)
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
        case (.ctrlC, .connected(let client, let i)):
            await client.close()
            self.page = Page([
                ["ClientProgram"], ["Disconnected \(i) \(client.address)"],
            ])
            self.state = .select
        case (.ctrlJ, .select):
            do {
                let client = try await MessageClient(host: "::1", port: 42169)
                let msg = ClientMessage(
                    connect: "Client", maxX: maxX, maxY: maxY)
                let r = try await client.send(msg: msg.json)
                let i = 1
                self.state = .connected(client, i)
                self.page = Page([
                    ["ClientProgram"],
                    ["Connected \(i) \(client.address) \(r.count)"],
                ])
            } catch {
                self.state = .select
                self.page = Page([["ClientProgram"], ["Failed To Connect"]])
            }
        case (let k, .select):
            self.page = Page([["ClientProgram"], ["Disconnected \(k)"]])
            self.state = .select
        case (let k, .connected(let client, var i)):
            do {
                let msg = ClientMessage(
                    ascii: k.rawValue, maxX: maxX, maxY: maxY)
                let r = try await client.send(msg: msg.json)
                i += 1
                self.page = Page([
                    ["ClientProgram"],
                    ["Received \(i) \(client.address) \(r.count)"],
                ])
                self.state = .connected(client, i)
            } catch {
                self.state = .select
                self.page = Page([
                    ["ClientProgram"], ["Connection Error: \(client.address)"],
                ])
            }
        }
        return page.renderWindow(maxX, maxY)
    }

    public func shutDown(
        _ maxX: Int, _ maxY: Int
    ) async -> Frame {
        page.renderWindow(maxX, maxY)
    }

    public static func processKey(_ key: InputType) -> ClientAction {
        ClientAction(key: key)
    }

    public typealias ActionType = ClientAction

    var page: Page

    public init() async {
        self.page = Page([["ClientProgram"], ["Not Connected"]])
    }
}
