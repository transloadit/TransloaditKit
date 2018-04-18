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
#import "Template.h"

@protocol APIObject <NSObject>

@property (nonatomic, assign)APIObjectType* type;

@property (nonatomic, strong)NSMutableURLRequest* callRequest;

@property (nonatomic, strong)NSDictionary* params;

@property (nonatomic, strong)NSData* data;


- (NSString*)buildParametersJSON;

@end
