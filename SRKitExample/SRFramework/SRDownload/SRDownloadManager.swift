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
import FMDB
import ObjectMapper

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
    
    public var dbManager: SRDBManager!
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
        public func resume() throws {
            guard let itemTask = itemTask, let processTask = processTask else { return }
            switch itemTask.processWway {
                case .http:
                    switch itemTask.type {
                        case .download:
                            if let downloadTask = processTask as? URLSessionDownloadTask {
                                downloadTask.resume()
                            }

                        case .upload:
                            if let downloadTask = processTask as? URLSessionUploadTask {
                                downloadTask.resume()
                            }
                            
                        default: break
                    }
                
                default: break
            }
        }
        
        ///根据itemTask的处理方式和类型等参数调用processTask对应的suspend功能方法
        public func suspend() throws {
            guard let itemTask = itemTask, let processTask = processTask else { return }
            switch itemTask.processWway {
                case .http:
                    switch itemTask.type {
                        case .download:
                            if let downloadTask = processTask as? URLSessionDownloadTask {
                                downloadTask.suspend()
                            }

                        case .upload:
                            if let downloadTask = processTask as? URLSessionUploadTask {
                                downloadTask.suspend()
                            }
                            
                        default: break
                    }
                
                default: break
            }
        }
        
        ///根据itemTask的处理方式和类型等参数调用processTask对应的cancel功能方法
        public func cancel() throws {
            guard let itemTask = itemTask, let processTask = processTask else { return }
            switch itemTask.processWway {
                case .http:
                    switch itemTask.type {
                        case .download:
                            if let downloadTask = processTask as? URLSessionDownloadTask {
                                downloadTask.cancel()
                            }

                        case .upload:
                            if let downloadTask = processTask as? URLSessionUploadTask {
                                downloadTask.cancel()
                            }
                            
                        default: break
                    }
                
                default: break
            }
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
    
    //MARK: -
    
    func itemTaskDidEnd(_ object: SRDownloadProcessTask, db inDB: FMDatabase? = nil) throws {
        guard let itemTask = object.itemTask else { return }
        let db = try open(db: inDb)
        defer { closeIfNeed(db, inDb) }
        
//        do {
//            try dbManager.updateModels(itemTask, context: .up, db: <#T##FMDatabase?#>)
//        } catch <#pattern#> {
//            <#statements#>
//        }
        
//            DownloadItemTask *task = (DownloadItemTask *)object.downloadTask;
//
//            DB_OPEN_WITH_INDB_ERROR
//            if (![self updateDownloadItemTaskWithStatusInfo:task inDb:db error:error]) {
//                RETURN_NO_WITH_CLOSE_DB_IF_NEED
//            }
//
//            @synchronized (_httpOnDownloadGroupTasks) {
//                for (DownloadItemTask *itemTask in object.associateTasks) {
//                    DownloadGroupTask *groupTask = itemTask.groupTask;
//                    if (!groupTask) {
//                        continue;
//                    }
//
//                    itemTask.status = task.status;
//                    itemTask.updateTime = task.updateTime;
//                    itemTask.endTime = task.endTime;
//                    itemTask.errorMessage = task.errorMessage;
//
//                    groupTask.updateTime = itemTask.updateTime;
//                    groupTask.completed += itemTask.total;
//
//                    groupTask.total = groupTask.completed;
//                    for (NSInteger i = groupTask.downloadingItemIndex + 1; i < groupTask.itemTasks.count; i++) {
//                        groupTask.total += [(DownloadItemTask *)groupTask.itemTasks[i] total];
//                    }
//
//                    if (groupTask.downloadingItemIndex < groupTask.itemTasks.count) {
//                        groupTask.downloadingItemIndex++;
//                        if (!groupTask.downloadingItemTask) { //当前已经没有需要进行的任务组任务完成
//                            groupTask.status = DownloadTaskStatusDidEnd;
//                            groupTask.endTime = itemTask.endTime;
//                            groupTask.errorMessage = itemTask.errorMessage;
//        //                    if (![self updateDownloadGroupTaskWithStatusInfo:groupTask inDb:db error:error]) { //更新数据库中组任务状态
//        //                        RETURN_NO_WITH_CLOSE_DB_IF_NEED
//        //                    }
//                            if (![self updateDownloadGroupTaskWithStatusInfo:groupTask inDb:db error:error]) {
//                                RETURN_NO_WITH_CLOSE_DB_IF_NEED
//                            }
//                            [_httpOnDownloadGroupTasks removeObject:groupTask];
//                            [self groupTaskStatusChanged:groupTask];
//                        } else { //继续进行下一个单项任务，直到所有子单项任务完成或失败为止
//                            if (![self updateDownloadGroupTaskWithStatusInfo:groupTask inDb:db error:error]
//                                || ![self resumeDownloadItemTask:groupTask.downloadingItemTask inDb:db error:error]) { //更新数据库中组任务状态
//                                RETURN_NO_WITH_CLOSE_DB_IF_NEED
//                            }
//                        }
//                    }
//                }
//            }
//
//            RETURN_YES_WITH_CLOSE_DB_IF_NEED
    }
    
    //MARK: -
    
    open func open(db: FMDatabase?) throws -> FMDatabase {
        if let db = db {
            return db
        } else {
            return try dbManager.open()
        }
    }
    
    open func closeIfNeed(_ db: FMDatabase?, _ inDb: FMDatabase?) {
        if db !== inDb {
            db?.close()
        }
    }
    
    open func resume(_ itemTask: SRDownloadItemTaskModel, db inDB: FMDatabase? = nil) throws {
        let db = try open(db: inDb)
        defer { closeIfNeed(db, inDb) }
        
//        do {
//            //下载/上传的处理任务仍被本组任务正在下载的单项任务所管理
//            if let object = didOnOrDidSuspendProcessTasks.first(where: { itemTask === $0.itemTask }) {
//                if itemTask.status == .didSuspend { //如果已被暂停，重新拉起来
//                    try object.resume()
//                    didOnItemTasks.append(nonduplicated: itemTask)
//                    return
//                }
//            }
//
//            //首先在正在进行的任务内存列表中进行查询匹配
//            if let existedItemTask = didOnItemTasks.first(where: { itemTask == $0 }) {
//                //其他组任务的单项任务已经正在进行中，只需同步单项任务状态
//                itemTask.mappingDB(map: Map(mappingType: .fromJSON,
//                                            JSON: existedItemTask.toJSON(),
//                                            context: SRDBMapContext(elements: [SRDBMapContext.selectAll])))
//                if let object = didOnOrDidSuspendProcessTasks.first(where: { itemTask === $0.itemTask }) {
//                    //将当前task加入到关联列表中
//                    object.itemTasks.append(nonduplicated: itemTask)
//                }
//                return
//            }
//
//            let itemTasks = try dbManager.selectModels(itemTask)
//            if itemTasks.count > 1 {
//                throw BFError("duplicated record of item task in table: \(itemTask.tableName), id: \(itemTask.id)")
//            } else if itemTasks.count == 1 {
//                //数据库中保存着最新的任务状态
//                let dbItemTask = itemTasks.first as! SRDownloadItemTaskModel
//                itemTask.mappingDB(map: Map(mappingType: .fromJSON,
//                                            JSON: dbItemTask.toJSON(),
//                                            context: SRDBMapContext(elements: [SRDBMapContext.selectAll])))
//                if itemTask.status == .didEnd { //该文件已下载完成
//                    try itemTaskDidEnd(itemTask)
//                    return
//                }
//            }
//
//            DB_OPEN_WITH_INDB_ERROR
//            //在数据库中查询匹配，获取最新的任务状态
//            NSArray *tasks;
//            if (![self selectDownloadItemTasksWithTask:task inDb:db tasks:&tasks error:error]) {
//                RETURN_NO_WITH_CLOSE_DB_IF_NEED
//            } else {
//                if (tasks.count > 1) {
//                    *error = LocalError(@"存在重复的单项任务: %@", task.url);
//                    RETURN_NO_WITH_CLOSE_DB_IF_NEED
//                }
//
//                if (tasks.count == 1) { //数据库中保存着最新的任务状态
//                    DownloadGroupTask *groupTask = task.groupTask;
//                    [task syncProperties:tasks.firstObject];
//                    task.groupTask = groupTask;
//                    if (task.status == DownloadTaskStatusDidEnd) { //该文件已下载完成
//                        if ([self downloadItemTaskDidEnd:[DownloadTaskWithWay wayWithTask:task] inDb:db error:error]) {
//                            RETURN_YES_WITH_CLOSE_DB_IF_NEED
//                        } else {
//                            RETURN_NO_WITH_CLOSE_DB_IF_NEED
//                        }
//                    }
//                } else { //插入新的单项任务到数据库中
//                    task.status = DownloadTaskStatusOn;
//                    if (![self insertDownloadItemTask:task inDb:db error:error]) {
//                        RETURN_NO_WITH_CLOSE_DB_IF_NEED
//                    }
//                }
//
//                @synchronized (_httpOnDownloadItemTasks) {
//                    task.startTime = [NSDate timeIntervalSinceReferenceDate];
//                    task.updateTime = task.startTime;
//                    task.endTime = 0;
//                    task.errorMessage = @"";
//                    if (![self updateDownloadItemTaskWithStatusInfo:task inDb:db error:error]) {
//                        RETURN_NO_WITH_CLOSE_DB_IF_NEED
//                    }
//                    if (![_httpOnDownloadItemTasks containsObject:task]) {
//                        [_httpOnDownloadItemTasks addObject:task];
//                    }
//                }
//                if (![self startDownloadWithHTTP:task error:error]) {
//                    RETURN_NO_WITH_CLOSE_DB_IF_NEED
//                }
//        } catch {
//            throw BFError(error: error)
//        }
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
