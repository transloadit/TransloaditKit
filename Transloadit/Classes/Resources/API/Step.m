//
//  Step.m
//  Transloadit
//
//  Created by Mark Masterson on 8/19/16.
//  Copyright © 2016 Mark R. Masterson. All rights reserved.
//

#import "Step.h"

@implementation Step

-(id)initWithKey:(NSString *)key{
    
    self = [super init];
    if(self) {
        _key = key;
        self.options = @{_key:[[NSMutableDictionary alloc] init]};
    }
    return self;
}

-(void)setValue:(NSString *)value forOption:(NSString *)option{
    
    [[self.options objectForKey:_key] setValue:value forKey:option];
    
}

@end
