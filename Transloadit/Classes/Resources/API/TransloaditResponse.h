//
//  TransloaditResponse.h
//  Pods
//
//  Created by Mark Masterson on 9/16/16.
//
//

#import <Foundation/Foundation.h>

@interface TransloaditResponse : NSObject

@property (nonatomic, strong)NSString* idNumber;
@property (nonatomic, strong)NSString* status_endpoint;
@property (nonatomic, strong)NSString* add_files_endpoint;

-(id)initWithID:(NSString *)idNumber AndStatusEndpoint:(NSString *)status_endpoint andAddFilesEndpoint:(NSString *)add_files;

@end
