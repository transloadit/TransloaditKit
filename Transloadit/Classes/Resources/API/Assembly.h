//
//  Assembly.h
//  Transloadit
//
//  Created by Mark Masterson on 8/19/16.
//  Copyright © 2016 Mark R. Masterson. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "APIObject.h"
#import "Template.h"

@interface Assembly : APIObject

@property (nonatomic, strong)NSString* id;

@property (nonatomic, strong)NSString* notify_url;

@property (nonatomic, strong)NSMutableArray<Step *>* stepsArray;

@property (nonatomic, strong)NSMutableArray<NSURL *>* files;
@property (nonatomic, strong)NSMutableArray<NSString *>* fileNames;


@property (nonatomic, strong)NSString* stepsJSONString;

@property (nonatomic, strong)Template* template;

@property (nonatomic)int* numberOfFiles;


- (id)initWithSteps:(NSMutableArray<Step *>*)steps andNumberOfFiles:(int)numberOfFiles;

- (id)initWithStepsJSONString:(NSString *)steps andNumberOfFiles:(int)numberOfFiles;

- (id)initWithTemplate:(Template *)template andNumberOfFiles:(int)numberOfFiles;

- (id)initWithId:(NSString* )id;

//MARK: Steps
- (void)addStepWithStep:(Step *)step;

-(NSMutableDictionary *)getSteps;


-(void)setExpirationWithMinutes:(int)minutes;

//MARK: Files
- (void)addFile:(NSURL* )file andFileName:(NSString* ) fileName;

-(int)fileCount;


@end
