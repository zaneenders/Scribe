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
