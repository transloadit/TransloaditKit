//
//  Transloadit.m
//  Transloadit
//
//  Created by Mark Masterson on 8/19/16.
//  Copyright © 2016 Mark R. Masterson. All rights reserved.
//

#import "Transloadit.h"


@interface Transloadit()

@end

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
- (NSString*)generateSignatureWithParams:(NSDictionary *)params {
    NSError *error;

    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:params
                                                       options:0
                                                         error:&error];
    NSLog([[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding]);
    if (!jsonData) {
        NSLog(@"Got an error: %@", error);
        return nil;
    } else {
        NSString *hash = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        return [hash signWithKey:_key];
    }
}





- (void) createAssembly: (Assembly *)assembly{
    NSDate *date = [[NSDate alloc] initWithTimeIntervalSinceNow:60*10];
    NSDateFormatter *dateFormatter=[[NSDateFormatter alloc]init];
    NSTimeZone *timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
    [dateFormatter setTimeZone:timeZone];
    [dateFormatter setDateFormat:@"YYYY/MM/dd HH:mm:SS+00:00"];
    
    NSMutableDictionary *auth = [[NSMutableDictionary alloc] init];
    [auth setObject:_key forKey:@"key"];
    [auth setObject:[dateFormatter stringFromDate:date] forKey:@"expires"];
    NSLog([dateFormatter stringFromDate:date]);
    NSMutableDictionary *params = @{@"auth":auth, @"steps":[assembly getSteps]};
    
    //NSString *signature = [self generateSignatureWithParams: params];
    
  
    
    
    
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[[NSURL alloc] initWithString:[NSString stringWithFormat:@"%@%@%@", TRANSLOADIT_API_DEFAULT_PROTOCOL, TRANSLOADIT_API_DEFAULT_BASE_URL, TRANSLOADIT_API_ASSEMBLIES]] cachePolicy: NSURLRequestReturnCacheDataElseLoad timeoutInterval:120.0];
    [request setHTTPMethod:@"POST"];
    
    NSLog([[request URL] absoluteString]);
    
    [request addValue:@"multipart/form-data" forHTTPHeaderField:@"Content-Type"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];
    
    [request setHTTPMethod:@"POST"];
   
    NSString *boundary = @"YOUR_BOUNDARY_STRING";
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary];
    [request addValue:contentType forHTTPHeaderField:@"Content-Type"];
    
    NSMutableData *body = [NSMutableData data];
    
    
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:params
                                                       options:0 // Pass 0 if you don't care about the readability of the generated string
                                                         error:nil];
    
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"params\"\r\n\r\n%@",  [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding]] dataUsingEncoding:NSUTF8StringEncoding]];
    
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"tus_num_expected_upload_files\"\r\n\r\n%d", 2] dataUsingEncoding:NSUTF8StringEncoding]];
    
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    
    [request setHTTPBody:body];
    
    
  

   
    
    NSURLSessionDataTask *assemblyTask = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            NSLog([error debugDescription]);
            return;
        }
        
        if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
            NSLog(@"Response HTTP Status code: %ld\n", (long)[(NSHTTPURLResponse *)response statusCode]);
            NSLog(@"Response HTTP Headers:\n%@\n", [(NSHTTPURLResponse *)response allHeaderFields]);
        }
        
        NSString* body = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSLog(@"Response Body:\n%@\n", body);
    }];
    
    
   // NSLog([[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding]);
    
   [assemblyTask resume];
 
}


-(void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
   didReceiveData:(NSData *)data {
    
    //[receivedData appendData:data];
}




@end
