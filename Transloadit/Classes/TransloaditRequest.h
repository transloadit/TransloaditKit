//
//  TransloaditRequest.h
//  Arcane-iOS
//
//  Created by Mark Masterson on 10/4/17.
//

#import <Foundation/Foundation.h>
#import "Transloadit.h"
@interface TransloaditRequest : NSMutableURLRequest

@property (nonatomic, strong)NSString* key;
@property (nonatomic, strong)NSString* secret;
@property (nonatomic, strong)NSString* method;


- (id) initWithKey:(NSString *)key andSecret:(NSString *)secret;
- (id) initWith:(NSString *)key andSecret:(NSString *)secret andMethod:(NSString *)method andURL:(NSString *) url;
- (NSMutableURLRequest *) createRequestWithMethod:(NSString *)method andURL:(NSString *) url;


- (void) appendParams:(NSMutableDictionary *) params;

@end
