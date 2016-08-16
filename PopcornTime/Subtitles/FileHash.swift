import Foundation

private let chunkSize: Int = 65536

public struct FileHash {
    var hash: String
    var size: UInt64
    var name: String
}

private func applyChunk(hash: UInt64, chunk: NSData) -> UInt64 {
    let bytes = UnsafeBufferPointer<UInt64>(
        start: UnsafePointer(chunk.bytes), count: chunk.length / sizeof(UInt64)
    )

    return bytes.reduce(hash, combine: &+)
}

private func getChunk(f: NSFileHandle, start: UInt64) -> NSData {
    f.seekToFileOffset(start)
    return f.readDataOfLength(chunkSize)
}

private func hexHash(hash: UInt64) -> String {
    return String(format:"%qx", hash)
}

private func fileSize(f: NSFileHandle) -> UInt64 {
    f.seekToEndOfFile()
    return f.offsetInFile
}

public func fileHash(path: String) -> FileHash? {
    if let f = NSFileHandle(forReadingAtPath: path) {
        let size = fileSize(f)
        if size < UInt64(chunkSize) {
            return nil
        }

        let start = getChunk(f, start: 0)
        let end = getChunk(f, start: size - UInt64(chunkSize))
        var hash = size
        hash = applyChunk(hash, chunk: start)
        hash = applyChunk(hash, chunk: end)

        f.closeFile()
        return FileHash(hash: hexHash(hash), size: size, name: path.lastPathComponent)
    }
    return nil
}


class HashAlgorithm: NSObject {
    let chunkSize: Int = 65536

    struct VideoHash {
        var fileHash: String
        var fileSize: UInt64
        var fileName: String
    }

    func hashForPath(path: String) -> VideoHash? {
        var fileHash = VideoHash(fileHash: "", fileSize: 0, fileName: "")
        if let fileHandler = NSFileHandle(forReadingAtPath: path) {
            let fileDataBegin: NSData = fileHandler.readDataOfLength(chunkSize)
            fileHandler.seekToEndOfFile()

            let fileSize: UInt64 = fileHandler.offsetInFile
            if UInt64(chunkSize) > fileSize {
                return fileHash
            }

            fileHandler.seekToFileOffset(max(0, fileSize - UInt64(chunkSize)))
            let fileDataEnd: NSData = fileHandler.readDataOfLength(chunkSize)

            var hash: UInt64 = fileSize

            var data_bytes = UnsafeBufferPointer<UInt64>(start: UnsafePointer(fileDataBegin.bytes), count: fileDataBegin.length/sizeof(UInt64))
            hash = data_bytes.reduce(hash, combine: &+)

            data_bytes = UnsafeBufferPointer<UInt64>(start: UnsafePointer(fileDataEnd.bytes), count: fileDataEnd.length/sizeof(UInt64))
            hash = data_bytes.reduce(hash, combine: &+)

            fileHash.fileHash = String(format:"%qx", arguments: [hash])
            fileHash.fileSize = fileSize
            fileHash.fileName = path.lastPathComponent

            fileHandler.closeFile()
            return fileHash
        }
        return nil
    }
}
