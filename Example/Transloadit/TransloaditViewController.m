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
  //  Transloadit *T = [[Transloadit alloc] initWithKey:@"" andSecret:@""];
    
    NSDictionary *params = [[NSDictionary alloc] init];
    
 //   [T perfromAssebmly:[[Assembly alloc] initWithParams:params]];
    
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
