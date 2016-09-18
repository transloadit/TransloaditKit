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
#import "APIState.h"
#import "APIObjectType.h"
#import "NSString+Utils.h"
#import <TUSKit/TUSKit.h>

#pragma mark - Resource Includes

@interface Transloadit : NSObject<TransloaditProtocol>

@property (nonatomic, strong) NSURLSession *session; // Session to use for uploads

@property (nonatomic, strong) NSString *secret; // Transloadit Secret

@property (nonatomic, strong) NSString *key; // Transloadit Key

@property (nonatomic, strong) NSDictionary *headers;

@property (nonatomic, strong) TUSResumableUpload *tus;

@property (nonatomic, strong) TUSUploadStore *tusStore;


- (id)initWithKey:(NSString *)key andSecret:(NSString *)secret;

- (NSData*)generateSignature;

- (NSString *)signWithKey:(NSString *)key usingData:(NSString *)data;

- (void) createAssembly: (Assembly *)assembly;

//- (TransloaditResponse *) createAssembly: (Assembly *)assembly;

@end
