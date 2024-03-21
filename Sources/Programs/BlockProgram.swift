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

    private var page: Page

    private var block: any Block = Main()

    struct Main: Block {
        @State var count = 0
        var component: some Block {
            Button("Hello \(count)") {
                count += 100
            }
        }
    }

    public init() async {
        self.page = Page(block)
    }

    public func command(
        with action: Command<BlockAction>, _ maxX: Int, _ maxY: Int
    ) async {
        print("Badtrace: \(BadTrace.id)")
        switch action {
        case .hello:
            ()
        case .action(.key(let k)):
            switch k {
            case .ctrlC:
                self.status = .close
            default:
                ()
            }
            let contents: [[String]] = unfoldAndPress(block).map { [$0] }
            self.page = Page(contents)
        }
        self.frame = self.page.renderWindow(maxX, maxY)
    }

    public func getFrame() async -> Frame {
        self.frame
    }

    public func getStatus() async -> Status {
        self.status
    }
}
