import Observation
import Scribe

public enum BlockAction: Action {
    case key(AsciiKeyCode)
}

public actor BlockProgram: Program {

    public typealias ActionType = BlockAction

    public static func processKey(_ key: InputType) -> Command<BlockAction> {
        .action(.key(key))
    }

    private(set) var status: Status = .working
    private(set) var frame: Frame = Frame(80, 24)
    private var x: Int = 80
    private var y: Int = 24

    private var page: Page

    private var block: any Block = Main()

    class StateObject: Observable {
        var name: String = "Zane"
    }

    struct Main: Block {
        var state: StateObject = StateObject()
        @State var count = 0
        var component: some Block {
            Button("\(state.name) \(count)") {
                count += 1
                state.name += "!"
            }
            Button("\(state.name) \(count)") {}
            if count.isMultiple(of: 2) {
                Button("Even") {}
            }
            for i in 0..<3 {
                Button("row \(i)") {}
            }
        }
    }

    public init() async {
        self.page = Page(block)
    }

    public func command(
        with action: Command<BlockAction>, _ maxX: Int, _ maxY: Int
    ) async {
        self.x = maxX
        self.y = maxY
        print("Badtrace: \(BadTrace.id)")
        switch action {
        case .hello:
            await update()
        case .action(.key(let k)):
            switch k {
            case .ctrlC:
                self.status = .close
            default:
                ()
            }
            onlyPress(block)
        }
    }

    private func update() async {
        withObservationTracking(
            {
                let contents: [[String]] = unfold(block).map { [$0] }
                self.page = Page(contents)
            },
            onChange: {
                Task { @MainActor in
                    await self.update()
                }
            })
    }

    public func getFrame() async -> Frame {
        page.renderWindow(x, y)
    }

    public func getStatus() async -> Status {
        self.status
    }
}
