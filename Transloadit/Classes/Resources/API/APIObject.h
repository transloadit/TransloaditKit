//
//  APIObject.h
//  
//
//  Created by Mark Masterson on 8/30/16.
//
//

#import <Foundation/Foundation.h>
#import "TransloaditResponse.h"
#import "APIState.h"
#import "APIObjectType.h"
#import "URLConstants.h"
#import "AssemblyStep.h"

@protocol APIObject <NSObject>

@property (nonatomic, assign)APIObjectType* type;


@property (nonatomic, strong)NSMutableURLRequest* callRequest;

@property (nonatomic, strong)NSDictionary* params;

@property (nonatomic, strong)NSData* data;

- (NSURLRequest*)createRequestWithSignature:(NSString *)signature;

- (NSString*)buildParametersJSON;

//- (NSString*)getParams;



@end
