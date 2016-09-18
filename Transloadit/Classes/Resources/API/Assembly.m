//
//  Assembly.m
//  Transloadit
//
//  Created by Mark Masterson on 8/19/16.
//  Copyright © 2016 Mark R. Masterson. All rights reserved.
//

#import "Assembly.h"

@interface Assembly ()

@end;

@implementation Assembly

@synthesize params;



- (id)initWithSteps:(NSMutableArray<AssemblyStep *>*)steps andNumberOfFiles:(int)numberOfFiles{
    self = [super init];
    if(self) {
        NSLog(@"_init: %@", self);
        [self setStepsArray:steps];
        [self setNumberOfFiles:numberOfFiles];
    }
    return self;
}

- (id)initWithStepsJSONString:(NSString *)steps andNumberOfFiles:(int)numberOfFiles{
    self = [super init];
    if(self) {
        NSLog(@"_init: %@", self);
        [self setStepsJSONString:steps]; //TODO: Parse Through JSON And Create Assembly Step Objects, Add To Step Array
        [self setNumberOfFiles:numberOfFiles];
    }
    return self;
}


-(void)addStepWithAssemblyStep:(AssemblyStep *)step{
    [[self stepsArray] addObject:step];
}

-(void)addStepWithJSONString:(NSString *)step{
    [[self stepsArray] addObject:[[AssemblyStep alloc] initWithJSON:step]];
}


- (NSMutableURLRequest*)createRequestWithSignature:(NSString *)signature{

    NSString *methodType = [[NSString alloc] init];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[[NSURL alloc] initWithString:[NSString stringWithFormat:@"%@%@%@?signature=%@", TRANSLOADIT_API_DEFAULT_PROTOCOL, TRANSLOADIT_API_DEFAULT_BASE_URL, TRANSLOADIT_API_ASSEMBLIES,signature]] cachePolicy: NSURLRequestReturnCacheDataElseLoad timeoutInterval:120.0];
    
    
    
    return request;
}




@end
