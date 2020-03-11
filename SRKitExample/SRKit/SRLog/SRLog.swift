//
//  SRLog.swift
//  SRKitExample
//
//  Created by Gary on 2019/4/18.
//  Copyright © 2019 Sharow Roland. All rights reserved.
//

import UIKit
import CocoaLumberjack

public func LogDebug(_ message: @autoclosure () -> String) {
    SRLog.shared.debug(message())
}

public func LogInfo(_ message: @autoclosure () -> String) {
    SRLog.shared.info(message())
}

public func LogWarn(_ message: @autoclosure () -> String) {
    SRLog.shared.warn(message())
}

public func LogError(_ message: @autoclosure () -> String) {
    SRLog.shared.error(message())
}

public class SRLog {
    public class var shared: SRLog {
        if sharedInstance == nil {
            sharedInstance = SRLog()
        }
        return sharedInstance!
    }
    
    private static var sharedInstance: SRLog?
    
    private init() {
        initLogger()
    }
    
    public var level: DDLogLevel = .info {
        didSet {
            initLogger()
        }
    }
    
    private var _directory: String = ""
    public var directory: String {
        get {
            if !_directory.isEmpty {
                return C.documentsDirectory.appending(pathComponent: _directory)
            } else {
                return logger.logFileManager.logsDirectory
            }
        }
        set {
            if (_directory != newValue) {
                _directory = newValue
                initLogger()
            }
        }
    }
    
    struct Const {
        static let defaultRollingFrequency: TimeInterval = 60 * 60 * 24 // 24 hour rolling
        static let defaultMaxNumber: UInt = 10
        static let defaultFilesDiskQuota: UInt64 = 10 * 1024 * 1024
    }
    
    public var rollingFrequency: TimeInterval = Const.defaultRollingFrequency {
        didSet {
            initLogger()
        }
    }
    public var maxNumber: UInt = Const.defaultMaxNumber {
        didSet {
            initLogger()
        }
    }
    public var filesDiskQuota: UInt64 = Const.defaultFilesDiskQuota {
        didSet {
            initLogger()
        }
    }
    
    private var _logger: DDFileLogger!
    private lazy var logger: DDFileLogger = {
        if _logger == nil {
            initLogger()
        }
        return _logger
    }()
    
    func initLogger() {
        if _logger != nil {
            DDLog.remove(_logger)
        } else {
            //DDLog.add(DDASLLogger.sharedInstance)
        }
        
        if !_directory.isEmpty {
            _logger = DDFileLogger(logFileManager: DDLogFileManagerDefault(logsDirectory: _directory))
        } else {
            _logger = DDFileLogger()
        }
        
        CocoaLumberjack.dynamicLogLevel = level
        _logger.rollingFrequency = rollingFrequency > 0 ? rollingFrequency : Const.defaultRollingFrequency
        _logger.logFileManager.maximumNumberOfLogFiles = maxNumber > 0 ? maxNumber : Const.defaultMaxNumber
        _logger.logFileManager.logFilesDiskQuota = filesDiskQuota > 0 ? filesDiskQuota : Const.defaultFilesDiskQuota
        DDLog.add(_logger)
    }
    
    fileprivate func debug(_ message: @autoclosure () -> String) {
        print(message())
        DDLogDebug(message())
    }
    
    fileprivate func info(_ message: @autoclosure () -> String) {
        print(message())
        DDLogInfo(message())
    }
    
    fileprivate func warn(_ message: @autoclosure () -> String) {
        print(message())
        DDLogWarn(message())
    }
    
    fileprivate func error(_ message: @autoclosure () -> String) {
        print(message())
        DDLogError(message())
    }
}
