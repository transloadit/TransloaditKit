//
//  Transloadit.m
//  Transloadit
//
//  Created by Mark Masterson on 8/19/16.
//  Copyright © 2016 Mark R. Masterson. All rights reserved.
//

#import "Transloadit.h"

@implementation Transloadit

-(NSURLSession *) session1{
    // Lazily instantiate a session
    if (_session == nil){
        NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
        sessionConfiguration.allowsCellularAccess = true;
        _session = [NSURLSession sessionWithConfiguration:sessionConfiguration delegate:nil delegateQueue:[NSOperationQueue mainQueue]];
    }
    return _session;
}

- (id)initWithKey:(NSString *)key andSecret:(NSString *)secret {
    self = [super init];
    if(self) {
        NSLog(@"_init: %@", self);
        _secret = secret;
        _key = key;
        
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        [configuration setAllowsCellularAccess:true];
        [configuration setHTTPMaximumConnectionsPerHost:10];
        _session = [NSURLSession sessionWithConfiguration:configuration delegate:nil delegateQueue:[NSOperationQueue mainQueue]];
        
        
        _tus = [TUSResumableUpload alloc];
        _tusStore = [TUSUploadStore alloc];
        
    }
    return self;
}


//TODO: Add WithParams as NSDictionary
- (NSString*)generateSignature {
    NSError *error;
    NSDate *date = [[NSDate alloc] init];
    NSDateFormatter *dateFormatter=[[NSDateFormatter alloc]init];
    NSTimeZone *timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
    [dateFormatter setTimeZone:timeZone];
    [dateFormatter setDateFormat:@"YYYY/MM/dd HH:mm:SS+00:00"];
    
    
    
    NSMutableDictionary *signatureDictionary = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *authDictionary = @{@"key":_key, @"expires":[dateFormatter stringFromDate:date]};
    NSDictionary *steps = @{};


    
    [signatureDictionary setObject:authDictionary forKey:@"auth"];
    [signatureDictionary setObject:steps forKey:@"steps"];
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:signatureDictionary
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:&error];
    
    if (!jsonData) {
        NSLog(@"Got an error: %@", error);
        return nil;
    } else {
        NSString *hash = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        return [hash signWithKey:_key];
    }
}

- (void) createAssembly: (Assembly *)assembly{
       NSString *signature = [self generateSignature];
    NSMutableURLRequest *request = [assembly createRequestWithSignature:signature];

    [request setHTTPMethod:@"POST"];
    
    NSLog([[request URL] absoluteString]);
    
    
    
    NSURLSessionUploadTask *assemblyTask = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            // Handle error...
            return;
        }
        
        if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
            NSLog(@"Response HTTP Status code: %ld\n", (long)[(NSHTTPURLResponse *)response statusCode]);
            NSLog(@"Response HTTP Headers:\n%@\n", [(NSHTTPURLResponse *)response allHeaderFields]);
        }
        
        NSString* body = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSLog(@"Response Body:\n%@\n", body);
    }];
    
    [assemblyTask resume];
}


-(void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
   didReceiveData:(NSData *)data {
    
    //[receivedData appendData:data];
}




@end
