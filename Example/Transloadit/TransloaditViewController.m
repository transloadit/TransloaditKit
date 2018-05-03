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


@interface TransloaditViewController ()
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

//static TransloaditAssemblyStatusBlock statusBlock = ^(NSDictionary* dict){
//    // Handle the error
//    NSLog(@"Dictionary: %@", [dict description]);
//};
//
//static TransloaditAssemblyCompletionBlock completionBlock = ^(NSDictionary* dict){
//    // Handle the error
//    NSLog(@"Dictionary: %@", [dict description]);
//};

@implementation TransloaditViewController

Transloadit *transloadit;


- (void)viewDidLoad {
    [super viewDidLoad];
    transloadit = [[Transloadit alloc] init];
    transloadit.failureBlock = failureBlock;
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
        
        NSLog([fileUrl description]);
        
        //MARK: Transloadit Kit Implementation
        
        //MARK: Assembly Steps
        //Here we create an array to hold each Step that we our files to process through on Transloadit
        NSMutableArray<Step *> *steps = [[NSMutableArray alloc] init];
        
        Step *step1 = [[Step alloc] initWithKey:@"encode"];
        [step1 setValue:@"75" forOption:@"width"];
        [step1 setValue:@"75" forOption:@"height"];
        [step1 setValue:@"/image/resize" forOption:@"robot"];

//
//        // Add the step to the array
        [steps addObject:step1];
        
        //MARK: We then create an Assembly Object with the steps and files
        //Assembly *TestAssemblyWithSteps = [[Assembly alloc] initWithSteps:steps andNumberOfFiles:3];
//        [TestAssemblyWithSteps addFile:fileUrl];
//        [TestAssemblyWithSteps setNotify_url:@""];
        
        Template *testTemplate = [[Template alloc] initWithTemplateId:@"854f71504eea11e8b947315f16ae1faa"];
//        Template *testTemplateWithSteps = [[Template alloc] initWithSteps:steps andName:@"TestName4"];
        
        Assembly *testAssemblyWithTemplate = [[Assembly alloc] initWithTemplate:testTemplate andNumberOfFiles:1];
//        [testAssemblyWithTemplate addFile:fileUrl];
//
        //[transloadit createTemplate:testTemplateWithSteps];
        //[transloadit invokeAssembly:testAssemblyWithTemplate];
        //MARK: Create the assembly on Transloadit
        [testAssemblyWithTemplate addFile:fileUrl];
       [transloadit createAssembly:testAssemblyWithTemplate];
        
        
//        transloadit.assemblyStatusBlock = ^(NSDictionary* completionDictionary){
//            NSLog(@"%@", [completionDictionary description]);
//
//        };
        
        transloadit.assemblyCreationFailureBlock = ^(NSDictionary* failureDictionary) {
            NSLog(@"%@", [failureDictionary description]);
        };
        
        
        transloadit.assemblyCreationCompletionBlock = ^(Assembly* assembly) {
            /*Invoking The Assebmly does NOT need to happen inside the completion block. However for sake of the example it is.
             We do however need to use the assebmly that is returned for future functions
             */
            NSLog(@"%@", [assembly urlString]);
            [transloadit invokeAssembly:assembly];
            //[transloadit checkAssembly:assembly];
            NSLog(@"%@", @"Finished!");
            
        };
        
        //MARK: Invoke the assebmly
        transloadit.assemblyCompletionBlock = ^(NSDictionary* completionDictionary){
            /*Invoking The Assebmly does NOT need to happen inside the completion block. However for sake of a small UI it is.
             We do however need to add the URL to the Assembly object so that we do invoke it, it knows where to go.
             */
            ///[TestAssemblyWithSteps setUrlString:[completionDictionary valueForKey:@"assembly_ssl_url"]];
           // [transloadit invokeAssembly:TestAssemblyWithSteps];
            
            //[transloadit checkAssembly:TestAssemblyWithSteps];
            NSLog(@"%@", [completionDictionary description]);
            NSLog(@"%@", @"Finished!");

        };
        
        transloadit.assemblyStatusBlock = ^(NSDictionary* completionDictionary){
            NSLog(@"%@", [completionDictionary description]);
        };
        
    }];
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
