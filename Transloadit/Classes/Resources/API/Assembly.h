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

@property (nonatomic, strong)NSMutableArray<AssemblyStep *>* stepsArray;

@property (nonatomic, strong)NSMutableArray<NSURL *>* files;

@property (nonatomic, strong)NSString* stepsJSONString;

@property (nonatomic, strong)NSString* template_id;

@property (nonatomic)int* numberOfFiles;


@property (nonatomic, strong)NSDate* expireDate;

- (id)initWithSteps:(NSMutableArray<AssemblyStep *>*)steps andNumberOfFiles:(int)numberOfFiles;

- (id)initWithStepsJSONString:(NSString *)steps andNumberOfFiles:(int)numberOfFiles;

//MARK: Steps
- (void)addStepWithAssemblyStep:(AssemblyStep *)step;

- (void)addStepWithJSONString:(NSString *)step;

-(NSMutableDictionary *)getSteps;


-(void)setExpirationWithMinutes:(int)minutes;

//MARK: Files
- (void)addFile:(NSURL* )file;

-(int)fileCount;


@end
