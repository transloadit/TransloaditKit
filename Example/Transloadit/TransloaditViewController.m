//
//  TransloaditViewController.m
//  Transloadit
//
//  Created by Mark R. Masterson on 08/30/2016.
//  Copyright (c) 2016 Mark R. Masterson. All rights reserved.
//

#import "TransloaditViewController.h"
#import <Transloadit/Transloadit.h>
#import <Photos/Photos.h>


@interface TransloaditViewController () <TransloaditDelegate>
@end


// MARK: Your Tansloadit Progress Blocks
static TransloaditUploadProgressBlock progressBlock = ^(int64_t bytesWritten, int64_t bytesTotal){
    // Update your progress bar here
    NSLog(@"progress: %llu / %llu", (unsigned long long)bytesWritten, (unsigned long long)bytesTotal);
};

static TransloaditUploadResultBlock resultBlock = ^(NSURL* fileURL){
    // Use the upload url
    NSLog(@"url: %@", fileURL);
};

static TransloaditUploadFailureBlock failureBlock = ^(NSError* error){
    // Handle the error
    NSLog(@"error: %@", error);
};


@implementation TransloaditViewController

Transloadit *transloadit;
Assembly *testAssembly;

- (void)viewDidLoad {
    [super viewDidLoad];
    transloadit = [[Transloadit alloc] init];
// Blocks have been depreciated
//    transloadit.uploadFailureBlock = failureBlock;
//    transloadit.uploadProgressBlock = progressBlock;
//    transloadit.uploadResultBlock = resultBlock;
    
    [transloadit setDelegate:self];
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"test" ofType:@"jpg"];
    
    NSMutableArray<Step *> *steps = [[NSMutableArray alloc] init];
    
    Step *step1 = [[Step alloc] initWithKey:@"encode"];
    [step1 setValue:@"75" forOption:@"width"];
    [step1 setValue:@"75" forOption:@"height"];
    [step1 setValue:@"/image/resize" forOption:@"robot"];
    [steps addObject:step1];
    
    
//    Template *newTemplate = [[Template alloc] initWithSteps:steps andName:@"New templates"];
//    Assembly *newAssembly = [[Assembly alloc] initWithSteps:steps andNumberOfFiles:1];
//    [transloadit create:newAssembly];
    
    Template *newTemplate = [[Template alloc] initWithTemplateId:@"d3d774803a5311e9b4f8bd2d638915d1"];
    
    Assembly *newAssembly = [[Assembly alloc] initWithId:@"49a2f4603a5811e992bf77da2e974230"];
    [transloadit delete:newAssembly];
}


- (void) transloaditAssemblyCreationError:(NSError *)error withResponse:(TransloaditResponse *)response {
    NSLog(@"%@", [response debugDescription]);
}

// DELEGATE
- (void) transloaditTemplateCreationResult:(Template *)template {
    NSLog(@"%@", @"Created Template");
}

- (void) transloaditTemplateCreationError:(NSError *)error withResponse:(TransloaditResponse *)response {
    NSLog(@"%@", @"Failed Creating Template");

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
