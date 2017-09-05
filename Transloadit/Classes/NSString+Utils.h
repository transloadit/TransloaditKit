//
//  NSString+Utils.h
//  Pods
//
//  Created by Mark Masterson on 9/18/16.
//
//

#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonCrypto.h>

@interface NSString (Utils)

-(NSString *)signWithKey:(NSString *)key;

@end
