/**
 *  MDDownload.h
 *  
 *  该文件可以执行下载操作，用 NSURLConnection 的代理方法，解决了直接用 NSURLConnection 的异步方法的
 *  内存峰值问题。
 *
 *  Created by xuehan.
 *  Copyright (c)  xuehan. All rights reserved.
 */

#import <Foundation/Foundation.h>

@interface MDDownload : NSObject

- (void)downloadWithURL:(NSURL *)url progress:(void (^)(float progress))progress completion:(void (^)(NSString *filePath))completion failed:(void(^)(NSString *errorMessage))failed;

- (void)pause;
@end
