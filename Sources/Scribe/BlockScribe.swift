import Observation

actor BlockScribe {

    var state: ScribeState = .running
    private(set) var frame: Frame = Frame(80, 24)
    private var x: Int = 80
    private var y: Int = 24

    private var blockState: BlockState

    class StateObject: Observable {
        var name: String = "Zane"
    }

    public init(_ address: String, _ programs: [any Program.Type]) {
        let block = ScribeBlock(address: address, programs: programs)
        self.blockState = BlockState(block)
    }

    public func command(
        _ cmd: ScribeCommand, _ maxX: Int, _ maxY: Int
    ) async {
        self.x = maxX
        self.y = maxY
        print("Badtrace: \(BadTrace.id)")
        switch cmd {
        case .hello:
            await update()
        case .key(let k):
            switch k {
            case .ctrlC:
                self.state = .shutdown
            default:
                ()
            }
            self.blockState.press()
        }
        self.blockState.parse()
    }

    private func update() async {
        withObservationTracking(
            {
                self.frame = blockState.buildFrame(self.x, self.y)
                // Maybe we can change to pushed updates instead of pull
            },
            onChange: {
                Task { @MainActor in  // don't know if @MainActor is correct
                    await self.update()
                }
            })
    }

    public func frame() async -> Frame {
        print(self.blockState.description)
        return self.frame
    }
}

// withObersvationTracking is tricky with nested scope
class StateObject: Observable {
    var name: String = "Zane"
}

struct Main: Block {
    @Binding var count: Int
    var component: some Block {
        Button("\(count)") {
            count += 1
        }
        if count.isMultiple(of: 2) {
            Text("Even")
        }
        for i in 0..<3 {
            Text("row \(i)")
        }
    }
}

struct ScribeBlock: Block {
    let address: String
    let programs: [any Program.Type]

    var state: StateObject = StateObject()
    @State var count = 0

    var component: some Block {
        Button(state.name) {
            state.name += "!"
        }
        Text(address).selected()
        for p in programs {
            Text("\(p)")
        }
        Main(count: $count)
    }
}
