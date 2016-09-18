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
        
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        [configuration setAllowsCellularAccess:true];
        
        _session = [NSURLSession sessionWithConfiguration:configuration];
        _tus = [TUSResumableUpload alloc];
        _tusStore = [TUSUploadStore alloc];
        
    }
    return self;
}

- (void) perfromAssebmly: (Assembly *)assembly{
    
    NSMutableURLRequest *request = [assembly createRequest];
    [request setHTTPMethod:@"POST"];
    //[request setHTTPBody:[[[assembly params ]description] dataUsingEncoding:NSUTF8StringEncoding]];
    
    [_session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        //
    }];
    
    
    
}





@end
