//
//  TransloaditDelegate.h
//  Pods
//
//  Created by Mark Masterson on 5/6/18.
//

#import <Foundation/Foundation.h>
#import "Resources/API/Assembly.h"

@protocol TransloaditDelegate <NSObject>

@optional
- (void) transloaditAssemblyCreationResult:(Assembly *)assembly completionDictionary:(NSDictionary *)completionDictionary;
@optional
- (void) transloaditAssemblyCreationFailure:(NSDictionary *)completionDictionary;

@optional
- (void) transloaditAssemblyStatus:(NSDictionary *)completionDictionary;
@optional
- (void) transloaditAssemblyResult:(NSDictionary *)completionDictionary;
@optional
- (void) transloaditAssemblyFailure:(NSDictionary *)completionDictionary;


@end
