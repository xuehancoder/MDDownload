/**
 *  MDDownloadManager.h
 *
 *  该文件为下载管理器，提供了下载和暂停方法，并且提供了一个单例来管理所有的下载操作。
 *
 *  Created by xuehan.
 *  Copyright (c)  xuehan. All rights reserved.
 */

#import <Foundation/Foundation.h>
@class MDDownload;
@interface MDDownloadManager : NSObject

+ (instancetype)sharedDownloadManager;

/** 下载指定的URL */
- (void)downloadWithURL:(NSURL *)url progress:(void (^)(float progress))progress completion:(void (^)(NSString *filePath))completion failed:(void(^)(NSString *errorMessage))failed;

/** 暂停  */
- (void)pauseWithURL:(NSURL *)url;
@end
