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
    func stateMachine(_ stateMachine: SRStateMachine, didFire event: Int)
    func stateMachine(_ stateMachine: SRStateMachine, didEnd event: Int)
}

/*
 * 控制事务流程的状态机类
 * 防止同一级别的事务并发产生，使之按顺序处理
 * 业务场景举例：已弹出教程页并且没点击消失的时候来了推送通知，需要弹出新的提示框
 * 并发的做法是教程页不消失马上弹出提示框，顺序处理的方式是等待用户点击后使教程页消失后再弹出提示框
 * SRStateMachine作为简单的状态机，定义弹出教程页时为“忙碌”状态，此时不接受新的事务处理
 * 定义教程页消失时为“空闲”状态，此时会去检查是否有新的任务，然后去处理
 */
public class SRStateMachine: NSObject {
    public weak var delegate: SRStateMachineDelegate?
    
    private(set) var stateMachine = TKStateMachine() //状态机
    private(set) var events: [Int] = [] //所有的状态机互斥事件
    private(set) var currentEvent: Int? //当前事件
    
    private var idleState: TKState! //空闲状态
    private var busyState: TKState! //忙碌状态
    private var resetEvent: TKEvent! //重置事件
    private var watingEvent: TKEvent! //等待事件
    private var currentEndEvent: TKEvent! //当前事件已经结束事件
    
    override init() {
        super.init()
        
        idleState = TKState(name: "idle")
        busyState = TKState(name: "busy")
        resetEvent = TKEvent(name: "reset", transitioningFromStates: nil, to: idleState)
        watingEvent = TKEvent(name: "wating", transitioningFromStates: [idleState], to: busyState)
        currentEndEvent =
            TKEvent(name: "currentEnd", transitioningFromStates: [busyState], to: idleState)
        
        idleState.setDidEnter { [weak self] (state, transition) in
            guard let strongSelf = self, strongSelf.events.count > 0 else { return }
            try! strongSelf.stateMachine.fireEvent(strongSelf.watingEvent, userInfo: nil)
        }
        
        busyState.setDidEnter { [weak self] (state, transition) in
            guard let strongSelf = self else { return }
            
            strongSelf.currentEvent = nil
            if let event = strongSelf.events.first {
                strongSelf.currentEvent = event
                strongSelf.events.remove(at: 0)
            }
            
            if let currentEvent = strongSelf.currentEvent {
                strongSelf.delegate?.stateMachine(strongSelf, didFire: currentEvent)
            } else {
                try! strongSelf.stateMachine.fireEvent(strongSelf.currentEndEvent, userInfo: nil)
            }
        }
        
        currentEndEvent.setDidFire { [weak self] (event, transition) in
            guard let strongSelf = self, let currentEvent = strongSelf.currentEvent else { return }
            strongSelf.delegate?.stateMachine(strongSelf, didEnd: currentEvent)
        }
        
        stateMachine.addState(idleState)
        stateMachine.addState(busyState)
        stateMachine.addEvent(watingEvent)
        stateMachine.addEvent(currentEndEvent)
        stateMachine.initialState = idleState
        try! stateMachine.fireEvent(resetEvent, userInfo: nil)
    }

    func append(_ event: Int) {
        objc_sync_enter(events)
        if !events.contains(event) { //相同事件不用添加
            events.append(event)
        }
        objc_sync_exit(events)
        if stateMachine.currentState == idleState {
            try! stateMachine.fireEvent(watingEvent, userInfo: nil)
        }
    }
    
    func remove(_ event: Int) {
        objc_sync_enter(events)
        if let index = events.index(of: event) {
            events.remove(at: index)
        }
        objc_sync_exit(events)
    }
    
    func endCurrentEvent() {
        try! stateMachine.fireEvent(currentEndEvent, userInfo: nil)
    }
    
    func end(_ event: Int) {
        if event == currentEvent {
            endCurrentEvent()
        } else {
            remove(event)
        }
    }
    
    func clearEvents() {
        events.removeAll()
        endCurrentEvent()
    }
}
