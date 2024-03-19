struct TupleBlock: Block {
    let value: (first: any Block, secound: any Block)
}

extension TupleBlock: LevelOneBlock {
    var type: LevelOneBlockType {
        .tuple
    }
}
