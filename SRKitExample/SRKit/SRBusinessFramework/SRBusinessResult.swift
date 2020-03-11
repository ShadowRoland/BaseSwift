//
//  SRBusinessResult
//  BaseSwift
//
//  Created by Shadow on 2016/12/14.
//  Copyright © 2016年 shadowR. All rights reserved.
//

import Foundation

///处理结果，用以表达事务处理的正确与否
public protocol SRResult {
    var isSuccess: Bool { get } ///处理结果是否成功
    var response: Any? { get } ///处理成功或失败返回的数据或失败信息对象
    var code: Int { get } ///处理结果的整数标识，一般可以由response中得出，这里希望可以提供便捷途径
    var message: String { get } ///处理结果的提示文字，一般可以由response中得出，这里希望可以提供便捷途径
}

public extension SRResult {
    var response: Any? { return nil }
    var code: Int { return 0 }
    var message: String { return "" }
}

public enum BFResult<Value>: SRResult, CustomStringConvertible, CustomDebugStringConvertible {
    case success(Value?)
    case failure(BFError)
    
    /// Returns `true` if the result is a success, `false` otherwise.
    public var isSuccess: Bool {
        switch self {
        case .success:
            return true
        default:
            return false
        }
    }
    
    /// Returns the associated value if the result is a success, `nil` otherwise.
    public var response: Any? {
        switch self {
        case .success(let value):
            return value
        case .failure(let error):
            return error
        }
    }
    
    public var code: Int {
        switch self {
        case .success:
            return 0
        case .failure(let error):
            return error.errorCode
        }
    }
    
    public var message: String {
        switch self {
        case .success:
            return ""
        case .failure(let error):
            return error.errorDescription ?? ""
        }
    }
    
    // MARK: - CustomStringConvertible

    public var description: String {
        switch self {
        case .success:
            return "SUCCESS, code: \(code), message: \(message)"
        case .failure:
            return "FAILURE, code: \(code), message: \(message)"
        }
    }
    
    // MARK: - CustomDebugStringConvertible
    public var debugDescription: String {
        switch self {
        case .success(let value):
            return "SUCCESS: \(String(describing: value))"
        case .failure(let error):
            return "FAILURE: \(error)"
        }
    }
}

// MARK: - BFError

open class BFError: CustomNSError, LocalizedError {
    open class AttributedString {
        public struct Key: RawRepresentable, Hashable {
            public typealias RawValue = String
            public var rawValue: String
            
            public init(_ rawValue: String) {
                self.rawValue = rawValue
            }
            
            public init(rawValue: String) {
                self.rawValue = rawValue
            }
        }
    }
    
    public init(_ description: String,
                code: Int? = nil,
                domain: String? = nil,
                userInfo: [AttributedString.Key : Any]? = nil) {
        _errorUserInfo[.errorDescription] = description
        if let code = code {
            _errorCode = code
        }
        if let domain = domain {
            _errorDomain = domain
        }
        if let userInfo = userInfo {
            _errorUserInfo += userInfo
        }
    }
    
    open var userInfo: [AttributedString.Key : Any]? {
        return _errorUserInfo.isEmpty ? nil : _errorUserInfo
    }
    
    //MARK: - CustomNSError
    
    private var _errorDomain: String = errorDomain
    public static var errorDomain: String { return "BFErrorDomain" }
    
    private var _errorCode: Int = 0
    open var errorCode: Int { return _errorCode }
    
    private var _errorUserInfo = [:] as [AttributedString.Key : Any]
    open var errorUserInfo: [String : Any] {
        var dictionary = [:] as [String : Any]
        _errorUserInfo.forEach {  dictionary[$0.key.rawValue] = $0.value}
        return dictionary
    }
    
    //MARK: - LocalizedError

    open var errorDescription: String? {
        return _errorUserInfo[.errorDescription] as? String
    }
    
    open var failureReason: String? {
        return _errorUserInfo[.failureReason] as? String
    }
    
    open var recoverySuggestion: String? {
        return _errorUserInfo[.recoverySuggestion] as? String
    }
    
    open var helpAnchor: String? {
        return _errorUserInfo[.helpAnchor] as? String
    }
}

public extension BFError.AttributedString.Key {
    static let errorDescription: BFError.AttributedString.Key = BFError.AttributedString.Key(NSLocalizedDescriptionKey)
    static let failureReason: BFError.AttributedString.Key = BFError.AttributedString.Key(NSLocalizedFailureReasonErrorKey)
    static let recoverySuggestion: BFError.AttributedString.Key = BFError.AttributedString.Key(NSLocalizedRecoverySuggestionErrorKey)
    static let helpAnchor: BFError.AttributedString.Key = BFError.AttributedString.Key(NSHelpAnchorErrorKey)
}
