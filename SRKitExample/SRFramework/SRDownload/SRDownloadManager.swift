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
    ///本地下载文件存储文件夹
    private var _directory: String = ""
    open var directory: String {
        get {
            if !_directory.isEmpty {
                return C.documentsDirectory.appending(pathComponent: _directory)
            } else {
                return ""
            }
        }
        set {
            if (_directory != newValue) {
                _directory = newValue
            }
        }
    }
    
    open var completionQueue: DispatchQueue?
    private var _operationQueue = OperationQueue()
    public var operationQueue: OperationQueue {
        get {
            return _operationQueue
        }
        set {
            _operationQueue.cancelAllOperations()
            _operationQueue = newValue
        }
    }
    private var _httpCompletionQueue = DispatchQueue(label: "com.srdownload.manager")
    public var httpCompletionQueue: DispatchQueue {
        get {
            return _httpCompletionQueue
        }
        set {
            _httpCompletionQueue = newValue
        }
    }
    private var _timeoutInterval: TimeInterval = 60
    open var timeoutInterval: TimeInterval {
        get {
            return _timeoutInterval
        }
        set {
            if _timeoutInterval != newValue {
                let configuration = httpSession.sessionConfiguration
                configuration.timeoutIntervalForRequest = newValue
                httpSession = Alamofire.Session(configuration: configuration, delegate: sessionDelegate)
                httpSession.delegate = nil
            }
            _timeoutInterval = newValue
        }
    }
    open var maxConcurrentCount = 0 {
        didSet {
            
        }
    }
    open var allowedNetworkReachabilityStatus: NetworkReachabilityManager.NetworkReachabilityStatus = .reachable(.cellular)
    
    private var  _httpSession = Alamofire.Session()
    public var httpSession: Alamofire.Session {
        get {
            return _httpSession
        }
        set {
            _httpSession.cancelAllRequests()
            _httpSession = newValue
        }
    }
    
    ///正在处理中的组任务
    open var didOnGroupTasks = [] as [SRDownloadGroupTaskModel]
    ///正在处理中的单项任务
    open var didOnItemTasks = [] as [SRDownloadItemTaskModel]
    
    ///正在网络处理中的组任务
    private var _httpDidOnDownloadGroupTasks = [] as [SRDownloadGroupTaskModel]
    public var httpDidOnDownloadGroupTasks: [SRDownloadGroupTaskModel] {
        return _httpDidOnDownloadGroupTasks
    }
    
    ///正在网络处理中的单项任务
    private var _httpDidOnDownloadItemTasks = [] as [SRDownloadItemTaskModel]
    public var httpDidOnDownloadItemTasks: [SRDownloadItemTaskModel] {
        return _httpDidOnDownloadItemTasks
    }

//    @property (nonatomic, strong, readonly) NSString *directory; //本地存储文件夹
//    @property (nonatomic, strong, nullable) dispatch_queue_t completionQueue;
//    @property (nonatomic, assign) NSInteger timeoutInterval;
//    @property (nonatomic, assign) NSInteger maxConcurrentCount; //最大同时处理的任务数量
//    @property (nonatomic, weak) id<DownloadManagerDelegate> delegate;
//    @property (nonatomic, assign) AFNetworkReachabilityStatus allowedNetworkReachabilityStatus; //允许下载的网络状态
//
//    + (DownloadManager *)shared;
//    - (NSArray<DownloadTask*> *)currentTasks;
//    - (void)createDownloadGroupTask:(DownloadGroupTask *)task completion:(void (^)(NSError *error))completion;
//    - (void)resumeDownloadGroupTask:(DownloadGroupTask *)task completion:(void (^)(NSError *error))completion;
//    - (void)cancelDownloadGroupTask:(DownloadGroupTask *)task completion:(void (^)(NSError *error))completion;
//    - (void)suspendDownloadGroupTask:(DownloadGroupTask *)task completion:(void (^)(NSError *error))completion;
//    - (void)resumeAllDownloadTasks:(void (^)(NSError *error))completion;
//    - (void)cancelAllDownloadTasks:(void (^)(NSError *error))completion;
//    - (void)suspendAllDownloadTasks:(void (^)(NSError *error))completion;
//
//    - (void)updateDownloadTask:(DownloadTask *)task set:(NSString *)sql completion:(void (^)(NSError *error))completion;
//    - (void)deleteDownloadTask:(DownloadTask *)task completion:(void (^)(NSError *error))completion;
//
//    - (void)selectDownloadItemTasksWithSQL:(NSString *)sql
//                                completion:(void (^)(NSArray *tasks, NSError *error))completion;
//    @end
//
//    @protocol DownloadManagerDelegate <NSObject>
//    - (void)downloadManager:(DownloadManager *)manager groupTaskStatusChanged:(DownloadGroupTask *)groupTask;
//    - (void)downloadManager:(DownloadManager *)manager groupTaskProgressChanged:(DownloadGroupTask *)groupTask;
//    @end
}

public protocol SRDownloadManagerDelegate: NSObjectProtocol {
    func downloadManager(_ manager: SRDownloadManager, groupTaskStatusChanged groupTask: SRDownloadGroupTaskModel)
    func downloadManager(_ manager: SRDownloadManager, groupTaskProgressChanged groupTask: SRDownloadGroupTaskModel)
    func downloadManager(_ manager: SRDownloadManager, itemTaskStatusChanged itemTask: SRDownloadItemTaskModel)
    func downloadManager(_ manager: SRDownloadManager, itemTaskProgressChanged itemTask: SRDownloadItemTaskModel)
}
