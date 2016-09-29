//
//  TransloaditResponse.m
//  Pods
//
//  Created by Mark Masterson on 9/16/16.
//
//

#import "TransloaditResponse.h"

@implementation TransloaditResponse

-(id)initWithID:(NSString *)id AndStatusEndpoint:(NSString *)status_endpoint andAddFilesEndpoint:(NSString *)add_files_endpoint{
    self = [super init];
    if(self) {
        NSLog(@"_init: %@", self);
        _idNumber = _idNumber;
        _status_endpoint = status_endpoint;
        _add_files_endpoint = add_files_endpoint;
    }
}

@end
