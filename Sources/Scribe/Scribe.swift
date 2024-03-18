private enum IntenralState {
    case ready
    case running(any Program)
}
enum State {
    case running
    case shutdown
}

actor Scribe {
    private var _state: IntenralState
    var state: State

    init() {
        self.state = .running
        self._state = .ready
    }

    func getFrame(_ key: AsciiKeyCode, _ x: Int, _ y: Int) async -> Frame {
        switch self._state {
        case .ready:
            switch key {
            case .ctrlC:
                self.state = .shutdown
            default:
                let p = await ClientProgram()
                self._state = .running(p)
            }
            return Frame(x, y)
        case .running(let p):
            let frame = await helper(key, x, y, program: p)
            switch await p.getStatus() {
            case .close:
                self._state = .ready
            case .working:
                self._state = .running(p)
            }
            return frame
        }
    }

    private func helper(
        _ key: AsciiKeyCode, _ x: Int, _ y: Int, program: some Program
    ) async -> Frame {
        let cmd = type(of: program).processKey(key)
        return await program.getFrame(with: cmd, x, y)
    }
}
