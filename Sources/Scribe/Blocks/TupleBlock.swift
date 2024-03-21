struct TupleBlock: Block {
    var first: any Block
    var second: any Block

    init<B0: Block, B1: Block>(first: B0, second: B1) {
        self.first = first
        self.second = second
    }
}

extension TupleBlock: LevelOneBlock {
    var type: LevelOneBlockType {
        .tuple
    }
}
