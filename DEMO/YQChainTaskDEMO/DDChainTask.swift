//
//  YQChainTask.swift
//  DaDaClass
//
//  Created by FreakyYang on 2018/4/25.
//  Copyright © 2018年 FreakyYang. All rights reserved.
//
// 链式调用任务

import Foundation

/*    使用参考 - 简单顺序执行
 YQChainTask { (_) in
    print("AAAA")
 }.next { (_) in
    print("BBB")
 }.next { (_) in
    print("CCC")
 }.begin()
 */

 /*    使用参考 - 手动控制执行时机
 YQChainTask { (task) in
    print("AAAA")
    task.nextStep()
 }.next { (task) in
    print("BBB")
    task.nextStep()
 }.next { (task) in
    print("CCC")
 }.beginByStep()
 */

public class YQChainTask {
    
    private var nextTask: YQChainTask?
    private var _action: ((YQChainTask) -> Void)?
    
    //如果只初始化一个任务，可以忽略task
    public init(action:@escaping ((YQChainTask) -> Void)) {
        self._action = action
        self.nextTask = nil
    }
    
    /// 返回值是 根任务
    /// 根任务如果是用beginByStep()执行，那么可以使用block里的task.nextStep()来手动触发下一步操作
    @discardableResult
    public func next(_ nextAction: @escaping (YQChainTask) -> Void ) -> YQChainTask {
        let newTask = YQChainTask(action: nextAction)
        
        if nextTask != nil {
            var endTask = nextTask
            while endTask?.nextTask != nil {
                endTask = endTask?.nextTask
            }
            endTask?.nextTask = newTask
        } else {
            nextTask = newTask
        }
        
        return self
    }
    
    //顺序执行每一步
    public func begin() {
        _action?(self)
        nextTask?.begin()
    }
    
    /// 配合nextStep()一步一步的调用
    public func beginByStep() {
        _action?(self)
    }
    
    //执行下一步
    public func nextStep() {
        nextTask?.beginByStep()
    }
    
}
