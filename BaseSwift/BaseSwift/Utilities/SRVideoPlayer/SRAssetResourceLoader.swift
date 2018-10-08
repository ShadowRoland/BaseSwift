//
//  SRAssetResourceLoader.swift
//  BaseSwift
//
//  Created by Gary on 2017/5/5.
//  Copyright © 2017年 shadowR. All rights reserved.
//

import UIKit
import AVFoundation

@objc protocol SRAssetResourceLoaderTaskDelegate {
    func resourceLoader(shouldLoad resourceLoader: SRAssetResourceLoader!) -> Bool
    func resourceLoader(didComplete resourceLoader: SRAssetResourceLoader!)
    func resourceLoader(didFail resourceLoader: SRAssetResourceLoader!, error: Error!)
}

class SRAssetResourceLoader: NSObject, AVAssetResourceLoaderDelegate, SRVideoRequestTaskDelegate {
    public weak var delegate: SRAssetResourceLoaderTaskDelegate?
    private(set) var isLoading = false

    private var loadingRequests: Set<AVAssetResourceLoadingRequest> = [] //所有的资源请求
    private var task: SRVideoRequestTask!
    
    init(url: URL!) {
        super.init()
        task = SRVideoRequestTask(url: url)
        task.delegate = self
    }
    
    public func cancel() {
        task.cancel()
        isLoading = false
    }
    
    public func suspend() {
        task.suspend()
        isLoading = false
    }
    
    public func resume() {
        task.resume()
        isLoading = true
    }
    
    func append(_ loadingRequest: AVAssetResourceLoadingRequest) {
        loadingRequests.insert(loadingRequest)
        let offset = UInt64(loadingRequest.dataRequest!.currentOffset)
        if task.currentSize > 0 {
            update()
        }
        
        if !isLoading {
            if let delegate = delegate, !delegate.resourceLoader(shouldLoad: self) {
                return
            }
            isLoading = true
            task.start(offset: offset)
        } else {
            if task.offset + task.currentSize + UInt64(1024 * 300) < offset //如果新起始位置比当前缓存的位置还大300k，则重新请求数据
                || offset < task.offset { //如果往回拖也重新请求
                isLoading = true
                task.start(offset: offset)
            }
        }
    }
    
    func update() {
        guard loadingRequests.count > 0 else {
            return
        }
        
        objc_sync_enter(loadingRequests)
        print("loadingRequests.count before: \(loadingRequests.count)")
        var loadingRequestsCompleted = [] as [AVAssetResourceLoadingRequest] //已完成的请求
        loadingRequests.forEach { loadingRequest in
            if respond(loadingRequest.dataRequest) { //如果已下载完成，把此次请求放进已完成的数组中
                loadingRequestsCompleted.append(loadingRequest)
                loadingRequest.finishLoading()
                print("loadingRequest finishLoading")
            }
        }
        loadingRequestsCompleted.forEach { loadingRequests.remove($0) }
        print("loadingRequests.count after: \(loadingRequests.count)")
        objc_sync_exit(loadingRequests)
    }
    
    func respond(_ dataRequest: AVAssetResourceLoadingDataRequest?) -> Bool {
        guard let dataRequest = dataRequest else {
            return false
        }
        
        print("--- respond start ---")
        let offset = dataRequest.currentOffset != 0
            ? UInt64(dataRequest.currentOffset)
            : UInt64(dataRequest.requestedOffset)
        guard offset >= task.offset && offset <= task.offset + task.currentSize else { //须在下载文件大小的范围内
            return false
        }
        
        // This is the total data we have from startOffset to whatever has been downloaded so far
        let unreadBytes = task.currentSize - (offset - task.offset)
        // Respond with whatever is available if we can't satisfy the request fully yet
        let respondBytes = min(unreadBytes, UInt64(dataRequest.requestedLength))
        let fileData = try! Data(contentsOf: URL(fileURLWithPath: task.videoCachePath!),
                                 options: .mappedIfSafe)
        let range = Int(offset - task.offset) ... Int(offset - task.offset + respondBytes)
        let dataRang: Range<Data.Index> = range.lowerBound ..< range.upperBound
        print("range: \(range.count)")
        print("dataRang.count: \(dataRang.count)")
        dataRequest.respond(with: fileData.subdata(in: range.lowerBound ..< range.upperBound))
        
        print("offset: \(offset)")
        print("respondBytes: \(respondBytes)")
        print("requestedLength: \(dataRequest.requestedLength)")
        print("task.offset: \(task.offset)")
        print("task.currentSize: \(task.currentSize)")
        print("--- respond end ---")
        return task.offset + task.currentSize >= offset + UInt64(dataRequest.requestedLength)
    }
    
    //MARK: - AVAssetResourceLoaderDelegate
    
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader,
                        shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        append(loadingRequest)
        return true
    }
    
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, didCancel loadingRequest: AVAssetResourceLoadingRequest) {
        loadingRequests.remove(loadingRequest)
    }
    
    //MARK: - SRVideoRequestTaskDelegate
    
    func task(didStart task: SRVideoRequestTask!) {
        isLoading = true
    }

    func task(didReceiveVideoData task: SRVideoRequestTask!) {
        update()
        isLoading = true
    }
    
    func task(didComplete task: SRVideoRequestTask!) {
        isLoading = false
    }
    
    func task(didFail task: SRVideoRequestTask!, error: Error!) {
        isLoading = false
    }
}
