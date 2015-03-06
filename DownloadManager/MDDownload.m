/**
 *  MDDownload.m
 *
 *  该文件可以执行下载操作，用 NSURLConnection 的代理方法，解决了直接用 NSURLConnection 的异步方法的
 *  内存峰值问题。
 *
 *  Created by xuehan.
 *  Copyright (c)  xuehan. All rights reserved.
 */

#import "MDDownload.h"
#define kTimeOut 20.0f

@interface MDDownload ()<NSURLConnectionDataDelegate>
/** 文件总大小 */
@property (nonatomic,assign) long long expectedContentLength;
/** 文件保存在本地的路径 */
@property (nonatomic,copy) NSString *filePath;
/** 当前本地文件大小 */
@property (nonatomic,assign) long long currentFileLength;
/** 记录下载路径URL */
@property (nonatomic,strong) NSURL *downLoadURL;
/** 文件输出流 */
@property (nonatomic,strong) NSOutputStream *fileStream;
/** 当前下载的运行循环 */
@property (nonatomic,assign) CFRunLoopRef currentRunLoop;
/** 下载连接 */
@property (nonatomic,strong) NSURLConnection *downloadConnection;
//---------定义block----------
@property (nonatomic,copy) void(^progressBlock)(float);
@property (nonatomic,copy) void(^completionBlock)(NSString *);
@property (nonatomic,copy) void(^failedBlock)(NSString *);
@end

@implementation MDDownload

#pragma mark - 下载代理方法
// 接收到服务器响应,做准备工作
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    self.fileStream = [[NSOutputStream alloc]initToFileAtPath:self.filePath append:YES];
    [self.fileStream open];
}
// 接收到数据，用输出流拼接，计算下载进度
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [self.fileStream write:data.bytes maxLength:data.length];
    self.currentFileLength += data.length;
    float progress =(float) self.currentFileLength / self.expectedContentLength;
    if(self.progressBlock)
    {
        self.progressBlock(progress);
    }
}
// 下载完成
- (void)connectionDidFinishLoading:(NSURLConnection *)connection{

    [self.fileStream close];
    
    // 结束运行循环
    CFRunLoopStop(self.currentRunLoop);
    
    if(self.completionBlock)
    {
        // 主线程回调
        dispatch_async(dispatch_get_main_queue(), ^{
            self.completionBlock(self.filePath);
        });
    }
}

// 下载出错
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    //关闭流
    [self.fileStream close];
    
    CFRunLoopStop(self.currentRunLoop);
    
    // 几乎第三方框架的错误回调都是异步的！能够保证做一些特殊操作，不会影响到主线程
    if(self.failedBlock)
    {
        self.failedBlock(error.localizedDescription);
    }
}

#pragma mark - 下载操作
- (void)downloadWithURL:(NSURL *)url progress:(void (^)(float))progress completion:(void (^)(NSString *))completion failed:(void (^)(NSString *))failed{
    
    self.downLoadURL = url;
    self.progressBlock = progress;
    self.completionBlock = completion;
    self.failedBlock = failed;
    
    // 1、检查服务器上文件的大小
    [self serverFileSizeWithURL:url];
    
    // 2、检查本地文件信息，判断是否需要下载
    if(![self checkLocalInfo]){
        
        //2.1 如果已经下载完成，直接返回
        if(completion)
        {
            completion(self.filePath);
        }
        return;
    }
    // 2.2 如果需要下载，直接下载
    [self downLoadFile];
    
}

#pragma mark - 暂停
- (void)pause
{
    [self.downloadConnection cancel];
}
#pragma mark - 私有方法
- (void)downLoadFile{

    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        // 建立请求
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.downLoadURL cachePolicy:1 timeoutInterval:kTimeOut];
        // 设置请求头字段
        NSString *range = [NSString stringWithFormat:@"bytes=%lld-",self.currentFileLength];
        [request setValue:range forHTTPHeaderField:@"Range"];
        // 开启网络连接
       self.downloadConnection = [NSURLConnection connectionWithRequest:request delegate:self];
        // 启动网络连接
        [self.downloadConnection start];
        
        // 获取当前运行循环，并启动运行循环
        self.currentRunLoop = CFRunLoopGetCurrent();
        CFRunLoopRun();
    });
    
}

- (BOOL)checkLocalInfo{
    
    long long fileSize = 0;
    // 判断文件是否存在
    if([[NSFileManager defaultManager] fileExistsAtPath:self.filePath]){
        
        NSDictionary *attributes =  [[NSFileManager defaultManager] attributesOfItemAtPath:self.filePath error:NULL];
        
        fileSize = [attributes fileSize];
        
        if(fileSize > self.expectedContentLength){
            
            [[NSFileManager defaultManager] removeItemAtPath:self.filePath error:NULL];
            fileSize = 0;
        }
        
        self.currentFileLength = fileSize;
        if(fileSize == self.expectedContentLength) return NO;
    }
    
     return YES;
    
}
- (void)serverFileSizeWithURL:(NSURL *)url{
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:1 timeoutInterval:kTimeOut];
    
    request.HTTPMethod = @"HEAD";
    
    NSURLResponse *response = nil;
    [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:nil];
    
    
    self.expectedContentLength = response.expectedContentLength;

    self.filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:response.suggestedFilename];
}
@end
