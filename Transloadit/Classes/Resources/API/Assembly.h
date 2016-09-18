//
//  Assembly.h
//  Transloadit
//
//  Created by Mark Masterson on 8/19/16.
//  Copyright © 2016 Mark R. Masterson. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "APIObject.h"


@interface Assembly : NSObject<APIObject>

@property (nonatomic, strong)NSString* urlString;

@property (nonatomic, strong)NSString* notify_url;

@property (nonatomic, strong)NSMutableArray* steps;


@property (nonatomic, strong)NSString* template_id;

@property (nonatomic)int* numberOfFiles;


- (id)init;

- (id)initWithSteps:(NSMutableArray<AssemblyStep *>*)steps andNumberOfFiles:(int)numberOfFiles;

- (void)addStep:(AssemblyStep *)step;




@end
