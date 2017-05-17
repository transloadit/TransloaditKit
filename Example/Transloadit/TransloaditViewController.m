//
//  TransloaditViewController.m
//  Transloadit
//
//  Created by Mark R. Masterson on 08/30/2016.
//  Copyright (c) 2016 Mark R. Masterson. All rights reserved.
//

#import "TransloaditViewController.h"
#import <Transloadit/Transloadit.h>
#import <AssetsLibrary/AssetsLibrary.h>

@interface TransloaditViewController ()
@property (strong,nonatomic) ALAssetsLibrary *assetLibrary;

@end

//MARK: Your Tansloadit Progress Blocks
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


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    transloadit = [[Transloadit alloc] initWithKey:@"5ae6b9c0f10c11e594a0bfa14ca2ffe1" andSecret:@"a9d351b355bb47b21af79d89aa9d8a54a6f27a41"];

    
	// Do any additional setup after loading the view, typically from a nib.
}

-(void)viewDidAppear:(BOOL)animated{
    [self selectFile:nil];
}

- (IBAction)selectFile:(id)sender {
    UIImagePickerController *imagePicker = [UIImagePickerController new];
    imagePicker.mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:imagePicker.sourceType];
    imagePicker.delegate = self;
    [self presentViewController:imagePicker animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [self dismissViewControllerAnimated:YES completion:nil];
    NSURL *assetUrl = [info valueForKey:UIImagePickerControllerReferenceURL];
    
    if (!self.assetLibrary) {
        self.assetLibrary = [ALAssetsLibrary new];
    }
    
    [self.assetLibrary assetForURL:assetUrl resultBlock:^(ALAsset* asset) {
        
        
        ALAssetRepresentation *rep = [asset defaultRepresentation];
        Byte *buffer = (Byte*)malloc(rep.size);
        NSUInteger buffered = [rep getBytes:buffer fromOffset:0.0 length:rep.size error:nil];
        
        NSData *data = [NSData dataWithBytesNoCopy:buffer length:buffered freeWhenDone:YES];
        NSURL *documentDirectory = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSAllDomainsMask][0];
        NSURL *fileUrl = [documentDirectory URLByAppendingPathComponent:[[NSUUID alloc] init].UUIDString];
        
        NSError *error;
        if (![data writeToURL:fileUrl options:NSDataWritingAtomic error:&error]) {
            NSLog(@"%li", (long)error.code);
        }
        
        
        //MARK: A Transloadigt Object that will handle all the features
        
        transloadit.completionBlock = ^(NSDictionary* completionDictionary){
            
            
            
        };
        
        //MARK: An Array to hold the steps
        NSMutableArray<AssemblyStep *> *steps = [[NSMutableArray alloc] init];
        
        //MARK: A Sample step
        AssemblyStep *step1 = [[AssemblyStep alloc] initWithKey:@"encode"];
        [step1 setValue:@"/image/resize" forOption:@"robot"];
        
        // Add the step to the array
        [steps addObject:step1];
        
        //MARK: Create an assembly with steps
        Assembly *TestAssemblyWithSteps = [[Assembly alloc] initWithSteps:steps andNumberOfFiles:1];
        [TestAssemblyWithSteps addFile:fileUrl];
        [TestAssemblyWithSteps setNotify_url:@""];
        
        //MARK: Start The Assembly
        [transloadit createAssembly:TestAssemblyWithSteps];
        


    } failureBlock:^(NSError* error) {
        NSLog(@"Unable to load asset due to: %@", error);
    }];
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
