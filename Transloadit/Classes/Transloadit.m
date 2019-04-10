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
@synthesize tusSession;


/**
 Init Transloadit

 @return Main Transloadit object
 */
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
        tusStore = [[TUSFileUploadStore alloc] initWithURL:[applicationSupportURL URLByAppendingPathComponent:@"Example"]];
        tus = [TUSResumableUpload alloc];
    }
    return self;
}

/**
 Set the delegate for Transloadit

 @param tDelegate the location of the delegate callbacks
 */
- (void)setDelegate: (_Nullable id<TransloaditDelegate>)tDelegate {
    if (_delegate != tDelegate) {
        _delegate = tDelegate;
    }
}


/**
 Create a Template or Assembly

 @param object A Template or Assembly object
 */
- (void)create:(id)object {
    if ([object isKindOfClass:[Assembly class]]) {
        [object setUrlString:[NSString stringWithFormat:@"%@%@%@", TRANSLOADIT_API_DEFAULT_PROTOCOL, TRANSLOADIT_API_DEFAULT_BASE_URL, TRANSLOADIT_API_ASSEMBLIES]];
    } else if([object isKindOfClass:[Template class]]) {
        [object setUrlString:[NSString stringWithFormat:@"%@%@%@", TRANSLOADIT_API_DEFAULT_PROTOCOL, TRANSLOADIT_API_DEFAULT_BASE_URL, TRANSLOADIT_API_TEMPLATES]];
    }

    [self makeRequestWithMethod:TRANSLOADIT_POST andObject:object callback:^(TransloaditResponse *json) {
        if([[json dictionary] valueForKey:@"error"]){
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
                [(Assembly *)object setUrlString: [[json dictionary] valueForKey:@"assembly_ssl_url"]];
                tusSession = [[TUSSession alloc] initWithEndpoint:[[NSURL alloc] initWithString:[[json dictionary] valueForKey:@"tus_url"]] dataStore:tusStore allowsCellularAccess:YES];
                [self.delegate transloaditAssemblyCreationResult:object];
            } else if([object isKindOfClass:[Template class]]) {
                [(Template *)object setTemplate_id:[[json dictionary] valueForKey:@"id"]];
                [self.delegate transloaditTemplateCreationResult:object];
            }
        }
    }];
}

/**
 Delete a Template or stop an Assembly

 @param object A Template or Assembly object
 */
- (void) delete:(id) object {
    if ([[object urlString] isEqual:[NSNull null]]) {
        [self.delegate transloaditTemplateCreationError:nil withResponse:[[TransloaditResponse alloc] initWithResponseDictionary:@{@"message":@"No URL Set"}]];
    } else {
        [self makeRequestWithMethod:TRANSLOADIT_DELETE andObject:object callback:^(TransloaditResponse *json) {
//            if([json valueForKey:@"error"]){
//                NSError *error = [NSError errorWithDomain:@"TRANSLOADIT"
//                                                     code:-57
//                                                 userInfo:nil];
//                if ([object isKindOfClass:[Assembly class]]) {
//                    [self.delegate transloaditAssemblyDeletionError:error withResponse:json];
//                } else if([object isKindOfClass:[Template class]]) {
//                    [self.delegate transloaditTemplateDeletionError:error withResponse:json];
//                }
//                return;
//            } else {
//                if ([object isKindOfClass:[Assembly class]]) {
//                    [self.delegate transloaditAssemblyDeletionResult:object];
//                } else if([object isKindOfClass:[Template class]]) {
//                    [self.delegate transloaditTemplateDeletionResult:object];
//                }
//            }
        }];
    }
}

/**
 Get a Template or Assembly

 @param object A Template or Assembly object - all you need is the id's set to retreive a full object
 */
- (void) get:(id) object {
    if ([[object urlString] isEqual:[NSNull null]]) {
        [self.delegate transloaditTemplateCreationError:nil withResponse:[[TransloaditResponse alloc] initWithResponseDictionary:@{@"message":@"No URL Set"}]];
    } else {
        [self makeRequestWithMethod:TRANSLOADIT_GET andObject:object callback:^(TransloaditResponse *json) {
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

/**
 Update a Template or Assembly

 @param object A Template or Assembly
 */
- (void) update: (APIObject *) object {
    [self makeRequestWithMethod:TRANSLOADIT_PUT andObject:object callback:^(TransloaditResponse *callback) {
        //callback;
    }];
}


/**
 Start the upload and assebmly steps

 @param assembly Assembly you wish to invoke
 @param retryCount number of times you'd like to try before failing out.
 */
- (void) invokeAssembly: (Assembly *)assembly retry:(int)retryCount{
    [self checkAssembly:assembly];
    NSArray *files = [assembly files];
    
    for (int x = 0; x < [files count]; x++) {
        NSString* fileName = [[assembly fileNames] objectAtIndex:x];
        TUSResumableUpload *upload = [tusSession createUploadFromFile:[files  objectAtIndex:x] retry:retryCount headers:@{} metadata:@{@"filename":fileName, @"fieldname":@"file-input", @"assembly_url": [assembly urlString]}];
        upload.progressBlock = _uploadProgressBlock;
        upload.resultBlock = _uploadResultBlock;
        upload.failureBlock = _uploadFailureBlock;
        [upload resume];
    }
}

/**
 Get the current status of your Assembly

 @param assembly The assembly object you wish to check
 */
- (void) checkAssembly: (Assembly *)assembly {
    if (@available(iOS 10.0, *)) {
        NSTimer *timer = [NSTimer timerWithTimeInterval:1.0 repeats:true block:^(NSTimer * _Nonnull timer) {
            [self assemblyStatus:assembly completion:^(NSDictionary *response) {
                NSArray *responseArray = @[@"REQUEST_ABORTED", @"ASSEMBLY_CANCELED", @"ASSEMBLY_COMPLETED"];
                int responseInterger = [responseArray indexOfObject:[response valueForKey:@"ok"]];
                
                switch (responseInterger) {
                        case 0:
                        //Aborted
                        [timer invalidate];
                        //                    self.assemblyFailureBlock(response);
                        [self.delegate transloaditAssemblyProcessError:nil withResponse:nil];
                        break;
                        case 1:
                        //canceld
                        [timer invalidate];
                        //                    self.assemblyFailureBlock(response);
                        [self.delegate transloaditAssemblyProcessError:nil withResponse:nil];
                        break;
                        case 2:
                        //completed
                        [timer invalidate];
                        //                    self.assemblyResultBlock(response);
                        TransloaditResponse *responseObject = [[TransloaditResponse alloc] initWithResponseDictionary:response];
                        [self.delegate transloaditAssemblyProcessResult:responseObject];
                        break;
                }
                
                if ([[response valueForKey:@"error"] isEqualToString:@"ASSEMBLY_CRASHED"]) {
                    
                }
            }];
        }];
        [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
    } else {
        // Fallback on earlier versions
    }
}

#pragma mark Private methods

/**
 The method used to make API calls to Transloadit

 @param method The method of the request
 @param object The Template or Assembly object you wish to pass
 @param callback The callback containing the response from the server
 */
- (void) makeRequestWithMethod:(NSString *)method andObject:(id) object callback:(void(^)(TransloaditResponse *))callback {
    
    TransloaditRequest *request;

    if ([method  isEqual: TRANSLOADIT_DELETE]) {
        NSString *url;
        if ([object isKindOfClass:[Template class]]) {
            url = [NSString stringWithFormat:@"%@%@%@%@%@", TRANSLOADIT_API_DEFAULT_PROTOCOL, TRANSLOADIT_API_DEFAULT_BASE_URL, TRANSLOADIT_API_TEMPLATES, @"/", [object template_id]];
        }
        if ([object isKindOfClass:[Assembly class]]) {
            url = [NSString stringWithFormat:@"%@%@%@%@%@", TRANSLOADIT_API_DEFAULT_PROTOCOL, TRANSLOADIT_API_DEFAULT_BASE_URL, TRANSLOADIT_API_ASSEMBLIES, @"/", [object id]];
        }

         request = [[TransloaditRequest alloc] initWith:_key andSecret:_secret andMethod:method andURL:url];

    }else if ([method  isEqual: TRANSLOADIT_POST]) {
        request = [[TransloaditRequest alloc] initWith:_key andSecret:_secret andMethod:method andURL:[object urlString]];
        
    }
//    if ([[request method] isEqualToString:TRANSLOADIT_POST] || [[request method] isEqualToString:TRANSLOADIT_PUT]) {
        [request appendParams:[object getParams]];
//    }
    NSLog(@"%@", [request debugDescription]);
    NSLog(@"%@", [[object getParams] debugDescription]);
    
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

/**
 The private method to check the assembly status

 @param assembly The Assembly you wish to check
 @param completion The callback from the server containing the server response
 */
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
        }
        completion(json);
    }];
    [assemblyTask resume];
}

// MARK: Your Tansloadit Progress Blocks
static TransloaditUploadProgressBlock progressBlock = ^(int64_t bytesWritten, int64_t bytesTotal){
    // Update your progress bar here
    NSLog(@"progress: %llu / %llu", (unsigned long long)bytesWritten, (unsigned long long)bytesTotal);
};

static TransloaditUploadResultBlock resultBlock = ^(NSURL* fileURL){
    // Use the upload url
    NSLog(@"url: %@", fileURL);
};

static TransloaditUploadFailureBlock failureBlock = ^(NSError* error){
    // Handle the error
    NSLog(@"error: %@", error);
};


//__deprecated
-(void) createAssembly:(id)assembly {
    
}
-(void) createTemplate:(id)template {
    
}

@end
