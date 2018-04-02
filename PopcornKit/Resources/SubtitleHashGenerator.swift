//
//  This Swift 3 version is based on Swift 2 version by eduo:
//  https://gist.github.com/eduo/7188bb0029f3bcbf03d4
//
//  Created by Niklas Berglund on 2017-01-01.
//
import Foundation

public class OpenSubtitlesHash: NSObject {
    private static let chunkSize: Int = 65536
    
    public struct VideoHash {
        var fileHash: String
        var fileSize: UInt64
    }
    
    public class func hashFor(_ url: URL) -> VideoHash {
        return self.hashFor(url.path)
    }
    
    public class func hashFor(_ path: String) -> VideoHash {
        var fileHash = VideoHash(fileHash: "", fileSize: 0)
        let fileHandler = FileHandle(forReadingAtPath: path)!
        
        let fileDataBegin: NSData = fileHandler.readData(ofLength: chunkSize) as NSData
        fileHandler.seekToEndOfFile()
        
        let fileSize: UInt64 = fileHandler.offsetInFile
        if (UInt64(chunkSize) > fileSize) {
            return fileHash
        }
        
        fileHandler.seek(toFileOffset: max(0, fileSize - UInt64(chunkSize)))
        let fileDataEnd: NSData = fileHandler.readData(ofLength: chunkSize) as NSData
        
        var hash: UInt64 = fileSize
        
        var data_bytes = UnsafeBufferPointer<UInt64>(
            start: UnsafePointer(fileDataBegin.bytes.assumingMemoryBound(to: UInt64.self)),
            count: fileDataBegin.length/MemoryLayout<UInt64>.size
        )
        
        hash = data_bytes.reduce(hash,&+)
        
        data_bytes = UnsafeBufferPointer<UInt64>(
            start: UnsafePointer(fileDataEnd.bytes.assumingMemoryBound(to: UInt64.self)),
            count: fileDataEnd.length/MemoryLayout<UInt64>.size
        )
        
        hash = data_bytes.reduce(hash,&+)
        
        fileHash.fileHash = String(format:"%016qx", arguments: [hash])
        fileHash.fileSize = fileSize
        
        fileHandler.closeFile()
        
        return fileHash
    }
}

// Usage example:
// let videoUrl = Bundle.main.url(forResource: "dummy5", withExtension: "rar")
// let videoHash = OpenSubtitlesHash.hashFor(videoUrl!)
// debugPrint("File hash: \(videoHash.fileHash)\nFile size: \(videoHash.fileSize)")
