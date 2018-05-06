//
//  Transloadit.h
//  Transloadit
//
//  Created by Mark Masterson on 8/19/16.
//  Copyright © 2016 Mark R. Masterson. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TransloaditProtocol.h"
#import "TransloaditRequest.h"
#import "Assembly.h"
#import "Template.h"
#import "Step.h"
#import "APIState.h"
#import "APIObjectType.h"
#import "NSString+Utils.h"
#import <TUSKit/TUSKit.h>

#pragma mark - Resource Includes

typedef void (^TransloaditUploadResultBlock)(NSURL* _Nonnull fileURL);
typedef void (^TransloaditUploadFailureBlock)(NSError* _Nonnull error);
typedef void (^TransloaditUploadProgressBlock)(int64_t bytesWritten, int64_t bytesTotal);


typedef void (^TransloaditAssemblyCreationResultBlock)(Assembly* _Nonnull assembly, NSDictionary* _Nonnull completionDictionary);
typedef void (^TransloaditAssemblyCreationFailureBlock)(NSDictionary* _Nonnull completionDictionary);

typedef void (^TransloaditTemplateCreationResultBlock)(Template* _Nonnull assembly, NSDictionary* _Nonnull completionDictionary);
typedef void (^TransloaditTemplateCreationFailureBlock)(NSDictionary* _Nonnull completionDictionary);


typedef void (^TransloaditAssemblyResultBlock)(NSDictionary* _Nonnull completionDictionary);
typedef void (^TransloaditAssemblyFailureBlock)(NSDictionary* _Nonnull completionDictionary);
typedef void (^TransloaditAssemblyStatusBlock)(NSDictionary* _Nonnull completionDictionary);



@interface Transloadit : NSObject<TransloaditProtocol>
@property (readwrite, copy) _Nullable TransloaditUploadResultBlock uploadResultBlock;
@property (readwrite, copy) _Nullable TransloaditUploadFailureBlock uploadFailureBlock;
@property (readwrite, copy) _Nullable TransloaditUploadProgressBlock uploadProgressBlock;

@property (readwrite, copy) _Nullable TransloaditAssemblyCreationResultBlock assemblyCreationResultBlock;
@property (readwrite, copy) _Nullable TransloaditAssemblyCreationFailureBlock assemblyCreationFailureBlock;

@property (readwrite, copy) _Nullable TransloaditTemplateCreationResultBlock templateCreationResultBlock;
@property (readwrite, copy) _Nullable TransloaditTemplateCreationFailureBlock templateCreationFailureBlock;

@property (readwrite, copy) _Nullable TransloaditAssemblyResultBlock assemblyResultBlock;
@property (readwrite, copy) _Nullable TransloaditAssemblyFailureBlock assemblyFailureBlock;
@property (readwrite, copy) _Nullable TransloaditAssemblyStatusBlock assemblyStatusBlock;

@property (nonatomic, strong) NSString * _Nonnull secret; // Transloadit Secret
@property (nonatomic, strong) NSString  * _Nonnull key; // Transloadit Key

#pragma mark - TUSKit References
@property (nonatomic, strong) TUSResumableUpload  * _Nonnull tus;
@property (nonatomic, strong) TUSUploadStore  * _Nonnull tusStore;
@property (nonatomic, strong) TUSSession  * _Nonnull tusSession;


- (id _Nonnull )init;
- (void) createTemplate: (Template *_Nonnull)template;
- (void) invokeAssembly: (Assembly *_Nonnull)assembly;
- (void) createAssembly: (Assembly *_Nonnull)assembly;
- (void) checkAssembly: (Assembly *_Nonnull)assembly;

@end
