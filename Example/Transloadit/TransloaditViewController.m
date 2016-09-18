//
//  TransloaditViewController.m
//  Transloadit
//
//  Created by Mark R. Masterson on 08/30/2016.
//  Copyright (c) 2016 Mark R. Masterson. All rights reserved.
//

#import "TransloaditViewController.h"
#import <Transloadit/Transloadit.h>

@interface TransloaditViewController ()

@end

@implementation TransloaditViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
   Transloadit *T = [[Transloadit alloc] initWithKey:@"5ae6b9c0f10c11e594a0bfa14ca2ffe1" andSecret:@" a9d351b355bb47b21af79d89aa9d8a54a6f27a41"];
    
    //NSDictionary* params = @{};
    
    NSMutableArray<AssemblyStep *> *steps = [[NSMutableArray alloc] init];
    
    AssemblyStep *step = [[AssemblyStep alloc] initWithOperationName:@"encode" andBodyOperations:@{@"use":@"orignal", @"robot":@"/video/encode", @"result":@"true"}];
    
    Assembly *A = [[Assembly alloc] initWithSteps:steps andNumberOfFiles:1];
    
    
    
    
    [T createAssembly:A];
    
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
