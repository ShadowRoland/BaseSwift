//
//  SRVideoRequestTask.swift
//  BaseSwift
//
//  Created by Gary on 2017/5/4.
//  Copyright © 2017年 shadowR. All rights reserved.
//

import UIKit
import CryptoSwift

@objc protocol SRVideoRequestTaskDelegate {
    func task(didStart task: SRVideoRequestTask!)
    func task(didReceiveVideoData task: SRVideoRequestTask!)
    func task(didComplete task: SRVideoRequestTask!)
    func task(didFail task: SRVideoRequestTask!, error: Error!)
}

class SRVideoRequestTask: NSObject, URLSessionDataDelegate {
    private(set) var url: URL?
    private(set) var offset: UInt64 = 0
    private(set) var totalSize: UInt64 = 0
    private(set) var currentSize: UInt64 = 0
    private(set) var videoCachePath: String?
    public var isCompleted = false
    public weak var delegate: SRVideoRequestTaskDelegate?
    
    private var session: URLSession!
    private var task: URLSessionDataTask?
    private var stream: OutputStream!
    
    public init(url: URL!) {
        super.init()
        self.url = url
        SRVideoRequestTask.createFileItems()
        session = URLSession(configuration: URLSessionConfiguration.default,
                             delegate: self,
                             delegateQueue: OperationQueue.main)
    }
    
    deinit {
        session.invalidateAndCancel()
    }
    
    static var videosDirectory: String! //下载成功后存放的视频文件目录
    static var videosCacheDirectory: String! //下载中的视频缓存文件目录
    
    class func createFileItems() {
        guard videosDirectory == nil else {
            return
        }
        
        let document = String(describing: NSSearchPathForDirectoriesInDomains(.documentDirectory,
                                                                              .userDomainMask,
                                                                              true)[0])
        videosDirectory = document.appending(pathComponent: "Videos")
        var isDirectory: ObjCBool = false
        if FileManager.default.fileExists(atPath: videosDirectory, isDirectory: &isDirectory)
            && !isDirectory.boolValue {
            try! FileManager.default.removeItem(atPath: videosDirectory)
        }
        try! FileManager.default.createDirectory(atPath: videosDirectory,
                                                 withIntermediateDirectories: true,
                                                 attributes: nil)
        videosCacheDirectory = document.appending(pathComponent: "VideosCache")
        isDirectory = false
        if FileManager.default.fileExists(atPath: videosCacheDirectory, isDirectory: &isDirectory)
            && !isDirectory.boolValue {
            try! FileManager.default.removeItem(atPath: videosCacheDirectory)
        }
        try! FileManager.default.createDirectory(atPath: videosCacheDirectory,
                                                 withIntermediateDirectories: true,
                                                 attributes: nil)
    }
    
    public func start(offset: UInt64) {
        cancel()
        self.offset = offset
        
        let prefix = self.url!.absoluteString.md5()
        //在缓存目录下寻找合适的已缓存文件
        var isFind = false
        let subpaths = FileManager.default.subpaths(atPath: SRVideoRequestTask.videosCacheDirectory)?.filter { $0.hasPrefix(prefix) }
        for fileName in subpaths! {
            var offset: UInt64 = 0
            var components = fileName.components(separatedBy: ".")
            if components.count > 0 {
                components = components[0].components(separatedBy: "_")
                if components.count > 1, let number = UInt64(components[1]) {
                    offset = number
                }
            }
            let filePath =
                SRVideoRequestTask.videosCacheDirectory.appending(pathComponent: fileName)
            let attributes = try! FileManager.default.attributesOfItem(atPath: filePath)
            let currentSize = attributes[FileAttributeKey.size] as! UInt64
            if self.offset >= offset && self.offset <= offset + currentSize {
                isFind = true
                self.offset = offset
                self.currentSize = currentSize
                videoCachePath = filePath
                break
            }
        }
        
        //没有合适的已缓存文件，创建新的缓存文件
        if !isFind {
            let fileName = self.offset > 0
                ? self.url!.absoluteString.md5() + ".mp4"
                : self.url!.absoluteString.md5() + "_\(self.offset).mp4"
            videoCachePath =
                SRVideoRequestTask.videosCacheDirectory.appending(pathComponent: fileName)
            var isDirectory: ObjCBool = false
            currentSize = 0
            if FileManager.default.fileExists(atPath: videoCachePath!, isDirectory: &isDirectory) {
                if isDirectory.boolValue {
                    try! FileManager.default.removeItem(atPath: videoCachePath!)
                } else {
                    let attributes =
                        try! FileManager.default.attributesOfItem(atPath: videoCachePath!)
                    currentSize = attributes[FileAttributeKey.size] as! UInt64
                }
            }
        }
        totalSize = 0
        
        var request = URLRequest(url: self.url!)
        if currentSize > 0{
            request.addValue("bytes=\(currentSize)-", forHTTPHeaderField: "Range")
        }
        task = session.dataTask(with: request)
        print("video load task start, offset: \(self.offset), currentSize: \(self.currentSize)")
        task?.resume()
    }
    
    public func cancel() {
        task?.cancel()
    }
    
    public func suspend() {
        task?.suspend()
    }
    
    public func resume() {
        task?.resume()
    }

    public func clearCache() {
        //删除其他的缓存文件
        let prefix = url!.absoluteString.md5()
        let subpaths =
            FileManager.default.subpaths(atPath: SRVideoRequestTask.videosCacheDirectory)?.filter {
                $0.hasPrefix(prefix)
        }
        subpaths?.forEach {
            try! FileManager.default.removeItem(atPath: SRVideoRequestTask.videosDirectory.appending(pathComponent: $0))
        }
    }
    
    //MARK: - URLSessionTaskDelegate
    
    func urlSession(_ session: URLSession,
                    dataTask: URLSessionDataTask,
                    didReceive response: URLResponse,
                    completionHandler: @escaping (URLSession.ResponseDisposition) -> Swift.Void) {
        delegate?.task(didStart: self)
        totalSize = currentSize + UInt64(response.expectedContentLength)
        if response.expectedContentLength > 0 {
            stream = OutputStream(toFileAtPath: videoCachePath!, append: true)!
            stream.open()
            completionHandler(.allow)
        }
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        stream.write(data.bytes, maxLength: data.count)
        currentSize += UInt64(data.count)
        delegate?.task(didReceiveVideoData: self)
    }
    
    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    didCompleteWithError error: Error?) {
        stream.close()
        if let error = error {
            delegate?.task(didFail: self, error: error)
        } else {
            delegate?.task(didComplete: self)
            cancel()
            self.task = nil
            if offset == 0 { //在全文件完整缓存的情况下，将缓存文件“转正”
                let fileName = self.url!.absoluteString.md5() + ".mp4"
                let videoPath = SRVideoRequestTask.videosDirectory.appending(pathComponent: fileName)
                if FileManager.default.fileExists(atPath: videoPath) {
                    try! FileManager.default.removeItem(atPath: videoPath)
                }
                try! FileManager.default.moveItem(atPath: videoCachePath!, toPath: videoPath)
                videoCachePath = videoPath
                clearCache()
            }
        }
    }
}
