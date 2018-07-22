//
//  TransloaditRequest.m
//  Arcane-iOS
//
//  Created by Mark Masterson on 10/4/17.
//

#import "TransloaditRequest.h"

@implementation TransloaditRequest


-(id)initWithKey:(NSString *)key andSecret:(NSString *)secret {
    self = [super init];
    if(self) {
        _key = key;
        _secret = secret;
    }
    return self;
}

- (NSString*)generateSignatureWithParams:(NSDictionary *)params {
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:params
                                                       options:0
                                                         error:&error];
    if (!jsonData) {
        NSLog(@"Got an error: %@", error);
        return nil;
    } else {
        NSString *hash = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        return [hash signWithKey:_secret];
    }
}

-(NSString *)currentGMTTime{
    NSDateFormatter *dateFormatter=[[NSDateFormatter alloc]init];
    NSTimeZone *timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
    [dateFormatter setTimeZone:timeZone];
    [dateFormatter setDateFormat:@"YYYY/MM/dd HH:mm:s+00:00"];
    
    return [dateFormatter stringFromDate:[[NSDate alloc] initWithTimeIntervalSinceNow:5*60]];
}

- (NSMutableDictionary *) createAuth{
    NSMutableDictionary *auth = [[NSMutableDictionary alloc] init];
    [auth setObject:_key forKey:@"key"];
    [auth setObject:[self currentGMTTime] forKey:@"expires"];
    
    return auth;
}

- (NSString *) generateBoundary {
    return [[NSUUID UUID] UUIDString];
}

- (NSMutableURLRequest *) createRequestWithMethod:(NSString *)method andURL:(NSString *) url {
    _method = method;
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[[NSURL alloc] initWithString:[NSString stringWithFormat:@"%@", url]] cachePolicy: NSURLRequestReturnCacheDataElseLoad timeoutInterval:120.0];
    [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setHTTPMethod:method];
    return request;
}

- (void) appendParams:(NSMutableDictionary *) params {
    [params setObject:[self createAuth] forKey:@"auth"];
    NSString *signature = [self generateSignatureWithParams: params];
    
    NSString *boundary = [self generateBoundary];
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@ ", boundary];
    [self addValue:contentType forHTTPHeaderField:@"Content-Type"];
    NSMutableData *body = [NSMutableData data];
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:params options:0 error:nil];
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"tus_num_expected_upload_files\"\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    int i = 2;
    NSData *intData = [NSData dataWithBytes: &i length: sizeof(i)];
    [body appendData:[@"1" dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"signature\"\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[signature dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"params\"\r\n\r\n%@",  [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding]] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [self setHTTPBody:body];
}




@end
