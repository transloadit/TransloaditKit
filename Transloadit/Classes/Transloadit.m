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
        NSString* PLIST_KEY = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"TRANSLOADIT_KEY"];
        NSString* PLIST_SECRET = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"TRANSLOADIT_SECRET"];

        if (![PLIST_KEY  isEqualToString: @""] && ![PLIST_SECRET isEqualToString:@""]) {
            _secret = PLIST_SECRET;
            _key = PLIST_KEY;
        }
        
        NSURL * applicationSupportURL = [[[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] firstObject];
        _tusStore = [[TUSFileUploadStore alloc] initWithURL:[applicationSupportURL URLByAppendingPathComponent:@"Example"]];
        _tus = [TUSResumableUpload alloc];
        
    }
    return self;
}

- (void) createTemplate: (Template *)template {
    NSMutableDictionary *steps = [template getSteps];
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    
    NSMutableDictionary *templateJSON = [[NSMutableDictionary alloc] init];
    
    [templateJSON setObject:steps forKey:@"steps"];
    
    [params setObject:templateJSON forKey:@"template"];
    [params setObject:[template name] forKey:@"name"];
    
    
    NSMutableURLRequest *request = [[[TransloaditRequest alloc] initWithKey:_key andSecret:_secret] createRequestWithParams:params andEndpoint:TRANSLOADIT_API_TEMPLATES];
    
    NSURLSessionDataTask *assemblyTask = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            return;
        }
        
        NSString* body = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:[body dataUsingEncoding:NSUTF8StringEncoding]
                                                             options:NSJSONReadingMutableContainers
                                                               error:nil];
        
        if([json valueForKey:@"error"]){
            self.templateCreationFailureBlock(json);
            return;
        } else {
            [template setTemplate_id:[json valueForKey:@"id"]];
            self.templateCreationResultBlock(template, json);
        }
    }];
    [assemblyTask resume];
}

- (void) invokeAssembly: (Assembly *)assembly{
    [self checkAssembly:assembly];
    NSArray *files = [assembly files];
    
    for (int x = 0; x < [files count]; x++) {
        NSString* fileName = [[assembly fileNames] objectAtIndex:x];
        TUSResumableUpload *upload = [_tusSession createUploadFromFile:[files  objectAtIndex:x] headers:@{} metadata:@{@"filename":fileName, @"fieldname":@"file-input", @"assembly_url": [assembly urlString]}];
        upload.progressBlock = _uploadProgressBlock;
        upload.resultBlock = _uploadResultBlock;
        upload.failureBlock = _uploadFailureBlock;
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
        NSString* body = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:[body dataUsingEncoding:NSUTF8StringEncoding]
                                                             options:NSJSONReadingMutableContainers
                                                               error:nil];
        
        if([json valueForKey:@"error"]){
            self.assemblyCreationFailureBlock(json);
            return;
        } else {
            [assembly setUrlString: [json valueForKey:@"assembly_ssl_url"]];
              _tusSession = [[TUSSession alloc] initWithEndpoint:[[NSURL alloc] initWithString:[json valueForKey:@"tus_url"]] dataStore:_tusStore allowsCellularAccess:YES];
            self.assemblyCreationResultBlock(assembly, json);
            //return;
        }
    }];
    [assemblyTask resume];
}

- (void) checkAssembly: (Assembly *)assembly {
    NSTimer *timer = [NSTimer timerWithTimeInterval:1.0 repeats:true block:^(NSTimer * _Nonnull timer) {
        [self assemblyStatus:assembly completion:^(NSDictionary *response) {
            NSArray *responseArray = @[@"REQUEST_ABORTED", @"ASSEMBLY_CANCELED", @"ASSEMBLY_COMPLETED"];
            int responseInterger = [responseArray indexOfObject:[response valueForKey:@"ok"]];
            
            switch (responseInterger) {
                case 0:
                    //Aborted
                    [timer invalidate];
                    self.assemblyFailureBlock(response);
                    break;
                case 1:
                    //canceld
                    [timer invalidate];
                    self.assemblyFailureBlock(response);
                    break;
                case 2:
                    //completed
                    [timer invalidate];
                    self.assemblyResultBlock(response);
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
    NSMutableURLRequest *request = [[[TransloaditRequest alloc] initWithKey:_key andSecret:_secret] createGetRequestWithURL:[assembly urlString]];
    
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
            //
        }
        
        completion(json);
    }];
    [assemblyTask resume];
}
@end
