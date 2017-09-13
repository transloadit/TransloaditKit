//
//  Template.m
//  Transloadit
//
//  Created by Mark Masterson on 8/19/16.
//  Copyright © 2016 Mark R. Masterson. All rights reserved.
//

#import "Template.h"

@interface Template ()

@end;

@implementation Template

- (id)initWithTemplateId:(NSString *)template_id {
    self = [super init];
    if(self) {
        NSLog(@"_init: %@", self);
        [self setTemplate_id:template_id];
    }
    return self;
}

- (id)initWithSteps:(NSMutableArray<Step *>*)steps andName: (NSString *)name {
    self = [super init];
    if(self) {
        NSLog(@"_init: %@", self);
        [self setStepsArray:steps];
        [self setName:name];
    }
    return self;
}


-(NSMutableDictionary *)getSteps { 
    
    
    NSMutableDictionary *stepsMutableDictionary = [[NSMutableDictionary alloc] init];
    for (Step* step in _stepsArray) {
        NSDictionary *tempOptions = [step options];
        if (tempOptions) {
            [stepsMutableDictionary addEntriesFromDictionary:tempOptions];
        }
    }
    NSParameterAssert(stepsMutableDictionary);
    NSMutableDictionary *params = @{@"steps":stepsMutableDictionary};
    
    

    
    return stepsMutableDictionary;
    
}
@end
