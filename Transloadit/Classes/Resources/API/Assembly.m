//
//  Assembly.m
//  Transloadit
//
//  Created by Mark Masterson on 8/19/16.
//  Copyright © 2016 Mark R. Masterson. All rights reserved.
//

#import "Assembly.h"

@implementation Assembly


- (id)init {
    self = [super init];
    if(self) {
        NSLog(@"_init: %@", self);
        _params = [[NSDictionary alloc] init];
    }
    return self;
}

- (id)initWithParams:(NSDictionary *)params {
    self = [super init];
    if(self) {
        NSLog(@"_init: %@", self);
        _params = params;
    }
    return self;
}


- (NSURLRequest*)buildRequestFor:(APIState *)state{
    NSString *methodType = [[NSString alloc] init];
    if (_template_id != nil) {
        [_params setValue:_template_id forKey:@"template_id"];
    }
    if (_notify_url != nil) {
        [_params setValue:_notify_url forKey:@"notify_url"];
    }
    if (state == 0){
        methodType = @"POST";
    }else if (state == 1){
        methodType = @"GET";
    }
    
    
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:<#(nonnull NSURL *)#> cachePolicy:<#(NSURLRequestCachePolicy)#> timeoutInterval:<#(NSTimeInterval)#>];
    
    return request;
}




@end
