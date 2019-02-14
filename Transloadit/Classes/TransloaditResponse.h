//
//  TransloaditResponse.h
//  Pods
//
//  Created by Mark Masterson on 7/3/18.
//

#import <Foundation/Foundation.h>

@interface TransloaditResponse : NSObject

@property (nonatomic, strong) NSDictionary * _Nonnull dictionary;

- (id)initWithResponseDictionary:(NSDictionary *)responseDictionary;

@end
