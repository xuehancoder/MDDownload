/**
 *  MDDownloadManager.m
 *
 *  该文件为下载管理器，提供了下载和暂停方法，并且提供了一个单例来管理所有的下载操作。
 *
 *  Created by xuehan.
 *  Copyright (c)  xuehan. All rights reserved.
 */

#import "MDDownloadManager.h"
#import "MDDownload.h"
@interface MDDownloadManager()

@property (nonatomic,strong) NSMutableDictionary *downloadCache;
@property (nonatomic,copy) void(^failedBlock)(NSString *);
@end
@implementation MDDownloadManager

#pragma mark - 懒加载
- (NSMutableDictionary *)downloadCache
{
    if(_downloadCache == nil)
    {
        _downloadCache = [NSMutableDictionary dictionary];
    }
    return _downloadCache;
}

#pragma mark - 单例
+ (instancetype)sharedDownloadManager
{
    static MDDownloadManager *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc]init];
    });
    return instance;
}

#pragma mark - 下载操作
- (void)downloadWithURL:(NSURL *)url progress:(void (^)(float))progress completion:(void (^)(NSString *))completion failed:(void (^)(NSString *))failed
{
    self.failedBlock = failed;
    // 1 判断下载缓存池中是否存在下载操作
    MDDownload *download = self.downloadCache[url.path];
    
    // 1.1 如果有操作，提示拼命下载
    if(download != nil)
    {
        if(failed)
        {
            failed(@"正在拼命下载...");
            
        }
        return;
    }
    
    // 1.2 如果没有操作，新建下载操作
    download = [[MDDownload alloc]init];
    // 2、将操作添加到下载操作缓冲池
    [self.downloadCache setObject:download forKey:url.path];
    // 3、开始下载
    [download downloadWithURL:url progress:progress completion:^(NSString *filePath) {
        // 3.1 下载完成，从缓存池中移除下载操作
        [self.downloadCache removeObjectForKey:url.path];
        // 2. 判断调用方是否传递了 completion，如果传递了直接执行
        if(completion){
            completion(filePath);
        }
        
    } failed:failed];
}
#pragma mark - 暂停
- (void)pauseWithURL:(NSURL *)url{

    // 1、判断缓存池中有没有下载操作
    MDDownload *download = self.downloadCache[url.path];
    // 1.1
    if(download == nil)
    {
        if(self.failedBlock)
        {
            self.failedBlock(@"没有下载操作");
            return;
        }
    }
    // 暂停下载
    [download pause];
    // 从缓存池中移除下载操做
    [self.downloadCache removeObjectForKey:url.path];
    
}
@end
