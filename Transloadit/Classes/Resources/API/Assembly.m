//
//  Assembly.m
//  Transloadit
//
//  Created by Mark Masterson on 8/19/16.
//  Copyright © 2016 Mark R. Masterson. All rights reserved.
//

#import "Assembly.h"


@implementation Assembly

@synthesize params;
@synthesize notify_url;


- (id)initWithSteps:(NSMutableArray<Step *>*)steps andNumberOfFiles:(int)numberOfFiles{
    self = [super init];
    if(self) {
        NSLog(@"_init: %@", self);
        [self setStepsArray:steps];
        [self setNumberOfFiles:&numberOfFiles];
        [self setFiles:[[NSMutableArray alloc] initWithCapacity:numberOfFiles]];
        [self setFileNames:[[NSMutableArray alloc] initWithCapacity:numberOfFiles]];

    }
    return self;
}

- (id)initWithTemplate:(Template *)template andNumberOfFiles:(int)numberOfFiles {
    self = [super init];
    if(self) {
        NSLog(@"_init: %@", self);
        [self setTemplate:template];
        [self setNumberOfFiles:&numberOfFiles];
        [self setFiles:[[NSMutableArray alloc] initWithCapacity:numberOfFiles]];
        [self setFileNames:[[NSMutableArray alloc] initWithCapacity:numberOfFiles]];
    }
    return self;
}


-(void)addStepWithStep:(Step *)step{
    [[self stepsArray] addObject:step];
}


-(NSMutableDictionary *)getSteps{
    
       
    NSMutableDictionary *stepsMutableDictionary = [[NSMutableDictionary alloc] init];
    for (Step* step in _stepsArray) {
        NSDictionary *tempOptions = [step options];
        if (tempOptions) {
            [stepsMutableDictionary addEntriesFromDictionary:tempOptions];
        }
    }
    NSParameterAssert(stepsMutableDictionary);
    NSMutableDictionary *params = @{@"steps":stepsMutableDictionary};
    
    
    if ([[self notify_url] length]) {
        [params setObject:[self notify_url] forKey:@"notify_url"];
    }

    return stepsMutableDictionary;
    
}


-(void) addFile:(NSURL* )file andFileName:(NSString* ) fileName{
    if([self files]) {
        [[self fileNames] addObject:fileName];
        [[self files] addObject:file];
    }
}

-(int) fileCount{
    return [[self files] count];
}


@synthesize data;

@end
