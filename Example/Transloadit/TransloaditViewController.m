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

@implementation TransloaditViewController

Transloadit *transloadit;
Template *newAssembly;

- (void)viewDidLoad {
    [super viewDidLoad];
    transloadit = [[Transloadit alloc] init];
    [transloadit setDelegate:self];
}


-(void)viewDidAppear:(BOOL)animated {
    [self selectFile:nil];
    
}

-(void)createAnAsseblyWithFileURL:(NSURL *) url {
    //An Array holding AssemblySteps
    NSMutableArray<Step *> *steps = [[NSMutableArray alloc] init];
    //An Example AssemblyStep
    Step *step1 = [[Step alloc] initWithKey:@"encode"];
    [step1 setValue:@"/image/resize" forOption:@"robot"];
    
    // Add the step to the array
    [steps addObject:step1];
    
    //MARK: We then create an Assembly Object with the steps and files
    Assembly *TestAssemblyWithSteps = [[Assembly alloc] initWithSteps:steps andNumberOfFiles:1];
    
    //Add the file
    [TestAssemblyWithSteps addFile:url andFileName:@"test.jpg"];
    
    //Create the Assembly
    [transloadit create:TestAssemblyWithSteps];
}

-(void)createTemplate {
    //An Array holding AssemblySteps
    NSMutableArray<Step *> *steps = [[NSMutableArray alloc] init];
    //An Example AssemblyStep
    Step *step1 = [[Step alloc] initWithKey:@"encode"];
    [step1 setValue:@"/image/resize" forOption:@"robot"];
    
    // Add the step to the array
    [steps addObject:step1];
    
    //MARK: We then create an Template Object with the steps
    Template *TestTemplateWithSteps = [[Template alloc] initWithSteps:steps andName:@"Test Template"];
    
    //Create the Template
    [transloadit create:TestTemplateWithSteps];
}

//-----------------------------------------------------
// MARK: Picker
//-----------------------------------------------------
// !! NOTE !!
// This is boilerplate imagepicker code. You do NOT need this for Transloadit.
// This is strictly for the Example, and grabbing an image.

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
        
        //Now that we have the image file URL - create the assembly
        [self createAnAsseblyWithFileURL:fileUrl];
        
    }];
}

// DELEGATE

- (void) transloaditAssemblyCreationResult:(Assembly *)assembly {
    NSLog(@"%@", [assembly urlString]);
    [assembly setUrlString:[assembly urlString]];
    [transloadit invokeAssembly:assembly retry:3];
}

- (void) transloaditAssemblyCreationError:(NSError *)error withResponse:(TransloaditResponse *)response {
    NSLog(@"%@: %@", @"FAILED!", [[response dictionary] description]);
}

- (void) transloaditTemplateCreationResult:(Template *)template {
    NSLog(@"%@", @"Created Template");
}

- (void) transloaditTemplateCreationError:(NSError *)error withResponse:(TransloaditResponse *)response {
    NSLog(@"%@", @"Failed Creating Template");
}


- (void) transloaditAssemblyProcessResult:(TransloaditResponse *)response {
    NSLog(@"%@", [response debugDescription]);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
