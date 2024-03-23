public protocol Block {
    associatedtype Component: Block
    @BlockParser var component: Component { get }
}

struct Nothing: Block, LevelOneBlock {
    var type: LevelOneBlockType {
        fatalError("Nothing is not a block type")
    }
}
