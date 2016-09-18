//
//  AssemblyStep.h
//  Transloadit
//
//  Created by Mark Masterson on 8/19/16.
//  Copyright © 2016 Mark R. Masterson. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AssemblyStep : NSObject

@property(nonatomic, strong)NSString* name;

@property(nonatomic, strong)NSMutableDictionary* operation;


@end
