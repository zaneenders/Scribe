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

struct BlockState {
    let block: any Block
    var selected = false  // TODO record parse path

    init(_ block: any Block) {
        self.block = block
    }

    func buildFrame(_ x: Int, _ y: Int) -> Frame {
        let contents: [[String]] = unfold(block).map { [$0] }
        let page = Page(contents)
        return page.renderWindow(x, y)
    }

    mutating func press() {
        onlyPress(self.block)
        let dag = parse(self.block)
        print(dag.description)
        layout(dag)
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

    indirect enum Node {
        case text
        case button
        case array([Node])
        case tuple(Node, Node)
        case selected(Node)
        case composed(Node)
    }

    private mutating func parse(_ block: some Block) -> Node {
        if !selected {
            if let _ = block as? any SelectedBlockType {
                self.selected = true
                return .selected(parse(block.component))
            }
        }
        if let l1 = block as? LevelOneBlock {
            switch l1.type {
            case .text:
                let _ = l1 as! Text
                return .text
            case .button:
                let _ = l1 as! Button
                return .button
            case .array:
                let a = l1 as! any ArrayBlocks
                var nodes: [Node] = []
                for b in a._blocks {
                    nodes.append(parse(b))
                }
                return .array(nodes)
            case .tuple:
                let t = l1 as! TupleBlock
                let f = parse(t.first)
                let s = parse(t.second)
                return .tuple(f, s)
            }
        } else {
            return .composed(parse(block.component))
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

extension BlockState.Node: CustomStringConvertible {
    var description: String {
        var out = ""
        switch self {
        case .composed(let n):
            out += " COMPOSED{ \(n.description) } "
        case .selected(let n):
            out += " SELECTED[ \(n.description) ] "
        case let .tuple(l, r):
            out += "Tuple: {\n "
            out += l.description
            out += " , "
            out += r.description
            out += " }\n"
        case .array(let arr):
            out += "ARRAY: [\n"
            for n in arr {
                out += "\(n.description), "
            }
            out += "]\n"
        case .button:
            out += "[BUTTON]"
        case .text:
            out += "(TEXT)"
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
