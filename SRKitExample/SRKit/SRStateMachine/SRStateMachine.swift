//
//  SRStateMachine.swift
//  BaseSwift
//
//  Created by Gary on 2017/5/25.
//  Copyright © 2017年 shadowR. All rights reserved.
//

import UIKit
import TransitionKit

public protocol SRStateMachineDelegate: class {
    func stateMachine(_ stateMachine: SRStateMachine, didFire event: SRKit.Event)
    func stateMachine(_ stateMachine: SRStateMachine, didEnd event: SRKit.Event)
}

extension SRStateMachineDelegate {
    public func stateMachine(_ stateMachine: SRStateMachine, didFire event: SRKit.Event) { }
    public func stateMachine(_ stateMachine: SRStateMachine, didEnd event: SRKit.Event) { }
}

/*
 * 控制事务流程的状态机类
 * 防止同一
 级别的事务并发产生，使之按顺序处理
 * 业务场景举例：已弹出教程页并且没点击消失的时候来了推送通知，需要弹出新的提示框
 * 并发的做法是教程页不消失马上弹出提示框，顺序处理的方式是等待用户点击后使教程页消失后再弹出提示框
 * SRStateMachine作为简单的状态机，定义弹出教程页时为“忙碌”状态，此时不接受新的事务处理
 * 定义教程页消失时为“空闲”状态，此时会去检查是否有新的任务，然后去处理
 */
public class SRStateMachine {
    public weak var delegate: SRStateMachineDelegate?
    public var currentEvent: SRKit.Event? { return _currentEvent }
    
    private(set) var stateMachine = TKStateMachine() //状态机
    private(set) var events: [SRKit.Event] = [] //所有的状态机互斥事件
    private(set) var _currentEvent: SRKit.Event? //当前事件
    
    private var idleState: TKState! //空闲状态
    private var busyState: TKState! //忙碌状态
    private var resetEvent: TKEvent! //重置事件
    private var watingEvent: TKEvent! //等待事件
    private var currentEndEvent: TKEvent! //当前事件已经结束事件
    
    public init() {
        idleState = TKState(name: "idle")
        busyState = TKState(name: "busy")
        resetEvent = TKEvent(name: "reset", transitioningFromStates: nil, to: idleState)
        watingEvent = TKEvent(name: "wating", transitioningFromStates: [idleState as Any], to: busyState)
        currentEndEvent =
            TKEvent(name: "currentEnd", transitioningFromStates: [busyState as Any], to: idleState)
        
        idleState.setDidEnter { [weak self] (state, transition) in
            guard let strongSelf = self, !strongSelf.events.isEmpty else { return }
            try! strongSelf.stateMachine.fireEvent(strongSelf.watingEvent, userInfo: nil)
        }
        
        busyState.setDidEnter { [weak self] (state, transition) in
            guard let strongSelf = self else { return }
            
            strongSelf._currentEvent = nil
            if let event = strongSelf.events.first {
                strongSelf._currentEvent = event
                strongSelf.events.remove(at: 0)
            }
            
            if let currentEvent = strongSelf._currentEvent {
                strongSelf.delegate?.stateMachine(strongSelf, didFire: currentEvent)
            } else {
                try! strongSelf.stateMachine.fireEvent(strongSelf.currentEndEvent, userInfo: nil)
            }
        }
        
        currentEndEvent.setDidFire { [weak self] (event, transition) in
            guard let strongSelf = self, let currentEvent = strongSelf._currentEvent else { return }
            strongSelf.delegate?.stateMachine(strongSelf, didEnd: currentEvent)
        }
        
        stateMachine.addState(idleState)
        stateMachine.addState(busyState)
        stateMachine.addEvent(watingEvent)
        stateMachine.addEvent(currentEndEvent)
        stateMachine.initialState = idleState
        try! stateMachine.fireEvent(resetEvent, userInfo: nil)
    }
    
    public func contains(_ event: SRKit.Event) -> Bool {
        return events.first { $0.option == event.option } != nil
    }

    public func append(_ event: SRKit.Event) {
        objc_sync_enter(events)
        if !contains(event) { //相同事件不用添加
            events.append(event)
        }
        objc_sync_exit(events)
        if stateMachine.currentState == idleState {
            try! stateMachine.fireEvent(watingEvent, userInfo: nil)
        }
    }
    
    public func append(contentsOf newElements: [SRKit.Event]) {
        objc_sync_enter(events)
        newElements.forEach {
            if !contains($0) {
                events.append($0)
            }
        }
        objc_sync_exit(events)
        if stateMachine.currentState == idleState {
            try! stateMachine.fireEvent(watingEvent, userInfo: nil)
        }
    }
    
    public func remove(_ event: SRKit.Event) {
        objc_sync_enter(events)
        if let index = events.firstIndex(where: { $0.option == event.option }) {
            events.remove(at: index)
        }
        objc_sync_exit(events)
    }
    
    public func endCurrentEvent() {
        try! stateMachine.fireEvent(currentEndEvent, userInfo: nil)
    }
    
    public func end(_ event: SRKit.Event) {
        if event == _currentEvent {
            endCurrentEvent()
        } else {
            remove(event)
        }
    }
    
    public func clearEvents() {
        events.removeAll()
        endCurrentEvent()
    }
}
