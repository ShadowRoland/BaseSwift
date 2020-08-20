//
//  SRDownloadManager.swift
//  SRFramework
//
//  Created by Gary on 2020/8/19.
//  Copyright © 2020 Sharow Roland. All rights reserved.
//

import UIKit
import SRKit
import Alamofire

open class SRDownloadManager: NSObject {
    public init(_ directory: String,
                operationQueue: OperationQueue? = nil,
                processReceiveQueue: DispatchQueue? = nil,
                timeoutInterval: TimeInterval = 60,
                httpSessionDelegate sessionDelegate: Alamofire.SessionDelegate? = nil) {
        var directoryPath = directory
        if let regex = try? NSRegularExpression(pattern: "[/\\\\]+$", options: .caseInsensitive) {
            directoryPath = regex.stringByReplacingMatches(in: directory,
                                           options: NSRegularExpression.MatchingOptions(rawValue: 0),
                                           range: NSMakeRange(0, directory.count),
                                           withTemplate: "")
        }
        let documentsDirectory = C.documentsDirectory
        if  directoryPath.count >= documentsDirectory.count && documentsDirectory == directoryPath[0 ... documentsDirectory.count] {
            self.downloadDirectory = directoryPath
            var relativeDirectory = directoryPath.substring(from: documentsDirectory.count)
            if let regex = try? NSRegularExpression(pattern: "^[/\\\\]+", options: .caseInsensitive) {
                relativeDirectory = regex.stringByReplacingMatches(in: directory,
                                               options: NSRegularExpression.MatchingOptions(rawValue: 0),
                                               range: NSMakeRange(0, directory.count),
                                               withTemplate: "")
            }
            self.relativeDownloadDirectory = relativeDirectory
        } else {
            self.downloadDirectory = C.documentsDirectory.appending(pathComponent: directory)
            self.relativeDownloadDirectory = directory
        }
        
        self.operationQueue = (operationQueue != nil) ? operationQueue! : OperationQueue()
        self.processReceiveQueue = (processReceiveQueue != nil) ? processReceiveQueue! : DispatchQueue(label: "com.srdownload.processCompletio")
        self.timeoutInterval = timeoutInterval
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = self.timeoutInterval
        self.httpSession = Alamofire.Session(configuration: configuration,
                                             delegate: sessionDelegate ?? SessionDelegate())
    }
    
    public var dbManager: SRDBManager?
    ///本地下载文件存储文件夹
    public let downloadDirectory: String
    public let relativeDownloadDirectory: String
    ///内部处理任务的OperationQueue
    public let operationQueue: OperationQueue
    ///内部调用网络或第三方处理后接收到结果后所在的DispatchQueue
    public let processReceiveQueue: DispatchQueue
    public let timeoutInterval: TimeInterval
    public let httpSession: Alamofire.Session
    
    ///提供给外部使用者操作完毕后的DispatchQueue
    fileprivate var isDelegateRespondGroupTaskStatusChanged = false
    fileprivate var isDelegateRespondGroupTaskProgressChanged = false
    fileprivate var isDelegateRespondItemTaskStatusChanged = false
    fileprivate var isDelegateRespondItemTaskProgressChanged = false
    weak open var delegate: SRDownloadManagerDelegate? {
        didSet {
            isDelegateRespondGroupTaskStatusChanged = false
            isDelegateRespondGroupTaskProgressChanged = false
            isDelegateRespondItemTaskStatusChanged = false
            isDelegateRespondItemTaskProgressChanged = false
            if let delegate = delegate {
                if delegate.responds(to: Selector(("downloadManager:groupTaskStatusChanged:"))) {
                    isDelegateRespondGroupTaskStatusChanged = true
                }
                if delegate.responds(to: Selector(("downloadManager:groupTaskProgressChanged:"))) {
                    isDelegateRespondGroupTaskProgressChanged = true
                }
                if delegate.responds(to: Selector(("downloadManager:itemTaskStatusChanged:"))) {
                    isDelegateRespondItemTaskStatusChanged = true
                }
                if delegate.responds(to: Selector(("downloadManager:itemTaskProgressChanged:"))) {
                    isDelegateRespondItemTaskProgressChanged = true
                }
            }
        }
    }
    open var completionQueue: DispatchQueue?
    open var maxConcurrentCount = 0
    open var allowedNetworkReachabilityStatus: NetworkReachabilityManager.NetworkReachabilityStatus = .reachable(.cellular)
    
    ///正在处理中的组任务
    open var didOnGroupTasks = [] as [SRDownloadGroupTaskModel]
    ///正在处理中的单项任务
    open var didOnItemTasks = [] as [SRDownloadItemTaskModel]
    
    open class SRDownloadProcessTask {
        public init(_ itemTask: SRDownloadItemTaskModel?) {
            self.itemTask = itemTask
        }
        ///直接关联的单项任务
        open var itemTask: SRDownloadItemTaskModel?
        ///关联的所有单项任务，当多个在处理中的组任务包含同一个url单项任务（单项任务的id相同）的时候，会将所有单项任务加入到此数组中，包括itemTask
        open var itemTasks = [] as [SRDownloadItemTaskModel]
        ///关联的实际处理任务，如HTTP下载关联的就是URLSessionDownloadTask
        open var processTask:  Any?
        
        ///根据itemTask的处理方式和类型等参数调用processTask对应的resume功能方法
        public func resume() -> Bool {
            guard let itemTask = itemTask, let processTask = processTask else { return false }
            switch itemTask.processWway {
                case .http:
                    switch itemTask.type {
                        case .download:
                            if let downloadTask = processTask as? URLSessionDownloadTask {
                                downloadTask.resume()
                                return true
                            }

                        case .upload:
                            if let downloadTask = processTask as? URLSessionUploadTask {
                                downloadTask.resume()
                                return true
                            }
                            
                        default: break
                    }
                
                default: break
            }
            return false
        }
        
        ///根据itemTask的处理方式和类型等参数调用processTask对应的suspend功能方法
        public func suspend() -> Bool {
            guard let itemTask = itemTask, let processTask = processTask else { return false }
            switch itemTask.processWway {
                case .http:
                    switch itemTask.type {
                        case .download:
                            if let downloadTask = processTask as? URLSessionDownloadTask {
                                downloadTask.suspend()
                                return true
                            }

                        case .upload:
                            if let downloadTask = processTask as? URLSessionUploadTask {
                                downloadTask.suspend()
                                return true
                            }
                            
                        default: break
                    }
                
                default: break
            }
            return false
        }
        
        ///根据itemTask的处理方式和类型等参数调用processTask对应的cancel功能方法
        public func cancel() -> Bool {
            guard let itemTask = itemTask, let processTask = processTask else { return false }
            switch itemTask.processWway {
                case .http:
                    switch itemTask.type {
                        case .download:
                            if let downloadTask = processTask as? URLSessionDownloadTask {
                                downloadTask.cancel()
                                return true
                            }

                        case .upload:
                            if let downloadTask = processTask as? URLSessionUploadTask {
                                downloadTask.cancel()
                                return true
                            }
                            
                        default: break
                    }
                
                default: break
            }
            return false
        }
    }
    
    ///关联对象，用于记录已开始处理或已暂停处理中的单项任务
    public var didOnOrDidSuspendProcessTasks = [] as [SRDownloadProcessTask]
    
    func localFilePath(_ itemTask: SRDownloadItemTaskModel, response: HTTPURLResponse? = nil) -> String? {
        var filePath: String?
        if itemTask.relativePath.trim.count > 0 {
            filePath = C.documentsDirectory.appending(pathComponent: itemTask.relativePath)
        } else if itemTask.fileName.trim.count > 0 {
            filePath = downloadDirectory.appending(pathComponent: itemTask.fileName)
            itemTask.relativePath = relativeDownloadDirectory.appending(pathComponent: itemTask.fileName)
        } else if let suggestedFilename = response?.suggestedFilename {
            filePath = downloadDirectory.appending(pathComponent: suggestedFilename)
            itemTask.relativePath = relativeDownloadDirectory.appending(pathComponent: suggestedFilename)
        }
        return filePath
    }
    
    func updateProgress(_ object: SRDownloadProcessTask?, completed: Int64, total: Int64) {
        guard let object = object, let itemTask = object.itemTask else { return }
        itemTask.completed = completed
        itemTask.total = total
        print("progress: \(completed)/\(total)")
        itemTaskProgressChanged(itemTask)
        object.itemTasks.forEach {
            if let groupTask = $0.groupTask {
                groupTask.completed = groupTask.completedConfirm + completed
                groupTaskProgressChanged(groupTask)
            }
        }
    }
    
    func groupTaskStatusChanged(_ groupTask: SRDownloadGroupTaskModel) {
        if isDelegateRespondGroupTaskProgressChanged {
            (completionQueue ?? DispatchQueue.main).async { [weak self] in
                if let strongSelf = self {
                    strongSelf.delegate?.downloadManager(strongSelf,
                                                         groupTaskStatusChanged: groupTask)
                }
            }
        }
    }
    
    func groupTaskProgressChanged(_ groupTask: SRDownloadGroupTaskModel) {
        if isDelegateRespondGroupTaskProgressChanged {
            (completionQueue ?? DispatchQueue.main).async { [weak self] in
                if let strongSelf = self {
                    strongSelf.delegate?.downloadManager(strongSelf,
                                                         groupTaskProgressChanged: groupTask)
                }
            }
        }
    }
    
    func itemTaskStatusChanged(_ itemTask: SRDownloadItemTaskModel) {
        if itemTask.status == .didOn {
            
        }
        if isDelegateRespondItemTaskStatusChanged {
            (completionQueue ?? DispatchQueue.main).async { [weak self] in
                if let strongSelf = self {
                    strongSelf.delegate?.downloadManager(strongSelf,
                                                         itemTaskStatusChanged: itemTask)
                }
            }
        }
    }
    
    func itemTaskProgressChanged(_ itemTask: SRDownloadItemTaskModel) {
        if isDelegateRespondItemTaskProgressChanged {
            (completionQueue ?? DispatchQueue.main).async { [weak self] in
                if let strongSelf = self {
                    strongSelf.delegate?.downloadManager(strongSelf,
                                                         itemTaskProgressChanged: itemTask)
                }
            }
        }
    }
    
    //MARK: - 网络或使用第三方进行下载/上传
    
    open func createProcessTask(_ itemTask: SRDownloadItemTaskModel,
                                       processTask: ((_ itemTask: SRDownloadItemTaskModel) -> SRDownloadProcessTask)? = nil) {
        let operation = BlockOperation { [weak self] in
            var object: SRDownloadProcessTask?
            if let processTask = processTask {
                object = processTask(itemTask)
            } else {
                switch itemTask.processWway {
                    case .http:
                        switch itemTask.type {
                            case .download:
                                object = self?.createHTTPDownloadProcessTask(itemTask)
                            
                            case .upload:
                                object = self?.createHTTPUploadProcessTask(itemTask)

                            default: break
                        }
                        
                    default: break
                }
            }
            
            if let object = object, let itemTask = object.itemTask {
                itemTask.status = .didOn
                itemTask.planStatus = .default
                object.itemTasks.append(nonduplicated: itemTask)
                self?.didOnOrDidSuspendProcessTasks.append(nonduplicated: object)
                self?.itemTaskStatusChanged(itemTask)
            }
        }
        operationQueue.addOperation(operation)
    }
    
    public func createHTTPDownloadProcessTask(_ itemTask: SRDownloadItemTaskModel) -> SRDownloadProcessTask? {
        guard let url = URL(string: itemTask.url) else { return nil }
        var object = SRDownloadProcessTask(itemTask)
        let request = URLRequest(url: url, timeoutInterval: timeoutInterval)
        let processTask = httpSession.download(request) { [weak self] (url, response) -> (destinationURL: URL, options: DownloadRequest.Options) in
            if let itemTask = object.itemTask,
                let filePath = self?.localFilePath(itemTask, response: response) {
                var options: DownloadRequest.Options = .init()
                if itemTask.type == .download {
                    options = [.createIntermediateDirectories, .removePreviousFile]
                } else if itemTask.type == .upload {
                    options = .createIntermediateDirectories
                }
                return (destinationURL: URL(fileURLWithPath: filePath), options: options)
            } else {
                return (destinationURL: URL(fileURLWithPath: ""), options: .init())
            }
        }.downloadProgress(queue: processReceiveQueue) { [weak self] progress in
            self?.updateProgress(object, completed: progress.completedUnitCount, total: progress.totalUnitCount)
        }.response(queue: processReceiveQueue) { [weak self] response in
            self?.didOnOrDidSuspendProcessTasks.remove(object: object)
            if let itemTask = object.itemTask {
                self?.didOnItemTasks.remove(object: itemTask)
                if let error = response.error {
                    if (itemTask.planStatus != .default) {
                        print("item task aborted: \(itemTask.url)")
                    } else {
                        itemTask.status = .didFail
                        itemTask.updateTime = Int(Date().timeIntervalSince1970)
                        itemTask.endTime = 0
                        itemTask.errorMessage = error.localizedDescription
                        self?.itemTaskStatusChanged(itemTask)
                    }
                } else {
                    itemTask.status = .didEnd
                    itemTask.updateTime = Int(Date().timeIntervalSince1970)
                    itemTask.endTime = itemTask.updateTime
                    itemTask.errorMessage = ""
                    self?.itemTaskStatusChanged(itemTask)
                }
            }
        }
        object = SRDownloadProcessTask(itemTask)
        object.processTask = processTask
        return object
    }
    
    public func createHTTPUploadProcessTask(_ itemTask: SRDownloadItemTaskModel) -> SRDownloadProcessTask? {
        var isDirectory: ObjCBool = false
        guard let url = URL(string: itemTask.url),
            let filePath = localFilePath(itemTask),
            FileManager.default.fileExists(atPath: filePath, isDirectory: &isDirectory)
                && !isDirectory.boolValue else {
            return nil
        }
        
        var object = SRDownloadProcessTask(itemTask)
        let processTask = httpSession.upload(multipartFormData:
            { [weak self] formData in
                if let itemTask = object.itemTask,
                    let filePath = self?.localFilePath(itemTask) {
                    formData.append(URL(fileURLWithPath: filePath), withName: itemTask.fileName)
                }
            },
            to: url)
            .uploadProgress(queue: processReceiveQueue) { [weak self] progress in
                self?.updateProgress(object, completed: progress.completedUnitCount, total: progress.totalUnitCount)
            }.response(queue: processReceiveQueue) { [weak self] response in
                self?.didOnOrDidSuspendProcessTasks.remove(object: object)
                if let itemTask = object.itemTask {
                    self?.didOnItemTasks.remove(object: itemTask)
                    if let error = response.error {
                        if itemTask.planStatus != .default {
                            print("item task aborted: \(itemTask.url)")
                        } else {
                            itemTask.status = .didFail
                            itemTask.updateTime = Int(Date().timeIntervalSince1970)
                            itemTask.endTime = 0
                            itemTask.errorMessage = error.localizedDescription
                            self?.itemTaskStatusChanged(itemTask)
                        }
                    } else {
                        itemTask.status = .didEnd
                        itemTask.updateTime = Int(Date().timeIntervalSince1970)
                        itemTask.endTime = itemTask.updateTime
                        itemTask.errorMessage = ""
                        self?.itemTaskStatusChanged(itemTask)
                    }
                }
            }

        object = SRDownloadProcessTask(itemTask)
        object.processTask = processTask
        return object
    }
}

public protocol SRDownloadManagerDelegate: NSObjectProtocol {
    func downloadManager(_ manager: SRDownloadManager, groupTaskStatusChanged groupTask: SRDownloadGroupTaskModel)
    func downloadManager(_ manager: SRDownloadManager, groupTaskProgressChanged groupTask: SRDownloadGroupTaskModel)
    func downloadManager(_ manager: SRDownloadManager, itemTaskStatusChanged itemTask: SRDownloadItemTaskModel)
    func downloadManager(_ manager: SRDownloadManager, itemTaskProgressChanged itemTask: SRDownloadItemTaskModel)
}
