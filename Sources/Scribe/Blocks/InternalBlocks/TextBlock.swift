public struct Text: Block {
    let text: String
}

extension Text: LevelOneBlock {
    var type: LevelOneBlockType {
        .text
    }
    public init(_ text: String) {
        self.text = text
    }
}
