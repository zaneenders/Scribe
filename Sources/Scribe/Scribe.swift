private enum IntenralState {
    case ready
    case running(any Program)
}

enum State {
    case running
    case shutdown
}

enum ScribeCommand {
    case hello
    case key(AsciiKeyCode)
}

actor Scribe {

    private let address: String
    private var programs: [any Program.Type]
    private var selected = 0

    private(set) var state: State
    private var _state: IntenralState

    private var page: Page
    private var x: Int = 80
    private var y: Int = 24

    func frame() async -> Frame {
        switch self._state {
        case .ready:
            page.renderWindow(x, y)
        case .running(let p):
            await p.getFrame()
        }
    }

    init(_ address: String, _ programs: [any Program.Type]) {
        self.address = address
        self.programs = programs

        self.state = .running
        self._state = .ready

        var data: [[String]] = [["Scribe", "[\(address)]"]]
        for prog in programs {
            data.append(["\(prog)"])
        }
        self.page = Page(data)
    }

    func command(_ cmd: ScribeCommand, _ x: Int, _ y: Int) async {
        self.x = x
        self.y = y
        switch (self.state, self._state, cmd) {
        case (.running, .ready, .key(.ctrlC)):
            self.state = .shutdown
        case (.running, .ready, .key(.ctrlJ)):  // enter key
            // start selected program
            let p = await programs[selected].init()
            await sendHello(p, x, y: y)
            print("starting: \(p)")
            self._state = .running(p)
        case (.running, .running(let p), .key(let k)):
            await sendCommand(p, k, x, y)
            switch await p.getStatus() {
            case .working:
                ()
            case .close:
                print("shutting down: \(p)")
                self._state = .ready
                var data: [[String]] = [["Scribe", "[\(address)]", "\(cmd)"]]
                for prog in self.programs {
                    data.append(["\(prog)"])
                }
                self.page = Page(data)
            }
        default:
            var data: [[String]] = [["Scribe", "[\(address)]", "\(cmd)"]]
            for prog in self.programs {
                data.append(["\(prog)"])
            }
            self.page = Page(data)
        }
    }

    func sendHello(_ p: some Program, _ x: Int, y: Int) async {
        await p.command(with: .hello, x, y)
    }

    func sendCommand(_ p: some Program, _ key: AsciiKeyCode, _ x: Int, _ y: Int)
        async
    {
        let c = type(of: p).processKey(key)
        await p.command(with: c, x, y)
    }
}
