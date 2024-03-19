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

private func buildDate(_ programs: [any Program.Type], _ address: String)
    -> [[String]]
{
    var data: [[String]] = []
    for (i, prog) in programs.enumerated() {
        if i == 0 {
            data.append(["\(prog)", "Scribe", "[\(address)]"])
        } else {
            data.append(["\(prog)"])
        }
    }
    return data
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
        let data = buildDate(programs, address)
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
                selected = 0
                let data = buildDate(programs, address)
                self.page = Page(data)
            }
        case (.running, .ready, .key(let k)):
            switch k {
            case .lowerCaseJ:
                if selected + 1 <= programs.count {
                    page.selected(move: .down)
                    selected += 1
                }
            case .lowerCaseK:
                // page.selected(move: .right)
                ()
            case .lowerCaseF:
                if selected - 1 >= 0 {
                    page.selected(move: .up)
                    selected -= 1
                }
            case .lowerCaseO:
                // page.selected(move: .left)
                ()
            default:
                ()

                let data = buildDate(programs, address)
                self.page = Page(data)
            }

        default:
            let data = buildDate(programs, address)
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
