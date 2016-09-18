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
    
    [_session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        //
    }];
    
    
    
}





@end
