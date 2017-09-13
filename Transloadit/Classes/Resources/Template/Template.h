//
//  Template.h
//  Transloadit
//
//  Created by Mark Masterson on 8/19/16.
//  Copyright © 2016 Mark R. Masterson. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "APIObject.h"

@interface Template : NSObject

@property (nonatomic, strong)NSString* template_id;

@property (nonatomic, strong)NSString* name;


@property (nonatomic, strong)NSMutableArray<Step *>* stepsArray;


- (id)initWithTemplateId:(NSString *)template_id;

- (id)initWithSteps:(NSMutableArray<Step *>*)steps andName: (NSString *)name;

-(NSMutableDictionary *)getSteps;

@end
