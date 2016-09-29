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
@synthesize notify_url;


- (id)initWithSteps:(NSMutableArray<AssemblyStep *>*)steps andNumberOfFiles:(int)numberOfFiles{
    self = [super init];
    if(self) {
        NSLog(@"_init: %@", self);
        [self setStepsArray:steps];
        [self setNumberOfFiles:numberOfFiles];
        [self setExpireDate:[[NSDate alloc] initWithTimeIntervalSinceNow:5*60]];
        [self setFiles:[[NSMutableArray alloc] init]];
    }
    return self;
}


-(void)addStepWithAssemblyStep:(AssemblyStep *)step{
    [[self stepsArray] addObject:step];
}




- (NSMutableURLRequest*)createRequestWithSignature:(NSString *)signature{

    NSString *methodType = [[NSString alloc] init];
    
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[[NSURL alloc] initWithString:[NSString stringWithFormat:@"%@%@%@", TRANSLOADIT_API_DEFAULT_PROTOCOL, TRANSLOADIT_API_DEFAULT_BASE_URL, TRANSLOADIT_API_ASSEMBLIES]] cachePolicy: NSURLRequestReturnCacheDataElseLoad timeoutInterval:120.0];

    
    [request addValue:@"multipart/form-data" forHTTPHeaderField:@"Content-Type"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];
    
    [request setHTTPMethod:@"POST"];
    
    
    NSString *boundary = @"YOUR_BOUNDARY_STRING";
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary];
    
    [request addValue:contentType forHTTPHeaderField:@"Content-Type"];
    
    NSMutableData *body = [NSMutableData data];

    
    return request;
}


-(NSMutableDictionary *)getSteps{
    
       
    NSMutableDictionary *stepsMutableDictionary = [[NSMutableDictionary alloc] init];
    for (AssemblyStep* step in _stepsArray) {
       [stepsMutableDictionary addEntriesFromDictionary:[step options]];
    }
   NSMutableDictionary *params = @{@"steps":stepsMutableDictionary};
    
    
    if ([[self notify_url] length]) {
        [params setObject:[self notify_url] forKey:@"notify_url"];
    }

    return stepsMutableDictionary;
    
}


-(void)setExpirationWithMinutes:(int)minutes{
    
    minutes = minutes * 60;
    
    _expireDate = [[NSDate alloc] initWithTimeIntervalSinceNow:minutes];
    
}

-(void) addFile:(NSURL *)file{
    [[self files] addObject:file];
}

-(int) fileCount{
    return [[self files] count];
}


@end
