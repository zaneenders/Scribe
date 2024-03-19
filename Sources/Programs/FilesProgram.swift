import NIOFileSystem
import Scribe

public enum FilesAction: Action {
    case key(AsciiKeyCode)
}

public actor FilesProgram: Program {

    public typealias ActionType = FilesAction

    private var status: Status = .working
    private var frame: Frame = Frame(80, 24)
    private var page: Page
    private var dataIndex = 0
    private var entries: [DirectoryEntry] = []
    private var vcwd: FilePath
    private var state: State = .dir

    public init() async {
        self.dataIndex = 0
        var data: [[String]] = []
        let fileSystem = FileSystem.shared
        if let cwd = try? await fileSystem.currentWorkingDirectory {
            self.vcwd = cwd
            self.entries = await getEntries(for: cwd)
            for e in entries {
                data.append([e.path.string])
            }
            self.page = Page(data)
        } else {
            print("unable to find cwd")
            self.vcwd = FilePath("/")
            self.entries = []
            self.page = Page(data)
        }
    }

    public static func processKey(_ key: InputType) -> Command<FilesAction> {
        .action(.key(key))
    }

    public func getStatus() async -> Status {
        status
    }

    public func getFrame() async -> Frame {
        self.frame
    }

    public func command(
        with action: Command<FilesAction>, _ maxX: Int, _ maxY: Int
    ) async {
        switch action {
        case .hello:
            ()
        case .action(let a):
            switch self.state {
            case .dir:
                await updateDir(a)
            case .file:
                await updateFile(a)
            }
        }

        self.frame = page.renderWindow(maxX, maxY)
    }

    private enum State {
        case dir
        case file
    }

    private func updateFile(_ action: FilesAction) async {
        switch action {
        case .key(let k):
            switch k {
            case .ctrlC:
                self.status = .close
            case .lowerCaseJ:
                page.selected(move: .down)
            case .lowerCaseF:
                page.selected(move: .up)
            case .lowerCaseD:
                page.selected(move: .left)
            case .lowerCaseK:
                page.selected(move: .right)
            case .ctrlD:
                if let dir = DirectoryEntry(path: vcwd, type: .directory) {
                    self.state = .dir
                    await changeDir(dir)
                }
            default:
                ()
            }
        }
    }

    private func updateDir(_ action: FilesAction) async {
        switch action {
        case .key(let k):
            switch k {
            case .ctrlC:
                self.status = .close
            case .lowerCaseJ:
                page.selected(move: .down)
                if dataIndex + 1 < entries.count {
                    dataIndex += 1
                }
            case .lowerCaseF:
                page.selected(move: .up)
                if dataIndex - 1 < entries.count {
                    dataIndex -= 1
                }
            case .lowerCaseK:
                page.selected(move: .right)
                let selected = entries[dataIndex]
                await changeDir(selected)
            case .lowerCaseD:
                page.selected(move: .left)
                let p = vcwd.removingLastComponent()
                if let d = DirectoryEntry(path: p, type: .directory) {
                    await changeDir(d)
                }
            case .ctrlJ:  // Enter
                let selected = entries[dataIndex]
                await openFile(selected)
            default:
                ()
            }
        }
    }

    public func getFrame(
        with action: FilesAction, _ maxX: Int, _ maxY: Int
    ) async -> Frame {
        return page.renderWindow(maxX, maxY)
    }

    private func openFile(_ path: DirectoryEntry) async {
        if path.type == .regular {
            if let fh = try? await FileSystem.shared.openFile(
                forReadingAndWritingAt: path.path,
                options: OpenOptions.Write
                    .modifyFile(createIfNecessary: false))
            {
                if let info = try? await fh.info() {
                    if var data = try? await fh.readToEnd(
                        maximumSizeAllowed: .bytes(info.size))
                    {
                        if let str = data.readString(length: Int(info.size)) {
                            let lines = str.split(separator: "\n")
                            var data: [[String]] = []
                            for line in lines {
                                var row: [String] = []
                                for c in line {
                                    row.append(String(c))
                                }
                                data.append(row)
                            }
                            self.state = .file
                            self.page = Page(data)
                        }
                    }
                }
                try? await fh.close()
            }
        }
    }

    private func changeDir(_ path: DirectoryEntry) async {
        if path.type == .directory {
            vcwd = path.path
            self.entries = await getEntries(for: path.path)
            dataIndex = 0
            var data: [[String]] = []
            for e in entries {
                data.append([e.path.string])
            }
            self.page = Page(data)
        }
    }
}

private func getEntries(for path: FilePath) async -> [DirectoryEntry] {
    let fileSystem = FileSystem.shared
    var entries: [DirectoryEntry] = []
    let parrent = path.removingLastComponent()
    if let d = DirectoryEntry(path: parrent, type: .directory) {
        entries.append(d)
    } else {
        entries.append(
            DirectoryEntry(path: path, type: .directory)!)
    }
    if let fh = try? await fileSystem.openDirectory(atPath: path) {
        var i = fh.listContents().makeAsyncIterator()
        var n: DirectoryEntry?
        n = try? await i.next()
        while n != nil {
            entries.append(n!)
            n = try? await i.next()
        }
        try? await fh.close()
    }
    return entries
}
