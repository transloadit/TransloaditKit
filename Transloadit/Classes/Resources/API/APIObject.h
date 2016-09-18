//
//  APIObject.h
//  
//
//  Created by Mark Masterson on 8/30/16.
//
//

#import <Foundation/Foundation.h>

typedef enum : NSUInteger {
    CREATE = 0,
    STATUS = 1,
} APIState;


@protocol APIObject <NSObject>


@property (nonatomic, strong)NSMutableURLRequest* callRequest;

@property (nonatomic, strong)NSString* params;

- (NSURLRequest*)buildRequestFor:(APIState *)state;

- (NSString*)buildParametersJSON;


@end
