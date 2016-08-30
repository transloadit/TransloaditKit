//
//  APIObject.h
//  
//
//  Created by Mark Masterson on 8/30/16.
//
//

#import <Foundation/Foundation.h>

@interface APIObject : NSObject

@property (nonatomic, strong)NSMutableURLRequest* callRequest;

- (NSURLRequest*)buildRequest;

@end
