extension Page {
    public init(_ block: some Block) {
        let contents: [[String]] = unfold(block).map { [$0] }
        self = Page(contents)
    }
}

extension Block {
    public func select() -> some Block {
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

    mutating func press() {
        onlyPress(self.block)
    }

    private mutating func onlyPress(_ block: some Block) {
        if !selected {
            if let _ = block as? any SelectedBlockType {
                selected = true
                print(block)
            }
        }
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
