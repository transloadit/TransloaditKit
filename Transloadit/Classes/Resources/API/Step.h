//
//  Step.h
//  Transloadit
//
//  Created by Mark Masterson on 8/19/16.
//  Copyright © 2016 Mark R. Masterson. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Step : NSObject

@property(nonatomic, strong)NSString* key;

@property(nonatomic, strong)NSDictionary* options;


-(id)initWithKey:(NSString *)key;

-(void)setValue:(NSString *)value forOption:(NSString *)option;


@end
