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

    private(set) var frame: Frame = Frame(80, 24)

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
        switch (self.state, self._state, cmd) {
        case (.running, .ready, .key(.ctrlC)):
            self.state = .shutdown
        case (.running, .ready, .key(.ctrlJ)):  // enter key
            let p = await programs[selected].init()
            print("starting: \(p)")
            self._state = .running(p)
        case (.running, .running(let p), .key(.ctrlC)):
            print("shutting down: \(p)")
            self._state = .ready
        default:
            var data: [[String]] = [["Scribe", "[\(address)]", "\(cmd)"]]
            for prog in self.programs {
                data.append(["\(prog)"])
            }
            self.page = Page(data)
            self.frame = page.renderWindow(x, y)
        }
    }
}
