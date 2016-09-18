//
//  Transloadit.h
//  Transloadit
//
//  Created by Mark Masterson on 8/19/16.
//  Copyright © 2016 Mark R. Masterson. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TransloaditProtocol.h"
#import "Resources/API/Assembly.h"
#import "Resources/API/TransloaditResponse.h"

#pragma mark - Resource Includes

@interface Transloadit : NSObject<TransloaditProtocol>

@property (nonatomic, strong) NSURLSession *session; // Session to use for uploads

@property (nonatomic, strong) NSString *secret; // Transloadit Secret

@property (nonatomic, strong) NSString *key; // Transloadit Key

@property (nonatomic, strong) NSDictionary *headers;



- (id)initWithKey:(NSString *)key andSecret:(NSString *)secret;



- (TransloaditResponse *) prefromAssebmly: (Assembly *)assembly;

- (TransloaditResponse *) createAssembly: (Assembly *)assembly;

@end
