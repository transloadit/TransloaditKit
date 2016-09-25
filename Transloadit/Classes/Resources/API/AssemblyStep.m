//
//  AssemblyStep.m
//  Transloadit
//
//  Created by Mark Masterson on 8/19/16.
//  Copyright © 2016 Mark R. Masterson. All rights reserved.
//

#import "AssemblyStep.h"

@implementation AssemblyStep

-(id)init{
    
    self = [super init];
    if(self) {
        self.options = [[NSMutableDictionary alloc] init];
    }
    return self;
}

-(void)setValue:(NSString *)value forOption:(NSString *)option{
    
    [self.options setValue:value forKey:option];
    
}

@end
