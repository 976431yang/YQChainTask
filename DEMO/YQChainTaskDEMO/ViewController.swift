//
//  ViewController.swift
//  YQChainTaskDEMO
//
//  Created by FreakyYang on 2018/6/14.
//  Copyright © 2018年 FreakyYang. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        stepDEMOTask()
        //simpleDEMO()
    }
    
    
    // 手动控制链式执行的DEMO
    func stepDEMOTask() {
        
        //简单的情况
        YQChainTask { (task) in
            print("AAAA")
            task.nextStep()
        }.next { (task) in
            print("BBB")
            task.nextStep()
        }.next { (task) in
            print("CCC")
        }.beginByStep()
        
        // 实用的，加入有N个If要嵌套
        YQChainTask { (task) in
            if true {
                task.nextStep()
            }
        }.next { (task) in
            if true {
                task.nextStep()
            }
        }.next { (task) in
            if true {
                task.nextStep()
            }
        }.beginByStep()
        
        // 复杂的
        // 假设有一张图片需要上传，上传完了以后需要再调一下服务器的某个接口，再之后再做一个异步任务
        let img = UIImage()
        
        var outSideImgURL = ""
        
        YQChainTask { (task) in
            //上传图片
            self.uploadImage(img) { (success, imgurl) in
                if success == true, imgurl != nil {
                    //图片上传成功了
                    outSideImgURL = imgurl!
                    //执行下一步
                    task.nextStep()
                } else {
                    //提示用户出错了
                }
            }
        }.next { (task) in
            // 执行一个异步任务，比如调一下服务器的接口
            print("把图片的URL告诉服务器：\(outSideImgURL)")
            self.asynchronousTask(resultHandle: {
                //OK了，再进行下一个任务
                task.nextStep()
            })
        }.next { (task) in
            // 再执行一个异步任务
            print("第三个任务")
            self.asynchronousTask(resultHandle: {
                //OK了
            })
        }.beginByStep()
    }
    
    // 简单顺序执行的DEMO
    func simpleDEMO() {
        
        YQChainTask { (_) in
            print("AAAA")
        }.next { (_) in
            print("BBB")
        }.next { (_) in
            print("CCC")
        }.begin()
        
        // 当然，上面的看上去没什么实际用处，下面举例一下
        
        // 假设有一个小明
        let XiaoMing = person()
        
        // 新建一个链式处理任务
        let dealTask = YQChainTask { (_) in
            print("开始处理小明")
        }
        // 根据情况为这个任务添加一些后续任务，但不会马上执行
        if XiaoMing.sex == .man {
            dealTask.next { (_) in
                print("把他加入男性处理队列……")
            }
        }
        if XiaoMing.age > 60 {
            dealTask.next { (_) in
                print("把他加入需要办理老年证的队列……")
            }
        }
        
        // 最后,你就可以在任何想要处理的时候(一般不会在这里)，再来处理这个任务了
        dealTask.begin()
        
    }
    
    
    
    // MARK: 辅助内容
    
    // 模拟上传图片
    func uploadImage(_ image: UIImage, resultHandle: ((Bool,String?) -> Void)?) {
        print("开始模拟上传图片")
        Timer.scheduledTimer(withTimeInterval: 3, repeats: false) { (_) in
            print("上传完成")
            resultHandle?(true,"模拟图片地址")
        }
    }
    
    // 模拟异步任务，例如请求接口、后台处理等
    func asynchronousTask(resultHandle: (() -> Void)?) {
        print("开始异步任务")
        Timer.scheduledTimer(withTimeInterval: 3, repeats: false) { (_) in
            print("异步任务完成")
            resultHandle?()
        }
    }
    

}


enum personSex {
    case man,woman
}

class person {
    var name = ""
    var age = 0
    var sex: personSex = .man
}

