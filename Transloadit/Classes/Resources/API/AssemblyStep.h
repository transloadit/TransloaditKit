//
//  AssemblyStep.h
//  Transloadit
//
//  Created by Mark Masterson on 8/19/16.
//  Copyright © 2016 Mark R. Masterson. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AssemblyStep : NSObject

@property(nonatomic, strong)NSString* operationName;

@property(nonatomic, strong)NSMutableDictionary* bodyOperations;


-(id)initWithOperationName:(NSString *)name andBodyOperations:(NSMutableDictionary *)bodyOperations;

-(NSString *)asJSON;

@end
