public protocol Block {
    associatedtype Component: Block
    @BlockParser var component: Component { get }
}

@resultBuilder
public enum BlockParser {
    public static func buildPartialBlock<B: Block>(first: B) -> B {
        first
    }

    public static func buildPartialBlock<B0: Block, B1: Block>(
        accumulated: B0, next: B1
    ) -> some Block {
        TupleBlock(first: accumulated, second: next)
    }

    public static func buildOptional<B: Block>(_ component: B?) -> some Block {
        ArrayBlock(blocks: component.map { [$0] } ?? [])
    }

    public static func buildEither(first component: some Block) -> some Block {
        ArrayBlock(blocks: [component])
    }

    public static func buildEither(second component: some Block) -> some Block {
        ArrayBlock(blocks: [component])
    }

    public static func buildArray<B: Block>(_ components: [B]) -> some Block {
        ArrayBlock(blocks: components)
    }
}

public struct ArrayBlock<B: Block>: Block, LevelOneBlock, ArrayBlocks {
    let type: LevelOneBlockType = .array
    let blocks: [B]

    var _blocks: [any Block] {
        blocks
    }
}

protocol ArrayBlocks {
    var _blocks: [any Block] { get }
}

extension Page {
    public init(_ block: some Block) {
        let contents: [[String]] = unfold(block).map { [$0] }
        self = Page(contents)
    }

}

public func unfold(_ block: some Block) -> [String] {
    if let l1 = block as? LevelOneBlock {
        switch l1.type {
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

public struct Button: Block {
    let label: String
    let action: () -> Void
}

extension Button: LevelOneBlock {
    var type: LevelOneBlockType {
        .button
    }
    public init(_ label: String, _ action: @escaping () -> Void) {
        self.label = label
        self.action = action
    }
}

protocol LevelOneBlock {
    var type: LevelOneBlockType { get }
}

enum LevelOneBlockType {
    case array
    case button
    case tuple
}

extension LevelOneBlock {
    public var component: some Block {
        return Nothing()
    }
}

struct Nothing: Block, LevelOneBlock {
    var type: LevelOneBlockType {
        fatalError("Nothing is not a block type")
    }
}
