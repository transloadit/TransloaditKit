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
        _secret = secret;
        _key = key;
        
        NSURLSessionConfiguration *configuration = [[NSURLSessionConfiguration alloc] init];
        [configuration setAllowsCellularAccess:true];
        
        _session = [NSURLSession sessionWithConfiguration:configuration];
        _tus = [TUSResumableUpload alloc];
        _tusStore = [TUSUploadStore alloc];
        
    }
    return self;
}

- (TransloaditResponse *) createAssembly: (Assembly *)assembly{
    
    NSMutableURLRequest *request = [assembly createRequest];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:[[assembly params] dataUsingEncoding:NSUTF8StringEncoding]];
    
    [_session dataTaskWithURL:[assembly createRequest]];
    
    
    
}





@end
