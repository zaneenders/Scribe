public protocol Block {
    associatedtype Component: Block
    @BlockParser var component: Component { get }
}

@resultBuilder
public enum BlockParser {
    public static func buildPartialBlock(first content: some Block)
        -> some Block
    {
        return content
    }

    public static func buildPartialBlock(
        accumulated: some Block, next: some Block
    )
        -> some Block
    {
        return TupleBlock(value: (accumulated, next))
    }
}

extension Page {
    public init(_ block: some Block) {
        let contents: [[String]] = unfold(block).map { [$0] }
        self = Page(contents)
    }

}

func unfold(_ block: some Block) -> [String] {
    if let l1 = block as? LevelOneBlock {
        switch l1.type {
        case .button:
            let b = l1 as! Button
            return [b.label]
        case .tuple:
            let t = l1 as! TupleBlock
            let f = unfold(t.value.first)
            let s = unfold(t.value.secound)
            return f + s
        }
    } else {
        return unfold(block.component)
    }
}

public func unfoldAndPress(_ block: some Block) -> [String] {
    if let l1 = block as? LevelOneBlock {
        switch l1.type {
        case .button:
            let b = l1 as! Button
            b.action()
            return [b.label]
        case .tuple:
            let t = l1 as! TupleBlock
            let f = unfoldAndPress(t.value.first)
            let s = unfoldAndPress(t.value.secound)
            return f + s
        }
    } else {
        return unfoldAndPress(block.component)
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
