//
//  Transloadit.m
//  Transloadit
//
//  Created by Mark Masterson on 8/19/16.
//  Copyright © 2016 Mark R. Masterson. All rights reserved.
//

#import "Transloadit.h"
#import <CommonCrypto/CommonHMAC.h>

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


- (NSString*)generateSignature{
    NSError *error;
    NSDate *date = [[NSDate alloc] init];
    NSDateFormatter *dateFormatter=[[NSDateFormatter alloc]init];
    [dateFormatter setDateFormat:@"YYYY/MM/DD HH:mm:SS+00:00"];
    
    
    
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
        NSLog(hash);
        return hmacForKeyAndData(_secret, hash);
    }
}

- (void) createAssembly: (Assembly *)assembly{
    
    NSMutableURLRequest *request = [assembly createRequest];
    NSString *signature = [self generateSignature];
    NSLog(@"test hmac = %@",signature);
    [request setHTTPMethod:@"POST"];
    //[request setHTTPBody:[[[assembly params ]description] dataUsingEncoding:NSUTF8StringEncoding]];
    
    [_session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        //
    }];
    
    
    
}


NSData *hmacForKeyAndData(NSString *key, NSString *data)
{
    const char *cKey  = [key cStringUsingEncoding:NSASCIIStringEncoding];
    const char *cData = [data cStringUsingEncoding:NSASCIIStringEncoding];
    unsigned char cHMAC[CC_SHA256_DIGEST_LENGTH];
    CCHmac(kCCHmacAlgSHA256, cKey, strlen(cKey), cData, strlen(cData), cHMAC);
    return [[NSData alloc] initWithBytes:cHMAC length:sizeof(cHMAC)];
}




@end
