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

    private(set) var state: State
    private var _state: IntenralState
    private var page: Page
    private var programs: [any Program.Type]
    private var selected = 0
    private let address: String

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
        switch cmd {
        case .hello:
            ()
        case .key(let k):
            switch k {
            case .ctrlC:
                self.state = .shutdown
            default:
                ()
            }
        }
        var data: [[String]] = [["Scribe", "[\(address)]", "\(cmd)"]]
        for prog in self.programs {
            data.append(["\(prog)"])
        }
        self.page = Page(data)
        self.frame = page.renderWindow(x, y)
    }

    func getFrame(_ cmd: ScribeCommand, _ x: Int, _ y: Int) async -> Frame {
        switch cmd {
        case .hello:
            return page.renderWindow(x, y)
        case .key(let key):
            switch self._state {
            case .ready:
                switch key {
                case .ctrlC:
                    self.state = .shutdown
                case .ctrlJ:
                    if programs.count > selected {
                        let p = await programs[selected].init()
                        // TODO Send a hello command 1st
                        let frame = await helper(key, x, y, program: p)
                        self._state = .running(p)
                        return frame
                    }
                default:
                    var data: [[String]] = [
                        ["Scribe", "[\(address)]", "\(key)"]
                    ]
                    for prog in programs {
                        data.append(["\(prog)"])
                    }
                    self.page = Page(data)

                }
                return page.renderWindow(x, y)
            case .running(let p):
                let frame = await helper(key, x, y, program: p)
                switch await p.getStatus() {
                case .close:
                    self._state = .ready
                    return page.renderWindow(x, y)
                case .working:
                    self._state = .running(p)
                }
                return frame
            }
        }
    }

    private func helper(
        _ key: AsciiKeyCode, _ x: Int, _ y: Int, program: some Program
    ) async -> Frame {
        let cmd = type(of: program).processKey(key)
        return await program.getFrame(with: cmd, x, y)
    }
}
