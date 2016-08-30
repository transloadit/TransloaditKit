//
//  Assembly.h
//  Transloadit
//
//  Created by Mark Masterson on 8/19/16.
//  Copyright © 2016 Mark R. Masterson. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AssemblyStep.h"
#import <Transloadit.h>

@interface Assembly : APIObject

@property (nonatomic, strong)NSString* urlString;

@property (nonatomic, strong)NSString* assemblyID;


- (id)initWithID:(NSString *)assembly_id;

- (id)initWithSteps:(AssemblyStep *)steps;

- (id)createWithParams:(NSString *)params andSteps:(NSArray*)steps andTemplateID:(NSString*)templateID andNotifyURL:(NSURL *)notifyURL;




@end
