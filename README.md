# YQChainTask
Swift链式调用

### 写代码的时候经常遇到以下的情况
- N个If嵌套
- N个异步任务的闭包嵌套，比如先上传图片，然后再把图片URL给服务器等 

### 导致的后果就是：
![image](https://github.com/976431yang/YQChainTask/blob/master/BadCode.png) 

#### 我们知道解决这种问题，可以使用著名的“PromiseKit”等库
- 这些库虽然厉害，但是不可否认的是对于小型需求来说有点过重了

#### 于是，我这里提供了一个50行不到实现的链式任务“YQChainTask”，如果你的需求简单，又想从回调地狱解脱出来，可以尝试一下。

### YQChainTask
#### 能够做什么？
```Swift
    // 简单顺序执行
    YQChainTask { (_) in
        print("AAAA")
    }.next { (_) in
        print("BBB")
    }.next { (_) in
        print("CCC")
    }.begin()
    
    // 手动控制执行时机
    YQChainTask { (task) in
        print("AAAA")
        task.nextStep()
    }.next { (task) in
        print("BBB")
        task.nextStep()
    }.next { (task) in
        print("CCC")
    }.beginByStep()
```

### 用途示例

#### 解决N个If嵌套
- 假如你的源代码是这样

```Swift
    if true {
        if true {
            if true {
                // do something
            }
        }
    }
```

- 那么用YQChainTask可以改造成这样

```Swift
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
           // do something
       }
    }.beginByStep()
```

#### 解决回调地狱
- 假设有一张图片需要上传，上传完了以后需要再调一下服务器的某个接口，再之后再做一个异步任务

- 这里先做两个假的异步任务

```Swift 
    // 模拟上传图片
    func uploadImage(_ image: UIImage, resultHandle: ((Bool,String?) -> Void)?) {
       print("开始模拟上传图片")
       Timer.scheduledTimer(withTimeInterval: 3, repeats: false) { (_) in
           print("上传完成")
           resultHandle?(true,"模拟图片地址")
       }
    }
        
    // 模拟异步任务，例如请求接口、后台处理等
    func doAnAsynchronousTaskNow(resultHandle: (() -> Void)?) {
       print("开始异步任务")
       Timer.scheduledTimer(withTimeInterval: 3, repeats: false) { (_) in
           print("异步任务完成")
           resultHandle?()
       }
    }
```

- 用传统写法来串逻辑会怎样？

```Swift
    //上传图片
    self.uploadImage(UIImage(), resultHandle: { (success, imgurl) in
        if success == true, imgurl != nil {
            //图片上传成功了
            // 执行一个异步任务，比如调一下服务器的接口
            print("把图片的URL告诉服务器：\(imgurl!)")
            self.doAnAsynchronousTaskNow(resultHandle: {
                // 检查一下结果
                if true {
                    //OK了，再进行下一个任务
                    // 再执行一个异步任务
                    print("第三个任务")
                    self.doAnAsynchronousTaskNow(resultHandle: {
                        if true {
                            //OK了
                        }
                    })
                }
           })
        } else {
            //提示用户出错了
        }
    }
```

- 用YQChainTask可以改造成这样

```Swift
    var outSideImgURL = ""
       
    YQChainTask { (task) in
        //上传图片
        self.uploadImage(UIImage()) { (success, imgurl) in
            if success == true, imgurl != nil {
                //图片上传成功了
                outSideImgURL = imgurl!
                //执行下一步
                task.nextStep()
            } else {
                //提示用户出错了
            }
        })
    }.next { (task) in
        // 执行一个异步任务，比如调一下服务器的接口
        print("把图片的URL告诉服务器：\(outSideImgURL)")
        self.doAnAsynchronousTaskNow() {
            if true {
                //OK了，再进行下一个任务
                task.nextStep()
            }
        }
    }.next { (task) in
        // 再执行一个异步任务
        print("第三个任务")
        self.doAnAsynchronousTaskNow() {
            if true {
                //OK了
            }
        }
    }.beginByStep()
```

#### 异步任务

- 每步都在后台线程执行

```Swift 
    YQChainTask { _ in
        print("in task1 \(Date())")
        sleep(3)
        print("end task1 \(Date())")
    }.next({ _ in
        print("in task2 \(Date())")
        sleep(3)
        print("end task2 \(Date())")
    }).beginByAsync()
    
    print("task submited")


    /*
     task submited
     
     in task1 2024-10-26 10:36:36 +0000
     end task1 2024-10-26 10:36:39 +0000
     
     in task2 2024-10-26 10:36:39 +0000
     end task2 2024-10-26 10:36:42 +0000
     */
```

- 混合主线程和后台线程

```Swift 
    YQChainTask { _ in
        print("in sync task1 \(Date()) \(Thread.current)")
        sleep(3)
        print("end sync task1 \(Date()) \(Thread.current)")
    }.nextInBackGround({ _ in
        print("in async task2 \(Date()) \(Thread.current)")
        sleep(3)
        print("end async task2 \(Date()) \(Thread.current)")
    }).next({ _ in
        print("in sync task3 \(Date()) \(Thread.current)")
        sleep(3)
        print("end sync task3 \(Date()) \(Thread.current)")
    }).begin()
    
    print("task submited")

    /*
     in sync task1 2024-10-26 10:42:46 +0000 <_NSMainThread: 0x60000170c000>{number = 1, name = main}
     end sync task1 2024-10-26 10:42:49 +0000 <_NSMainThread: 0x60000170c000>{number = 1, name = main}
     
     task submited
     
     in async task2 2024-10-26 10:42:49 +0000 <NSThread: 0x6000017b10c0>{number = 8, name = (null)}
     end async task2 2024-10-26 10:42:52 +0000 <NSThread: 0x6000017b10c0>{number = 8, name = (null)}
     
     in sync task3 2024-10-26 10:42:52 +0000 <_NSMainThread: 0x60000170c000>{number = 1, name = main}
     end sync task3 2024-10-26 10:42:55 +0000 <_NSMainThread: 0x60000170c000>{number = 1, name = main}
     */
```


#### YQChainTask的实现只有50行不到，有兴趣的可以看看源码

