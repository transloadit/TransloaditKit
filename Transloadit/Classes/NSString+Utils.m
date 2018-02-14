//
//  NSString+Utils.m
//  Pods
//
//  Created by Mark Masterson on 9/18/16.
//
//

#import "NSString+Utils.h"

@implementation NSString (Utils)

- (NSString *)signWithKey:(NSString *)key {
    NSData *clearTextData = [self dataUsingEncoding:NSUTF8StringEncoding];
    NSData *keyData = [key dataUsingEncoding:NSUTF8StringEncoding];
    uint8_t digest[CC_SHA1_DIGEST_LENGTH] = {0};
    CCHmacContext hmacContext;
    CCHmacInit(&hmacContext, kCCHmacAlgSHA1, keyData.bytes, keyData.length);
    CCHmacUpdate(&hmacContext, clearTextData.bytes, clearTextData.length);
    CCHmacFinal(&hmacContext, digest);

    return [NSString stringWithHexBytes:[NSData dataWithBytes:digest length:CC_SHA1_DIGEST_LENGTH]];
}

+ (NSString *)stringWithHexBytes:(NSData *)data {
    static const char hexdigits[] = "0123456789abcdef";
    const size_t numBytes = [data length];
    const unsigned char* bytes = [data bytes];
    char *strbuf = (char *)malloc(numBytes * 2 + 1);
    char *hex = strbuf;
    NSString *hexBytes = nil;

    for (int i = 0; i<numBytes; ++i) {
        const unsigned char c = *bytes++;
        *hex++ = hexdigits[(c >> 4) & 0xF];
        *hex++ = hexdigits[(c ) & 0xF];
    }
    *hex = 0;
    hexBytes = [NSString stringWithUTF8String:strbuf];
    free(strbuf);
    return hexBytes;
}

@end
