
import UIKit
//: # 基本分类介绍
/*:
 ## 队列执行任务分为
 - 同步: 在当前线程中执行,执行完才执行下一条命令,会阻塞当前线程
 - 异步: 在另一个线程中执行,下一条执行命令不需要等待改线程,不会阻塞当前线程

 ## 队列分类
 - 串行队列: 任务一个接一个执行
 - 并行队列: 多个任务同时执行,只有在异步函数下才有效
 */

//: # 常用代码

//: ## 队列的创建

// 创建串行队列
let serial = DispatchQueue(label: "serialqueue1")
// 创建并行队列
let concurrent = DispatchQueue(label: "concurrentqueue1",
                               qos: .userInitiated,
                               attributes: .concurrent,
                               autoreleaseFrequency: .workItem,
                               target: nil)

/*:
 ## 参数说明
 1. label 队列名称
 2. qos 优先级
 - .background 后台(非常耗时的又不是很重要的操作,执行完在主线程中回调)
 - .utility 低
 - .default 默认
 - .userInitiated 高(不太耗时有很重要的操作)
 - .userInteractive 用户交互(跟主线程一样)
 - .unspecified 不指定
 3. attributes 队列类型
 - .concurrent 并行队列
 - .initiallyInactive 与线程优先级有关
 4. autoreleaseFrequency 自动释放频率
 - .inherit 不确定
 - .workItem GCD为每个任务创建自动释放池,项目完成后清理临时对象
 - .never GCD不管理自动释放池
 */

// 获取系统队列
// 全局队列
let globalQueue = DispatchQueue.global(qos: .default)
// 主线程 (跟UI有关的操作都在主线程中完成)
let mainQueue = DispatchQueue.main


//: ## 队列的操作

// 添加任务到队列中
// 异步
DispatchQueue.global(qos: .default).async {
    print("耗时操作")
    DispatchQueue.main.async {
        print("耗时操作完成后,回调主线程,UI在这里刷新")
    }
}
// 同步
DispatchQueue.global(qos: .default).sync {
    print("全局队列中执行同步操作")
}

DispatchQueue.main.sync {
    print("主线程中执行同步操作, 会引起死锁 程序报错")
}

// 暂停/继续队列
let concurrentQueue = DispatchQueue(label: "concurrentQueue2",
                                    qos: .userInitiated,
                                    attributes: .concurrent,
                                    autoreleaseFrequency: .workItem,
                                    target: nil)
concurrentQueue.async {
    (1...10000).forEach({ (idx) in
        print(idx)
    })
}
// 暂停
concurrentQueue.suspend()
// 继续
concurrentQueue.resume();

// 延时操作
DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2.0) {
    print("延时2s执行")
}

// 只执行一次 (可用于创建单利)
private var once1: Void = {
    print("once1")
}()

private var once2: String = {
    print("once2")
    return "once2"
}()

once1;once1;once1;once1
once2;once2;once2;once2

// Group用法
// 获取全局队列
let queue = DispatchQueue.global()
// 创建group
let group = DispatchGroup()
// 并发
queue.async(group: group, qos: .default, flags: .barrier) {
    sleep(2)
    print("第1个")
}
queue.async(group: group, qos: .default, flags: .barrier) {
    sleep(2)
    print("第2个")
}
queue.async(group: group, qos: .default, flags: .barrier) {
    sleep(2)
    print("第3个")
}
// 获取到线程组全部执行完毕通知 (不会阻塞主线程)
group.notify(queue: DispatchQueue.main) {
    print("所有任务完成后,在主队列中回调,更新UI操作")
}
// 如果有多个并发队列在一个组里,我们想在这些操作执行完再继续,可调用wait
group.wait()

// 指定多次Block到队列中
let queue2 = DispatchQueue.global(qos: .default)
queue2.async {
    DispatchQueue.concurrentPerform(iterations: 3, execute: { (idx) in
        print(idx)
    })
    DispatchQueue.main.async {
        print("执行完毕,在主线程中刷新")
    }
}

// 信号量
let queue3 = DispatchQueue.global()
let semaphore = DispatchSemaphore(value: 1)
(1...1000).forEach { (idx) in
    queue3.async {
        semaphore.wait()
        print(idx)
        semaphore.signal()
    }
}



class GCDDemo {
    
    func loadData() {
        // 开发常见需求
        // 当两个异步的网络请求都执行完后,刷新页面
        let group2 = DispatchGroup()
        group2.enter()
        networkTask(url: "http://www.xxx.xxx") {
            group2.leave()
        }
        
        group2.enter()
        networkTask(url: "http://www.ooo.xxx") {
            group2.leave()
        }
        group2.notify(queue: DispatchQueue.main) {
            print("两个异步线程执行完后,在主线程中刷新页面")
        }
    }
    
    
    // 模拟网络请求
    public func networkTask(url: String, complete: @escaping () -> ()) {
        print("请求链接: \(url)")
        DispatchQueue.global(qos: .default).async {
            sleep(arc4random()%3)
            DispatchQueue.main.async {
                complete()
            }
        }
    }
}


