# YQChainTask
Swift链式调用，50行不到代码实现 的 链式任务调用

### 写代码的时候经常遇到以下的情况
- N个If嵌套
- N个异步任务的闭包嵌套，比如先上传图片，然后再把图片URL给服务器等 

##### 导致的后果就是：
![image](https://github.com/976431yang/YQChainTask/blob/master/BadCode.png) 

##### 我们知道解决这种问题，可以使用著名的“PromiseKit”等库
- 这些库虽然厉害，但是不可否认的是对于小型需求来说有点过重了

##### 于是，我这里提供了一个50行不到实现的链式任务“YQChainTask”，如果你的需求简单，又想从回调地狱解脱出来，可以尝试一下。

#### YQChainTask
##### 能够做什么？
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

- 如果用传统写法来串逻辑会怎样？

```Swift
//上传图片
self.uploadImage(UIImage()) { (success, imgurl) in
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

- 那么用YQChainTask可以改造成这样

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
    self.doAnAsynchronousTaskNow(resultHandle: {
        if true {
            //OK了，再进行下一个任务
            task.nextStep()
        }
    })
}.next { (task) in
    // 再执行一个异步任务
    print("第三个任务")
    self.doAnAsynchronousTaskNow(resultHandle: {
        if true {
            //OK了
        }
    })
}.beginByStep()
```

