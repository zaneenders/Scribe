extension Page {
    public init(_ block: some Block) {
        let contents: [[String]] = unfold(block).map { [$0] }
        self = Page(contents)
    }
}

extension Block {
    public func selected() -> some Block {
        SelectedBlock(wrapped: self)
    }
}

struct SelectedBlock<B: Block>: Block, SelectedBlockType {
    var wrapped: B
    var component: some Block {
        wrapped
    }
}

protocol SelectedBlockType {
    associatedtype B = Block
    var wrapped: B { get }
}

extension BlockState: CustomStringConvertible {
    var description: String {
        self.dag.description
    }
}

extension Page {

    init(_ node: L2Node) {
        self = Page(Page.getStrings(node))
    }

    private static func getStrings(_ node: L2Node) -> [[String]] {
        var out: [[String]] = []
        switch node {
        case .selected(let n):
            out.append(["SELECTED"])
        case .array(let arr):
            for n in arr {
                out += getStrings(n)
            }
        case .button(let b):
            out.append(["[\(b)]"])
        case .text(let t):
            out.append([t])
        }
        return out
    }
}

struct BlockState {
    let block: any Block
    private var dag: L2Node!
    private var selectedPath: [PathNode]

    init(_ block: any Block) {
        self.block = block
        self.selectedPath = []
        self.dag = parse(self.block)
        self.selectedPath = updateSelected(self.dag)
    }

    func buildFrame(_ x: Int, _ y: Int) -> Frame {
        let read = read(self.block, self.selectedPath)
        let page = Page(read)
        return page.renderWindow(x, y)
    }

    mutating func parse() {
        self.dag = parse(self.block, self.selectedPath)
    }

    mutating func press() {
        onlyPress(self.block)
        self.dag = parse(self.block, self.selectedPath)
    }

    mutating func down() {
        #warning("Does not mutate block so doesn't trigger buildFrame")
        self.selectedPath = moveDown(self.selectedPath)
        self.dag = updateSelected(self.dag, self.selectedPath)
    }

    private func flattenArrays(_ node: L2Node) -> L2Node {
        switch node {
        case .selected(let n):
            return .selected(flattenArrays(n))
        case .array(let arr):
            var out: [L2Node] = []
            for n in arr {
                let c = flattenArrays(n)
                switch c {
                case .selected, .text, .button:
                    out.append(c)
                case .array(let _arr):
                    out += _arr
                }
            }
            return .array(out)
        case .button, .text:
            return node
        }
    }

    private func flattenTuples(_ node: Node) -> L2Node {
        switch node {
        case .composed(let n):
            return flattenTuples(n)
        case .selected(let n):
            return .selected(flattenTuples(n))
        case let .tuple(l, r):
            return .array([
                flattenTuples(l),
                flattenTuples(r),
            ])
        case .array(let arr):
            return .array(arr.compactMap { flattenTuples($0) })
        case .button(let b):
            return .button(b)
        case .text(let t):
            return .text(t)
        }
    }

    private func layout(_ node: Node) {
        switch node {
        case .composed(let n):
            layout(n)
        case .selected(let n):
            layout(n)
        case let .tuple(l, r):
            layout(l)
            layout(r)
        case .array(let arr):
            for n in arr {
                layout(n)
            }
        case .button:
            ()
        case .text:
            ()
        }
    }

    indirect enum Node: Codable {
        case text(String)
        case button(String)
        case array([Node])
        case tuple(Node, Node)
        case selected(Node)
        case composed(Node)
    }

    private func moveDown(_ path: [PathNode]) -> [PathNode] {
        guard let first = path.first else {
            return []
        }
        var copy = path
        let rest = copy.dropFirst()
        switch first {
        case .text, .button:
            return [first]
        case .array(let index):
            switch rest.first {
            case .none, .text, .button, .array:
                return [first] + moveDown(Array(rest))
            case .selected:
                return [.array(index: index + 1)] + moveDown(Array(rest))
            }
        case .selected:
            return path
        }
    }

    private func moveDown(_ block: L2Node) -> L2Node {
        switch block {
        case .text, .button:
            return block
        case .array(let arr):
            var out: [L2Node] = []
            var found = false
            for c in arr {
                switch peek(selected: c) {
                case .selected:
                    found = true
                    let n = moveDown(c)
                    out.append(moveDown(n))
                default:
                    if found {
                        found = false
                        let n = moveDown(c)
                        out.append(.selected(n))
                    } else {
                        out.append(c)
                    }
                }
            }
            return .array(out)
        case .selected(let s):
            return moveDown(s)
        }
    }

    enum PeekNode {
        case selected
        case text
        case button
        case array
    }

    private func peek(selected block: L2Node) -> PeekNode {
        switch block {
        case .button:
            return .button
        case .text:
            return .text
        case .array:
            return .array
        case .selected:
            return .selected
        }
    }

    private func isSelected(_ block: L2Node) -> Bool {
        switch peek(selected: block) {
        case .button, .text, .array:
            return false
        case .selected:
            return true
        }
    }

    enum PathNode {
        case selected
        case text
        case button
        case array(index: Int)
    }

    private func updateSelected(_ block: L2Node) -> [PathNode] {
        switch block {
        case .selected(let n):
            switch n {
            case .selected:
                fatalError("Double selected: \(#function)")
            case .button, .text:
                return [.selected]
            case .array:
                fatalError("can't select array right now: \(#function)")
            }
        case .text, .button:
            return []
        case .array(let arr):
            for (i, n) in arr.enumerated() {
                var path = updateSelected(n)
                if path.count > 0 {
                    path.insert(.array(index: i), at: 0)
                    return path
                }
            }
            return []
        }
    }

    private func updateSelected(_ node: L2Node, _ prev: [PathNode]) -> L2Node {
        guard let first = prev.first else {
            print("empty prev path")
            return node
        }
        let rest = prev.dropFirst()
        switch (node, first) {
        case (let n, .selected):
            // TODO check that n and s match
            return .selected(n)
        case (.array(let nodes), .array(index: let i)):
            guard nodes.count > i else {
                print("array index fail")
                return node
            }
            let n = updateSelected(nodes[i], Array(rest))
            var copy = nodes
            copy[i] = n
            return .array(copy)
        default:
            return node
        }
    }

    private func read(_ block: some Block, _ prev: [PathNode] = [])
        -> L2Node
    {
        let l1 = read0(block)
        let l2 = flattenTuples(l1)
        let out = flattenArrays(l2)
        let new = updateSelected(out, prev)
        return new
    }

    private func read0(_ block: some Block) -> Node {
        if let l1 = block as? LevelOneBlock {
            switch l1.type {
            case .text:
                let t = l1 as! Text
                return .text(t.text)
            case .button:
                let b = l1 as! Button
                return .button(b.label)
            case .array:
                let a = l1 as! any ArrayBlocks
                var nodes: [Node] = []
                for b in a._blocks {
                    nodes.append(read0(b))
                }
                return .array(nodes)
            case .tuple:
                let t = l1 as! TupleBlock
                let f = read0(t.first)
                let s = read0(t.second)
                return .tuple(f, s)
            }
        } else {
            return .composed(read0(block.component))
        }
    }

    private mutating func parse(_ block: some Block, _ prev: [PathNode] = [])
        -> L2Node
    {
        let l1 = _parse(block)
        let l2 = flattenTuples(l1)
        let out = flattenArrays(l2)
        let new = updateSelected(out, prev)
        return new
    }

    private var selected = false

    private mutating func _parse(_ block: some Block) -> Node {
        if !selected {
            if let _ = block as? any SelectedBlockType {
                selected = true
                return .selected(_parse(block.component))
            }
        }
        if let l1 = block as? LevelOneBlock {
            switch l1.type {
            case .text:
                let t = l1 as! Text
                return .text(t.text)
            case .button:
                let b = l1 as! Button
                return .button(b.label)
            case .array:
                let a = l1 as! any ArrayBlocks
                var nodes: [Node] = []
                for b in a._blocks {
                    nodes.append(_parse(b))
                }
                return .array(nodes)
            case .tuple:
                let t = l1 as! TupleBlock
                let f = _parse(t.first)
                let s = _parse(t.second)
                return .tuple(f, s)
            }
        } else {
            return .composed(_parse(block.component))
        }
    }

    private func onlyPress(_ block: some Block) {
        if let l1 = block as? LevelOneBlock {
            switch l1.type {
            case .text:
                let _ = l1 as! Text
            case .button:
                let b = l1 as! Button
                b.action()
            case .array:
                let a = l1 as! any ArrayBlocks
                for b in a._blocks {
                    onlyPress(b)
                }
            case .tuple:
                let t = l1 as! TupleBlock
                onlyPress(t.first)
                onlyPress(t.second)
            }
        } else {
            onlyPress(block.component)
        }
    }
}

indirect enum L2Node: Codable {
    case text(String)
    case button(String)
    case array([L2Node])
    case selected(L2Node)
}

extension L2Node: CustomStringConvertible {
    var description: String {
        var out = ""
        switch self {
        case .selected(let n):
            out += "SELECTED[ \(n.description) ]"
        case .array(let arr):
            out += "ARRAY: ["
            for (i, n) in arr.enumerated() {
                if i == arr.count - 1 {
                    out += "\(n.description)"
                } else {
                    out += "\(n.description)"
                }
            }
            out += "]"
        case .button:
            out += "\n[BUTTON]"
        case .text:
            out += "\n(TEXT)"
        }
        return out
    }
}

extension BlockState.Node: CustomStringConvertible {
    var description: String {
        var out = ""
        switch self {
        case .composed(let n):
            out += "COMPOSED{ \(n.description) }"
        case .selected(let n):
            out += "SELECTED[ \(n.description) ]"
        case let .tuple(l, r):
            out += "Tuple: {"
            out += "\(l.description)"
            out += "\(r.description)"
            out += "}"
        case .array(let arr):
            out += "ARRAY: ["
            for (i, n) in arr.enumerated() {
                if i == arr.count - 1 {
                    out += "\(n.description)"
                } else {
                    out += "\(n.description)"
                }
            }
            out += "]"
        case .button:
            out += "\n[BUTTON]"
        case .text:
            out += "\n(TEXT)"
        }
        return out
    }
}

public func unfold(_ block: some Block) -> [String] {
    if let l1 = block as? LevelOneBlock {
        switch l1.type {
        case .text:
            let t = l1 as! Text
            return [t.text]
        case .array:
            let a = l1 as! any ArrayBlocks
            var out: [String] = []
            for b in a._blocks {
                out.append(contentsOf: unfold(b))
            }
            return out
        case .button:
            let b = l1 as! Button
            return [b.label]
        case .tuple:
            let t = l1 as! TupleBlock
            let f = unfold(t.first)
            let s = unfold(t.second)
            return f + s
        }
    } else {
        return unfold(block.component)
    }
}

public func onlyPress(_ block: some Block) {
    if let l1 = block as? LevelOneBlock {
        switch l1.type {
        case .text:
            let _ = l1 as! Text
        case .button:
            let b = l1 as! Button
            b.action()
        case .array:
            let a = l1 as! any ArrayBlocks
            for b in a._blocks {
                onlyPress(b)
            }
        case .tuple:
            let t = l1 as! TupleBlock
            onlyPress(t.first)
            onlyPress(t.second)
        }
    } else {
        onlyPress(block.component)
    }
}
