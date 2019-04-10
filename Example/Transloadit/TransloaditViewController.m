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
Template *newAssembly;

- (void)viewDidLoad {
    [super viewDidLoad];
    transloadit = [[Transloadit alloc] init];
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
    
    
    
}


-(void)viewDidAppear:(BOOL)animated {
    [self selectFile:nil];
    
}

- (IBAction)selectFile:(id)sender {
    //MARK: Image Picker
    //Basic UIImagePicker Controller Setup
    UIImagePickerController *imagePicker = [UIImagePickerController new];
    imagePicker.mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:imagePicker.sourceType];
    imagePicker.delegate = self;
    
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    if(status == PHAuthorizationStatusNotDetermined) {
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
            [self presentViewController:imagePicker animated:YES completion:nil];
        }];
    } else if (status == PHAuthorizationStatusAuthorized) {
        [self presentViewController:imagePicker animated:YES completion:nil];
    } else if (status == PHAuthorizationStatusRestricted) {
        //Permisions Needed
    } else if (status == PHAuthorizationStatusDenied) {
        // Permisions Needed
    }
}


- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    //-----------------------------------------------------
    // MARK: Picker
    //-----------------------------------------------------
    // !! NOTE !!
    // This is boilerplate imagepicker code. You do NOT need this for Transloadit.
    // This is strictly for the Example, and grabbing an image.
    [self dismissViewControllerAnimated:YES completion:nil];
    NSURL *assetUrl = [info valueForKey:UIImagePickerControllerReferenceURL];
    PHFetchResult *result = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum
                                                                     subtype:PHAssetCollectionSubtypeSmartAlbumUserLibrary
                                                                     options:nil];
    PHAssetCollection *assetCollection = result.firstObject;
    NSLog(@"%@", assetCollection.localizedTitle);
    
    NSArray<NSURL *> *array = [[NSArray alloc] initWithObjects:assetUrl, nil];
    PHFetchResult *fetchResult = [PHAsset fetchAssetsWithALAssetURLs:array options:nil];
    PHAsset *asset = [fetchResult firstObject];
    [[[PHImageManager alloc] init] requestImageDataForAsset:asset options:nil resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
        
        NSURL *documentDirectory = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSAllDomainsMask][0];
        NSURL *fileUrl = [documentDirectory URLByAppendingPathComponent:[[NSUUID alloc] init].UUIDString];
        NSError *error;
        if (![imageData writeToURL:fileUrl options:NSDataWritingAtomic error:&error]) {
            NSLog(@"%li", (long)error.code);
        }
        
        NSMutableArray<Step *> *steps = [[NSMutableArray alloc] init];

        Step *step1 = [[Step alloc] initWithKey:@"encode"];
        [step1 setValue:@"/image/resize" forOption:@"robot"];

        // Add the step to the array
        [steps addObject:step1];
//
        //MARK: We then create an Assembly Object with the steps and files
        Assembly *TestAssemblyWithSteps = [[Assembly alloc] initWithSteps:steps andNumberOfFiles:1];
        
        Template *testTemplate = [[Template alloc] initWithSteps:steps andName:@"New Template"];

//        [TestAssemblyWithSteps addFile:fileUrl andFileName:@"thisIsNew.jpg"];
//        [TestAssemblyWithSteps setNotify_url:@""];
        [transloadit create:TestAssemblyWithSteps];
//        Assembly *alreadyCreated = [[Assembly alloc] initWithId:@"63d028303a5811e9b44f2f1f0370e845"];
//
//        [alreadyCreated addFile:fileUrl andFileName:@"test22.jpg"];
        
    }];
}

- (void) transloaditAssemblyCreationResult:(Assembly *)assembly {
    NSLog(@"%@", [assembly urlString]);
    //[transloadit invokeAssembly:assembly retry:3];
}

- (void) transloaditAssemblyCreationError:(NSError *)error withResponse:(TransloaditResponse *)response {
    NSLog(@"%@: %@", @"FAILED!", [[response dictionary] description]);
}

// DELEGATE
- (void) transloaditTemplateCreationResult:(Template *)template {
    NSLog(@"%@", @"Created Template");
}

- (void) transloaditTemplateCreationError:(NSError *)error withResponse:(TransloaditResponse *)response {
    NSLog(@"%@", @"Failed Creating Template");
    //NSLog(@"%@", [[response dictionary] debugDescription]);
    
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
