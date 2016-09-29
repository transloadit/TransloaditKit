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

- (id)initWithKey:(NSString *)key andSecret:(NSString *)secret {
    self = [super init];
    if(self) {
        NSLog(@"_init: %@", self);
        _secret = secret;
        _key = key;
        
    NSURL * applicationSupportURL = [[[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] firstObject];
        _tusStore = [[TUSFileUploadStore alloc] initWithURL:[applicationSupportURL URLByAppendingPathComponent:@"Example"]];

        _tusSession = [[TUSSession alloc] initWithEndpoint:[[NSURL alloc] initWithString:[NSString stringWithFormat:@"%@%@%@", TRANSLOADIT_API_DEFAULT_PROTOCOL, TRANSLOADIT_API_DEFAULT_BASE_URL, TRANSLOADIT_API_TUS_RESUMABLE]] dataStore:_tusStore allowsCellularAccess:YES];
        
        
        _tus = [TUSResumableUpload alloc];
        
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





- (void) invokeAssembly: (Assembly *)assembly{
    
    NSDate *date = [[NSDate alloc] initWithTimeIntervalSinceNow:60*10];
    NSDateFormatter *dateFormatter=[[NSDateFormatter alloc]init];
    NSTimeZone *timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
    [dateFormatter setTimeZone:timeZone];
    [dateFormatter setDateFormat:@"YYYY/MM/dd HH:mm:SS+00:00"];
    
    NSMutableDictionary *auth = [[NSMutableDictionary alloc] init];
    [auth setObject:_key forKey:@"key"];
    [auth setObject:[dateFormatter stringFromDate:[assembly expireDate]] forKey:@"expires"];

    NSMutableDictionary *params = @{@"auth":auth, @"steps":[assembly getSteps]};
    
    NSString *signature = [self generateSignatureWithParams: params];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[[NSURL alloc] initWithString:[NSString stringWithFormat:@"%@%@%@?signature=%@", TRANSLOADIT_API_DEFAULT_PROTOCOL, TRANSLOADIT_API_DEFAULT_BASE_URL, TRANSLOADIT_API_ASSEMBLIES, signature]] cachePolicy: NSURLRequestReturnCacheDataElseLoad timeoutInterval:120.0];
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
    NSString *responseData = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    responseData = [responseData stringByReplacingOccurrencesOfString:@"\\" withString:@""];
    NSString* encodedString = [responseData stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    NSLog(responseData);
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"tus_num_expected_upload_files\"\r\n\r\n%d", [assembly fileCount]] dataUsingEncoding:NSUTF8StringEncoding]];
    
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    
    [request setHTTPBody:body];
    
    NSURLSessionDataTask *assemblyTask = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            NSLog([error debugDescription]);
            return;
        }
        
        NSString* body = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:[body dataUsingEncoding:NSUTF8StringEncoding]
                                                             options:NSJSONReadingMutableContainers
                                                               error:nil];
        
        TransloaditResponse *assemblyResponse = [[TransloaditResponse alloc]initWithID:[json valueForKey:@"id"] AndStatusEndpoint:[json valueForKey:@"status_endpoint"] andAddFilesEndpoint:[json valueForKey:@"add_files_endpoint"]];
        NSLog([[assembly files] description]);
        
        
        
        TUSResumableUpload *upload = [self.tusSession createUploadFromFile:[[assembly files] firstObject] headers:@{} metadata:@{@":assembly_id":[json valueForKey:@"id"], @"filename":@"test.jpg", @"fieldname":@"file-input", @"assembly_url":[json valueForKey:@"status_endpoint"]}];

            upload.progressBlock = _progressBlock;
            upload.resultBlock = _resultBlock;
            upload.failureBlock = _failureBlock;

        [upload resume];
        NSLog(@"Response Body:\n%@\n", body);
    }];
    
    
    
   [assemblyTask resume];
 
}


-(void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
   didReceiveData:(NSData *)data {
    
    //[receivedData appendData:data];
}




@end
