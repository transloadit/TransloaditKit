//
//  AssemblyStep.m
//  Transloadit
//
//  Created by Mark Masterson on 8/19/16.
//  Copyright © 2016 Mark R. Masterson. All rights reserved.
//

#import "AssemblyStep.h"

@implementation AssemblyStep

-(id)initWithOperationName:(NSString *)operationName andBodyOperations:(NSDictionary *)bodyOperations{
    self = [super init];
    if(self) {
        [self setOperationName:operationName];
        [self setBodyOperations:bodyOperations];
        [self setJsonString:[self asJSON]];
    }
    return self;
}

-(id)initWithJSON:(NSString *)jsonString{
    self = [super init];
    if(self) {
        [self setJsonString:jsonString];
    }
    return self;
}


-(NSString *)asJSON{
    NSError *error;
    NSMutableDictionary* jsonDictionary = [[NSMutableDictionary alloc] init];
    
    [jsonDictionary setObject:[self bodyOperations] forKey:[self operationName]];
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonDictionary
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:&error];
    if (!jsonData) {
        NSLog(@"Got an error: %@", error);
        return nil;
    } else {
        return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }

}


@end
