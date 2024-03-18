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
    private var avaible: [any Program.Type]
    private var selected = 0
    private let address: String

    init(_ address: String, _ programs: [any Program.Type]) {
        self.address = address
        self.avaible = programs
        self.state = .running
        self._state = .ready
        var data: [[String]] = [["Scribe", "[\(address)]"]]
        for prog in programs {
            data.append(["\(prog)"])
        }
        self.page = Page(data)
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
                    if avaible.count > selected {
                        let p = await avaible[selected].init()
                        // TODO Send a hello command 1st
                        let frame = await helper(key, x, y, program: p)
                        self._state = .running(p)
                        return frame
                    }
                default:
                    var data: [[String]] = [
                        ["Scribe", "[\(address)]", "\(key)"]
                    ]
                    for prog in avaible {
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
