//
//  APIObject.h
//  
//
//  Created by Mark Masterson on 8/30/16.
//
//

#import <Foundation/Foundation.h>
#import "APIState.h"
#import "APIObjectType.h"
#import "URLConstants.h"
#import "Step.h"

@interface APIObject : NSObject

@property (nonatomic, assign)APIObjectType apiType;

@property (nonatomic, strong)NSString* id;

@property (nonatomic, strong)NSMutableURLRequest* callRequest;

@property (nonatomic, strong)NSMutableDictionary* params;

@property (nonatomic, strong)NSData* data;

@property (nonatomic, strong)NSString* urlString;

- (id)init;

- (NSMutableDictionary*) getParams;

@end
