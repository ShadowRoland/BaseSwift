//
//  SRBusinessResult
//  BaseSwift
//
//  Created by Shadow on 2016/12/14.
//  Copyright © 2016年 shadowR. All rights reserved.
//

import Foundation

public enum BFResult<Value> {
    case success(Value?)
    case bfailure(Value?)
    case failure(Error)
    
    /// Returns `true` if the result is a success, `false` otherwise.
    public var isSuccess: Bool {
        switch self {
        case .success:
            return true
        default:
            return false
        }
    }
    
    public var isBFailure: Bool {
        switch self {
        case .bfailure:
            return true
        default:
            return false
        }
    }
    
    /// Returns `true` if the result is a failure, `false` otherwise.
    public var isFailure: Bool {
        switch self {
        case .failure:
            return true
        default:
            return false
        }
    }
    
    /// Returns the associated value if the result is a success, `nil` otherwise.
    public var value: Value? {
        switch self {
        case .success(let value):
             return value
        case .bfailure(let value):
            return value
        case .failure:
            return nil
        }
    }
    
    /// Returns the associated error value if the result is a failure, `nil` otherwise.
    public var error: Error? {
        switch self {
        case .failure(let error):
            return error
        default:
            return nil
        }
    }
}

// MARK: - CustomStringConvertible

extension BFResult: CustomStringConvertible {
    /// The textual representation used when written to an output stream, which includes whether the result was a
    /// success or failure.
    public var description: String {
        switch self {
        case .success:
            return "SUCCESS"
        case .bfailure, .failure:
            return "FAILURE"
        }
    }
}

// MARK: - CustomDebugStringConvertible

extension BFResult: CustomDebugStringConvertible {
    /// The debug textual representation used when written to an output stream, which includes whether the result was a
    /// success or failure in addition to the value or error.
    public var debugDescription: String {
        switch self {
        case .success(let value):
            return "SUCCESS: \(String(describing: value))"
        case .bfailure(let value):
            return "FAILURE: \(String(describing: value))"
        case .failure(let error):
            return "FAILURE: \(error)"
        }
    }
}

// MARK: - BFError

public enum BFError: Error {
    case callModule(CallModuleFailureReason)
    case http(LoadDataFailureReason)
}


// MARK: - Error Descriptions

extension BFError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .callModule(let reason):
            return reason.localizedDescription
        case .http(let reason):
            return reason.localizedDescription
        }
    }
}

extension BFError {
    public enum CallModuleFailureReason {
        case moduleNotExist(UInt)
        case capabilityNotExist(UInt)
    }
    
    public enum LoadDataFailureReason {
        case afResponse(Error)
        case responseSerialization(Error?)
        case other(String?)
    }
}

extension BFError.CallModuleFailureReason {
    public var localizedDescription: String {
        switch self {
        case .moduleNotExist(let moduleId):
            return String(format: "[SR]Business module (moduleId: %d)  does not exist".srLocalized,
                          moduleId)
            
        case .capabilityNotExist(let funId):
            return String(format: "[SR]Business capability (funId: %d)  does not exist".srLocalized,
                          funId)
        }
    }
}

extension BFError.LoadDataFailureReason {
    public var localizedDescription: String {
        switch self {
        case .afResponse(let error):
            return error.localizedDescription
            
        case .responseSerialization(let error):
            return error == nil
                ? "[SR]Response serialization failed".srLocalized
                : "[SR]Response serialization failed".srLocalized + error!.localizedDescription
            
        case .other(let error):
            return error == nil ? "" : error!.srLocalized
        }
    }
}
