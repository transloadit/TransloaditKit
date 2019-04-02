//
//  APIObject.m
//  Pods
//
//  Created by Mark Masterson on 7/21/18.
//

#import "APIObject.h"

@implementation APIObject

- (id)init {
    self = [super init];
    if(self) {
    }
    return self;
}

- (NSMutableDictionary*) getParams {
    return [[NSDictionary alloc] init];
}
@end
