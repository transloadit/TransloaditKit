//
//  Transloadit.m
//  Transloadit
//
//  Created by Mark Masterson on 8/19/16.
//  Copyright © 2016 Mark R. Masterson. All rights reserved.
//

#import "Transloadit.h"

@implementation Transloadit


- (id)initWithKey:(NSString *)key andSecret:(NSString *)secret {
    self = [super init];
    if(self) {
        NSLog(@"_init: %@", self);
        self.session = [NSURLSession sharedSession];
    }
    return self;
}


- (void) prefromAssebmly: (Assembly *)assembly {
    
}

@end
