protocol LevelOneBlock {
    var type: LevelOneBlockType { get }
}

enum LevelOneBlockType {
    case array
    case button
    case text
    case tuple
}

extension LevelOneBlock {
    public var component: some Block {
        return Nothing()
    }
}
