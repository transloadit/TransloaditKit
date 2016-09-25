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
   Transloadit *transloadit = [[Transloadit alloc] initWithKey:@"5ae6b9c0f10c11e594a0bfa14ca2ffe1" andSecret:@"a9d351b355bb47b21af79d89aa9d8a54a6f27a41"];
 
    
    NSMutableArray<AssemblyStep *> *steps = [[NSMutableArray alloc] init];
    
    AssemblyStep *step1 = [[AssemblyStep alloc] init];
    [step1 setValue:@"/image/resize" forOption:@"robot"];
    
    [steps addObject:step1];
    Assembly *TestAssemblyWithSteps = [[Assembly alloc] initWithSteps:steps andNumberOfFiles:1];
    
    [TestAssemblyWithSteps setNotify_url:@""];

    
    
  //  [transloadit createAssembly:TestAssemblyWithSteps];
    [transloadit createAssembly:TestAssemblyWithSteps];

    
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
