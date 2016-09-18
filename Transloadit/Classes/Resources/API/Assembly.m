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




- (id)init {
    self = [super init];
    if(self) {
        NSLog(@"_init: %@", self);
      //  self.params = [[NSDictionary alloc] init];
      //  self.type = Assembly_API_Object;
    }
    return self;
}

- (id)initWithParams:(NSDictionary *)params {
    self = [super init];
    if(self) {
        NSLog(@"_init: %@", self);
 
    }
    return self;
}


- (NSMutableURLRequest*)createRequest{
    NSString *methodType = [[NSString alloc] init];
//    if (_template_id != nil) {
//        [self.params setValue:_template_id forKey:@"template_id"];
//    }
//    if (_notify_url != nil) {
//        [self.params setValue:_notify_url forKey:@"notify_url"];
//    }

   
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[[NSURL alloc] initWithString:[NSString stringWithFormat:@"%@/%@/%@", TRANSLOADIT_API_DEFAULT_PROTOCOL, TRANSLOADIT_API_DEFAULT_BASE_URL, TRANSLOADIT_API_ASSEMBLIES]] cachePolicy: NSURLRequestReturnCacheDataElseLoad timeoutInterval:120.0];
    
    
    
    return request;
}




@end
