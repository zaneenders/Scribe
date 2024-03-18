import Foundation

extension FileHandle {

    func asyncByteIterator() -> _FileHandleAsyncByteIterator {
        return _FileHandleAsyncByteIterator(fileHandle: self)
    }

    struct _FileHandleAsyncByteIterator: AsyncSequence {

        typealias Element = UInt8

        let fileHandle: FileHandle

        init(fileHandle: FileHandle) {
            self.fileHandle = fileHandle
        }

        struct AsyncIterator: AsyncIteratorProtocol {
            typealias Element = UInt8
            let fileHandle: FileHandle

            @available(*, deprecated, message: "Really bad, but works for now")
            mutating func next() async throws -> UInt8? {
                guard let data: Data = try fileHandle.read(upToCount: 1) else {
                    throw AsyncIteratorError.readError
                }
                return data.first
            }
        }

        func makeAsyncIterator() -> AsyncIterator {
            return AsyncIterator(fileHandle: fileHandle)
        }
    }
}

enum AsyncIteratorError: Error {
    case readError
}
