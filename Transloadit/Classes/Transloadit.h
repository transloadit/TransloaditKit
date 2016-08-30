//
//  Transloadit.h
//  Transloadit
//
//  Created by Mark Masterson on 8/19/16.
//  Copyright © 2016 Mark R. Masterson. All rights reserved.
//

#import <Foundation/Foundation.h>

#pragma mark - Resource Includes
#import "Resources/API/APIObject.h"
#import "Resources/Resources.h"

@interface Transloadit : NSObject

@property (nonatomic, strong) NSURLSession *session; // Session to use for uploads


- (id)initWithKey:(NSString *)key andSecret:(NSString *)secret;


- (void) prefromAssebmly: (Assembly *)assembly;

@end
