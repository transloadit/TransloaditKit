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
    
    //
    //        // Add the step to the array
    [steps addObject:step1];
    
    testAssembly = [[Assembly alloc] initWithSteps:steps andNumberOfFiles:1];

    
    //MARK: We then create an Assembly Object with the steps and files
    [testAssembly addFile:[NSURL fileURLWithPath:path] andFileName:@"file.jpg"];
    
    //CRUD Operations
    //    [transloadit get: testAssembly];
    //    [transloadit update: testAssembly];
    //    [transloadit delete: testAssembly];
    
    transloadit.assemblyCreationResultBlock = ^(Assembly* assembly, NSDictionary* completionDictionary){
        NSLog(@"Assembly creation success");
        NSLog(@"%@", @"Invoking assembly.");
        [transloadit invokeAssembly:assembly];
    };
    
    transloadit.assemblyCreationFailureBlock = ^(NSDictionary* completionDictionary){
        NSLog(@"Assembly creation failed: %@", [completionDictionary debugDescription]);
    };

    transloadit.assemblyStatusBlock = ^(NSDictionary* completionDictionary){
        NSLog(@"Assembly status: %@", [completionDictionary debugDescription]);
    };
    
    transloadit.assemblyResultBlock = ^(NSDictionary* completionDictionary){
        NSLog(@"Assembly finished : %@", [completionDictionary debugDescription]);
    };
    
    transloadit.assemblyFailureBlock = ^(NSDictionary* completionDictionary){
        NSLog(@"Assembly failed: %@", [completionDictionary debugDescription]);
    };
}

- (IBAction)upload:(id)sender {
    [transloadit create: testAssembly];

}

- (IBAction)runAssembly:(id)sender {
    [transloadit create: testAssembly];
    
}

- (void) transloaditAssemblyCreationError:(NSError *)error withResponse:(TransloaditResponse *)response {
    NSLog(@"%@", [response debugDescription]);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
