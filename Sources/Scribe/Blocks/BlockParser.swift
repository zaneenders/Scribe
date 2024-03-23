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
