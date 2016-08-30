//
//  Assembly.m
//  Transloadit
//
//  Created by Mark Masterson on 8/19/16.
//  Copyright © 2016 Mark R. Masterson. All rights reserved.
//

#import "Assembly.h"

@implementation Assembly


- (id)initWithID:(NSString *)assembly_id {
    self = [super init];
    if(self) {
        NSLog(@"_init: %@", self);
        
    }
    return self;
}

- (id)initWithSteps:(AssemblyStep [])steps {
    self = [super init];
    if(self) {
        NSLog(@"_init: %@", self);
        
    }
    return self;
}

-(NSURL)url


@end
