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
