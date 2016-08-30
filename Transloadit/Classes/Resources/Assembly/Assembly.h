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

- (id)initWithID:(NSString *)assembly_id;

- (id)initWithSteps:(AssemblyStep *)steps;



@end
