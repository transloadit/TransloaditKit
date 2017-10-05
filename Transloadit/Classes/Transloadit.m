//
//  Transloadit.m
//  Transloadit
//
//  Created by Mark Masterson on 8/19/16.
//  Copyright © 2016 Mark R. Masterson. All rights reserved.
//

#import "Transloadit.h"


@implementation Transloadit

- (id)init {
    self = [super init];
    if(self) {
        if ([[[NSBundle mainBundle] objectForInfoDictionaryKey:@"TRANSLOADIT_SECRET"]  isEqualToString: @""] && [[[NSBundle mainBundle] objectForInfoDictionaryKey:@"TRANSLOADIT_SECRET"] isEqualToString:@""]) {
            _secret = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"TRANSLOADIT_SECRET"];
            _key = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"TRANSLOADIT_KEY"];
        } else {
            _secret = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"TRANSLOADIT_SECRET"];
            _key = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"TRANSLOADIT_KEY"];
        }
        NSLog(@"_init: %@", self);
        NSURL * applicationSupportURL = [[[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] firstObject];
        _tusStore = [[TUSFileUploadStore alloc] initWithURL:[applicationSupportURL URLByAppendingPathComponent:@"Example"]];
        _tusSession = [[TUSSession alloc] initWithEndpoint:[[NSURL alloc] initWithString:[NSString stringWithFormat:@"%@%@%@", TRANSLOADIT_API_DEFAULT_PROTOCOL, TRANSLOADIT_API_DEFAULT_BASE_URL, TRANSLOADIT_API_TUS_RESUMABLE]] dataStore:_tusStore allowsCellularAccess:YES];
        _tus = [TUSResumableUpload alloc];
        
    }
    return self;
}

- (void) createTemplate: (Template *)template {
    NSMutableDictionary *steps = [template getSteps];
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    
    [params setObject:steps forKey:@"template"];
    [params setObject:[template name] forKey:@"name"];
    
    
    NSMutableURLRequest *request = [[[TransloaditRequest alloc] initWithKey:_key andSecret:_secret] createRequestWithParams:params andEndpoint:TRANSLOADIT_API_TEMPLATES];
    
    NSURLSessionDataTask *assemblyTask = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            NSLog(@"%@", [error debugDescription]);
            return;
        }
        
        NSString* body = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:[body dataUsingEncoding:NSUTF8StringEncoding]
                                                             options:NSJSONReadingMutableContainers
                                                               error:nil];
        
        if([json valueForKey:@"error"]){
            NSLog(@"%@", [json valueForKey:@"error"]);
            return;
        } else {
            // self.assemblyCompletionBlock(json);
            NSLog(@"%@", [json debugDescription]);
            
        }
    }];
    [assemblyTask resume];
}

- (void) invokeAssembly: (Assembly *)assembly{
    
    NSArray *files = [assembly files];
    
    for (int x = 0; x < [files count]; x++) {
        TUSResumableUpload *upload = [self.tusSession createUploadFromFile:[files  objectAtIndex:x] headers:@{} metadata:@{@"filename":@"test.jpg", @"fieldname":@"file-input", @"assembly_url": [assembly urlString]}];
        upload.progressBlock = _progressBlock;
        upload.resultBlock = _resultBlock;
        upload.failureBlock = _failureBlock;
        [upload resume];
    }
}

- (void) createAssembly: (Assembly *)assembly{
    NSMutableDictionary *steps = [assembly getSteps];
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    if ([assembly template] == NULL) {
        [params setObject:steps forKey:@"steps"];
    } else {
        [params setObject:[[assembly template] template_id] forKey:@"template_id"];
    }
    NSMutableURLRequest *request = [[[TransloaditRequest alloc] initWithKey:_key andSecret:_secret] createRequestWithParams:params andEndpoint:TRANSLOADIT_API_ASSEMBLIES];
    NSURLSessionDataTask *assemblyTask = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            NSLog(@"%@", [error debugDescription]);
            return;
        }
        
        NSString* body = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:[body dataUsingEncoding:NSUTF8StringEncoding]
                                                             options:NSJSONReadingMutableContainers
                                                               error:nil];
        
        if([json valueForKey:@"error"]){
            NSLog(@"%@", [json valueForKey:@"error"]);
            return;
        } else {
            self.assemblyCompletionBlock(json);
        }
    }];
    [assemblyTask resume];
}

- (void) checkAssembly: (Assembly *)assembly {
    NSTimer *timer = [NSTimer timerWithTimeInterval:2.0 repeats:true block:^(NSTimer * _Nonnull timer) {
        [self assemblyStatus:assembly completion:^(NSDictionary *response) {
            NSArray *responseArray = @[@"REQUEST_ABORTED", @"ASSEMBLY_CANCELED", @"ASSEMBLY_COMPLETED"];
            int responseInterger = [responseArray indexOfObject:[response valueForKey:@"ok"]];
            
            switch (responseInterger) {
                case 0:
                    //Aborted
                    [timer invalidate];
                    self.assemblyStatusBlock(response);
                    break;
                case 1:
                    //canceld
                    [timer invalidate];
                    self.assemblyStatusBlock(response);
                    break;
                case 2:
                    //completed
                    [timer invalidate];
                    self.assemblyStatusBlock(response);
                default:
                    break;
            }
            
            if ([[response valueForKey:@"error"] isEqualToString:@"ASSEMBLY_CRASHED"]) {
                
            }
        }];
    }];
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
}

- (void) assemblyStatus: (Assembly *)assembly completion:(void (^)(NSDictionary *))completion {
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    NSMutableURLRequest *request = [[[TransloaditRequest alloc] initWithKey:_key andSecret:_secret] createGetRequestWithURL:[assembly urlString]];
    
    NSLog(@"Here");
    NSLog([assembly urlString]);
    NSURLSessionDataTask *assemblyTask = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            NSLog(@"%@", [error debugDescription]);
            return;
        }
        
        NSString* body = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:[body dataUsingEncoding:NSUTF8StringEncoding]
                                                             options:NSJSONReadingMutableContainers
                                                               error:nil];
        
        if([json valueForKey:@"error"]){
            NSLog(@"%@", [json valueForKey:@"error"]);
            return;
        } else {
            //self.assemblyStatusBlock(json);
        }
        
        completion(json);
    }];
    [assemblyTask resume];
}
@end
