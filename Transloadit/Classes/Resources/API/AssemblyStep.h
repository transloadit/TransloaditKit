//
//  AssemblyStep.h
//  Transloadit
//
//  Created by Mark Masterson on 8/19/16.
//  Copyright © 2016 Mark R. Masterson. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AssemblyStep : NSObject

@property(nonatomic, strong)NSDictionary* options;

-(id)init;

-(void)setValue:(NSString *)value forOption:(NSString *)option;


@end
