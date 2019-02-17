//
//  Transloadit.m
//  Transloadit
//
//  Created by Mark Masterson on 8/19/16.
//  Copyright © 2016 Mark R. Masterson. All rights reserved.
//

#import "Transloadit.h"
#import "Resources/API/APIObject.h"
#import "Resources/API//Template.h"
#import "Resources/API/Assembly.h"

@implementation Transloadit
@synthesize tus;
@synthesize tusStore;



- (id)init {
    self = [super init];
    if(self) {
        NSString* PLIST_KEY = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"TRANSLOADIT_KEY"];
        NSString* PLIST_SECRET = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"TRANSLOADIT_SECRET"];

        if (![PLIST_KEY isEqual:[NSNull null]] && ![PLIST_SECRET isEqual:[NSNull null]]) {
            _secret = PLIST_SECRET;
            _key = PLIST_KEY;
        }
        
        NSURL * applicationSupportURL = [[[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] firstObject];
//        tusStore = [[TUSFileUploadStore alloc] initWithURL:[applicationSupportURL URLByAppendingPathComponent:@"Example"]];
//        tus = [TUSResumableUpload alloc];
    }
    return self;
}

- (void)setDelegate: (_Nullable id<TransloaditDelegate>)tDelegate {
    if (_delegate != tDelegate) {
        _delegate = tDelegate;
    }
}


- (void)create:(id)object {
    if ([object isKindOfClass:[Assembly class]]) {
        [object setUrlString:[NSString stringWithFormat:@"%@%@%@", TRANSLOADIT_API_DEFAULT_PROTOCOL, TRANSLOADIT_API_DEFAULT_BASE_URL, TRANSLOADIT_API_ASSEMBLIES]];
    } else if([object isKindOfClass:[Template class]]) {
        [object setUrlString:[NSString stringWithFormat:@"%@%@%@", TRANSLOADIT_API_DEFAULT_PROTOCOL, TRANSLOADIT_API_DEFAULT_BASE_URL, TRANSLOADIT_API_TEMPLATES]];
    }

    [self makeRequestWithMethod:TRANSLOADIT_POST andObject:object callback:^(TransloaditResponse *json) {
        NSError *error = [[NSError alloc] init];
        if([json valueForKey:@"error"]){
            NSError *error = [NSError errorWithDomain:@"TRANSLOADIT"
                                                 code:-57
                                             userInfo:nil];
            if ([object isKindOfClass:[Assembly class]]) {
                [self.delegate transloaditAssemblyCreationError:NULL withResponse:json];
            } else if([object isKindOfClass:[Template class]]) {
                [self.delegate transloaditTemplateCreationError:error withResponse:json];
            }
            return;
        } else {
            if ([object isKindOfClass:[Assembly class]]) {
                [(Assembly *)object setUrlString: [json valueForKey:@"assembly_ssl_url"]];
                //                    _tusSession = [[TUSSession alloc] initWithEndpoint:[[NSURL alloc] initWithString:[json valueForKey:@"tus_url"]] dataStore:_tusStore allowsCellularAccess:YES];
                [self.delegate transloaditAssemblyCreationResult:object];
            } else if([object isKindOfClass:[Template class]]) {
                [(Template *)object setTemplate_id:[json valueForKey:@"id"]];
                [self.delegate transloaditTemplateCreationResult:object];
            }
        }
    }];
}

- (void) delete:(APIObject *) object {
    if ([[object urlString] isEqual:[NSNull null]]) {
        [self.delegate transloaditTemplateCreationError:nil withResponse:@{@"message":@"No URL Set"}];
    } else {
        [self makeRequestWithMethod:TRANSLOADIT_DELETE andObject:object callback:^(TransloaditResponse *json) {
            NSError *error = [[NSError alloc] init];
            if([json valueForKey:@"error"]){
                NSError *error = [NSError errorWithDomain:@"TRANSLOADIT"
                                                     code:-57
                                                 userInfo:nil];
                if ([object isKindOfClass:[Assembly class]]) {
                    [self.delegate transloaditAssemblyDeletionError:error withResponse:json];
                } else if([object isKindOfClass:[Template class]]) {
                    [self.delegate transloaditTemplateDeletionError:error withResponse:json];
                }
                return;
            } else {
                if ([object isKindOfClass:[Assembly class]]) {
                    [self.delegate transloaditAssemblyDeletionResult:object];
                } else if([object isKindOfClass:[Template class]]) {
                    [self.delegate transloaditTemplateDeletionResult:object];
                }
            }
        }];
    }
}

- (void) get:(APIObject *) object {
    if ([[object urlString] isEqual:[NSNull null]]) {
        [self.delegate transloaditTemplateCreationError:nil withResponse:@{@"message":@"No URL Set"}];
    } else {
        [self makeRequestWithMethod:TRANSLOADIT_GET andObject:object callback:^(TransloaditResponse *json) {
            NSError *error = [[NSError alloc] init];
            if([json valueForKey:@"error"]){
                NSError *error = [NSError errorWithDomain:@"TRANSLOADIT" code:-57 userInfo:nil];

                
                
                if ([object isKindOfClass:[Assembly class]]) {
                    [self.delegate transloaditAssemblyGetError:error withResponse:json];
                } else if([object isKindOfClass:[Template class]]) {
                    [self.delegate transloaditTemplateGetError:error withResponse:json];
                }
            
                return;
            } else {
                
                if ([object isKindOfClass:[Assembly class]]) {
                    [self.delegate transloaditAssemblyGetResult:object];
                } else if([object isKindOfClass:[Template class]]) {
                    [self.delegate transloaditTemplateGetResult:object];
                }
            }
        }];
    }
}

- (void) update: (APIObject *) object {
    [self makeRequestWithMethod:TRANSLOADIT_PUT andObject:object callback:^(TransloaditResponse *callback) {
        //callback;
    }];
}


- (void) invokeAssembly: (Assembly *)assembly{
    [self checkAssembly:assembly];
    NSArray *files = [assembly files];
    
    for (int x = 0; x < [files count]; x++) {
        NSString* fileName = [[assembly fileNames] objectAtIndex:x];
//        TUSResumableUpload *upload = [_tusSession createUploadFromFile:[files  objectAtIndex:x] headers:@{} metadata:@{@"filename":fileName, @"fieldname":@"file-input", @"assembly_url": [assembly urlString]}];
//        upload.progressBlock = _uploadProgressBlock;
//        upload.resultBlock = _uploadResultBlock;
//        upload.failureBlock = _uploadFailureBlock;
//        [upload resume];
    }
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
                    [self.delegate transloaditAssemblyProcessError:nil withResponse:nil];
                    break;
                case 1:
                    //canceld
                    [timer invalidate];
                    self.assemblyFailureBlock(response);
                    [self.delegate transloaditAssemblyProcessError:nil withResponse:nil];
                    break;
                case 2:
                    //completed
                    [timer invalidate];
                    self.assemblyResultBlock(response);
                    [self.delegate transloaditAssemblyProcessResult:nil];
                default:
                    break;
            }
            
            if ([[response valueForKey:@"error"] isEqualToString:@"ASSEMBLY_CRASHED"]) {
                
            }
        }];
    }];
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
}

- (void) makeRequestWithMethod:(NSString *)method andObject:(APIObject *) object callback:(void(^)(TransloaditResponse *))callback {
    NSLog(@"%@", [object urlString]);
    TransloaditRequest *request = [[TransloaditRequest alloc] initWith:_key andSecret:_secret andMethod:method andURL:[object urlString]];
    if ([[request method] isEqualToString:TRANSLOADIT_POST] || [[request method] isEqualToString:TRANSLOADIT_PUT]) {
        [request appendParams:[object getParams]];
    }
    
    NSURLSessionDataTask *assemblyTask = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            NSLog(@"%@", [error debugDescription]);
            return;
        }
        NSString* body = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:[body dataUsingEncoding:NSUTF8StringEncoding]
                                                             options:NSJSONReadingMutableContainers
                                                               error:nil];
        TransloaditResponse *responseObject = [[TransloaditResponse alloc] initWithResponseDictionary:json];
        callback(responseObject);
    }];
    [assemblyTask resume];
}

- (void) assemblyStatus: (Assembly *)assembly completion:(void (^)(NSDictionary *))completion {
    NSMutableURLRequest *request = [[[TransloaditRequest alloc] initWithKey:_key andSecret:_secret] createRequestWithMethod:TRANSLOADIT_GET andURL:[assembly urlString]];
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

//__deprecated
-(void) createAssembly:(id)assembly {

}
-(void) createTemplate:(id)template {

}



@end
