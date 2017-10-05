//
//  TransloaditRequest.h
//  Arcane-iOS
//
//  Created by Mark Masterson on 10/4/17.
//

#import <Foundation/Foundation.h>
#import "Transloadit.h"
@interface TransloaditRequest : NSObject

@property (nonatomic, strong)NSString* key;
@property (nonatomic, strong)NSString* secret;

- (id) initWithKey:(NSString *)key andSecret:(NSString *)secret;

- (NSMutableURLRequest *) createRequestWithParams:(NSMutableDictionary *) params andEndpoint:(NSString *)endpoint;
- (NSMutableURLRequest *) createRequestWithParams:(NSMutableDictionary *) params andURL:(NSString *)url;
- (NSMutableURLRequest *) createGetRequestWithURL:(NSString *) url;


@end
