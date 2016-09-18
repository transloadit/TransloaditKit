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


- (id)init {
    self = [super init];
    if(self) {
        NSLog(@"_init: %@", self);
      //  self.params = [[NSDictionary alloc] init];
      //  self.type = Assembly_API_Object;
    }
    return self;
}

- (id)initWithSteps:(NSMutableArray<AssemblyStep *>*)steps andNumberOfFiles:(int)numberOfFiles{
    self = [super init];
    if(self) {
        NSLog(@"_init: %@", self);
        [self setSteps:steps];
        [self setNumberOfFiles:numberOfFiles];
    }
    return self;
}


-(void)addStep:(AssemblyStep *)step{
    [[self steps] addObject:step];
}



- (NSMutableURLRequest*)createRequestWithSignature:(NSString *)signature{

    NSString *methodType = [[NSString alloc] init];

   
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[[NSURL alloc] initWithString:[NSString stringWithFormat:@"%@%@%@?signature=%@", TRANSLOADIT_API_DEFAULT_PROTOCOL, TRANSLOADIT_API_DEFAULT_BASE_URL, TRANSLOADIT_API_ASSEMBLIES,signature]] cachePolicy: NSURLRequestReturnCacheDataElseLoad timeoutInterval:120.0];
    
    
    
    return request;
}




@end
