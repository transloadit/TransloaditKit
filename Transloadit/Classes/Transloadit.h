//
//  Transloadit.h
//  Transloadit
//
//  Created by Mark Masterson on 8/19/16.
//  Copyright © 2016 Mark R. Masterson. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TransloaditProtocol.h"
#import "Assembly.h"
#import "AssemblyStep.h"
#import "APIState.h"
#import "APIObjectType.h"
#import "NSString+Utils.h"
#import <TUSKit/TUSKit.h>

#pragma mark - Resource Includes

typedef void (^TransloaditUploadResultBlock)(NSURL* _Nonnull fileURL);
typedef void (^TransloaditUploadFailureBlock)(NSError* _Nonnull error);
typedef void (^TransloaditUploadProgressBlock)(int64_t bytesWritten, int64_t bytesTotal);

typedef void (^TransloaditAssemblyCompletionBlock)(NSDictionary* _Nonnull completionDictionary);
typedef void (^TransloaditAssemblyStatusBlock)(NSDictionary* _Nonnull completionDictionary);



@interface Transloadit : NSObject<TransloaditProtocol>
@property (readwrite, copy) _Nullable TransloaditUploadResultBlock resultBlock;
@property (readwrite, copy) _Nullable TransloaditUploadFailureBlock failureBlock;
@property (readwrite, copy) _Nullable TransloaditUploadProgressBlock progressBlock;

@property (readwrite, copy) _Nullable TransloaditAssemblyCompletionBlock assemblyCompletionBlock;

@property (readwrite, copy) _Nullable TransloaditAssemblyStatusBlock assemblyStatusBlock;



@property (nonatomic, strong) NSString * _Nonnull secret; // Transloadit Secret
@property (nonatomic, strong) NSString  * _Nonnull key; // Transloadit Key

#pragma mark - TUSKit References
@property (nonatomic, strong) TUSSession* _Nonnull tusSession;
@property (nonatomic, strong) TUSResumableUpload  * _Nonnull tus;
@property (nonatomic, strong) TUSUploadStore  * _Nonnull tusStore;


- (id _Nonnull )initWithKey:(NSString *_Nonnull)key andSecret:(NSString *_Nonnull)secret;
- (void) invokeAssembly: (Assembly *_Nonnull)assembly;
- (void) createAssembly: (Assembly *_Nonnull)assembly;
- (void) checkAssembly: (Assembly *_Nonnull)assembly;

@end
