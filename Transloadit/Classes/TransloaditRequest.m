//
//  TransloaditRequest.m
//  Arcane-iOS
//
//  Created by Mark Masterson on 10/4/17.
//

#import "TransloaditRequest.h"
#import "Resources/TransloaditConstants.h"
@import MobileCoreServices;    // only needed in iOS

@implementation TransloaditRequest


-(id)initWithKey:(NSString *)key andSecret:(NSString *)secret {
    self = [super init];
    if(self) {
        _key = key;
        _secret = secret;
    }
    return self;
}

- (id) initWith:(NSString *)key andSecret:(NSString *)secret andMethod:(NSString *)method andURL:(NSString *) url {
    self = [super init];
    if(self) {
        _key = key;
        _secret = secret;
        _method = method;
        [self setURL:[[NSURL alloc] initWithString:[NSString stringWithFormat:@"%@", url]]];
        [self setCachePolicy:NSURLRequestReturnCacheDataElseLoad];
        [self setTimeoutInterval:120.0];
        [self addValue:@"application/json" forHTTPHeaderField:@"Accept"];
        [self addValue:TRANSLOADITKIT_VERSION forHTTPHeaderField:@"Transloadit-Client"];

        [self setHTTPMethod:method];
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

- (void) appendParams:(NSMutableDictionary *) params {
    [params setObject:[self createAuth] forKey:@"auth"];
    NSString *signature = [self generateSignatureWithParams: params];
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    NSData * jsonData = [NSJSONSerialization dataWithJSONObject:params options:0 error:nil];
    NSString * jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    [parameters setObject:jsonString forKey:@"params"];
    [parameters setObject:signature forKey:@"signature"];
    [parameters setObject:@"1" forKey:@"tus_num_expected_upload_files"];

    NSString *boundary = [self generateBoundaryString];
    NSData *body2 = [self createBodyWithBoundary:boundary parameters:parameters paths:nil fieldName:nil];
    
    
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary];
    [self setValue:contentType forHTTPHeaderField: @"Content-Type"];
    
    [self setHTTPBody:body2];

    
}


- (NSData *)createBodyWithBoundary:(NSString *)boundary
                        parameters:(NSDictionary *)parameters
                             paths:(NSArray *)paths
                         fieldName:(NSString *)fieldName {
    NSMutableData *httpBody = [NSMutableData data];
    
    // add params (all params are strings)

    [parameters enumerateKeysAndObjectsUsingBlock:^(NSString *parameterKey, NSString *parameterValue, BOOL *stop) {
        NSLog(@"Setting %@ with value %@", parameterKey, parameterValue);
        [httpBody appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [httpBody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", parameterKey] dataUsingEncoding:NSUTF8StringEncoding]];
        [httpBody appendData:[[NSString stringWithFormat:@"%@\r\n", parameterValue] dataUsingEncoding:NSUTF8StringEncoding]];
    }];
    
    [httpBody appendData:[[NSString stringWithFormat:@"--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    
    return httpBody;
}

- (NSString *)mimeTypeForPath:(NSString *)path {
    // get a mime type for an extension using MobileCoreServices.framework
    
    CFStringRef extension = (__bridge CFStringRef)[path pathExtension];
    CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, extension, NULL);
    assert(UTI != NULL);
    
    NSString *mimetype = CFBridgingRelease(UTTypeCopyPreferredTagWithClass(UTI, kUTTagClassMIMEType));
    assert(mimetype != NULL);
    
    CFRelease(UTI);
    
    return mimetype;
}

- (NSString *)generateBoundaryString {
    return [NSString stringWithFormat:@"Boundary-%@", [[NSUUID UUID] UUIDString]];
}


@end
