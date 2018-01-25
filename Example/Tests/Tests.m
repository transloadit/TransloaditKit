//
//  TransloaditTests.m
//  TransloaditTests
//
//  Created by Mark R. Masterson on 08/30/2016.
//  Copyright (c) 2016 Mark R. Masterson. All rights reserved.
//

@import XCTest;
@import TransloaditKit;

@interface Tests : XCTestCase

@end

@implementation Tests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    
    
}

- (void)testResizeImageExistingFile
{

    Transloadit *transloadit = [[Transloadit alloc] initWithKey:@"5ae6b9c0f10c11e594a0bfa14ca2ffe1" andSecret:@"a9d351b355bb47b21af79d89aa9d8a54a6f27a41"];
    

    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"test" ofType:@"jpg"];

    
    NSData *img = [NSData dataWithContentsOfFile:path];
    
    XCTAssertTrue(path != nil);
    
    NSError *error;
    

    
    NSMutableArray<Step *> *steps = [[NSMutableArray alloc] init];
    
    Step *step1 = [[Step alloc] initWithKey:@"encode"];
    [step1 setValue:@"/image/resize" forOption:@"robot"];
    
    // Add the step to the array
    [steps addObject:step1];
    
    //MARK: We then create an Assembly Object with the steps and files
    Assembly *TestAssemblyWithSteps = [[Assembly alloc] initWithSteps:steps andNumberOfFiles:1];
    [TestAssemblyWithSteps addFile:[NSURL fileURLWithPath:path]];
    
    [TestAssemblyWithSteps setTemplate:[[Template alloc] initWithTemplateId:@""]];
    [transloadit createAssembly:TestAssemblyWithSteps];
    
    transloadit.assemblyCompletionBlock = ^(NSDictionary* completionDictionary){
        /*Invoking The Assebmly does NOT need to happen inside the completion block. However for sake of a small UI it is.
         We do however need to add the URL to the Assembly object so that we do invoke it, it knows where to go.
         */
        [TestAssemblyWithSteps setUrlString:[completionDictionary valueForKey:@"assembly_ssl_url"]];
        [transloadit invokeAssembly:TestAssemblyWithSteps];
        
        [transloadit checkAssembly:TestAssemblyWithSteps];
    };
    

    transloadit.assemblyStatusBlock = ^(NSDictionary* completionDictionary){
        /*Invoking The Assebmly does NOT need to happen inside the completion block. However for sake of a small UI it is.
         We do however need to add the URL to the Assembly object so that we do invoke it, it knows where to go.
         */
        NSLog(@"%@", [completionDictionary description]);
        
        if ([completionDictionary[@"ok"] isEqualToString:@"ASSEMBLY_COMPLETED"]) {
             XCTAssertTrue([[completionDictionary objectForKey:@"uploads"] isEqualToString:@"1"]);

        }
    };
    
    
}


- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}


@end

