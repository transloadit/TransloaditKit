//
//  TransloaditDelegate.h
//  Pods
//
//  Created by Mark Masterson on 7/3/18.
//

#ifndef TransloaditDelegate_h
#define TransloaditDelegate_h
#import "TransloaditResponse.h"
@protocol TransloaditDelegate <NSObject>
#pragma mark  TUS MIDDLE LAYEE
- (void)tranloaditUploadProgress:(int64_t *)written bytesTotal:(int64_t *)total;
- (void)transloaditUploadFailureBlock:(NSError *)error;

#pragma mark  CREATE
- (void)transloaditAssemblyCreationResult:(Assembly *)assembly;
- (void)transloaditAssemblyCreationError:(NSError *)error withResponse:(TransloaditResponse *)response;
- (void)transloaditTemplateCreationResult:(Template *)template;
- (void)transloaditTemplateCreationError:(NSError *)error withResponse:(TransloaditResponse *)response;

#pragma mark  READ
- (void)transloaditAssemblyGetResult:(Assembly *)assembly;
- (void)transloaditAssemblyGetError:(NSError *)error withResponse:(TransloaditResponse *)response;
- (void)transloaditTemplateGetResult:(Template *)template;
- (void)transloaditTemplateGetError:(NSError *)error withResponse:(TransloaditResponse *)response;

#pragma mark  DELETE
- (void)transloaditAssemblyDeletionResult:(TransloaditResponse *)template;
- (void)transloaditAssemblyDeletionError:(NSError *)error withResponse:(TransloaditResponse *)response;
- (void)transloaditTemplateDeletionResult:(TransloaditResponse *)template;
- (void)transloaditTemplateDeletionError:(NSError *)error withResponse:(TransloaditResponse *)response;

#pragma mark  RUNNING ASSEMBLY
- (void)transloaditAssemblyProcessResult:(TransloaditResponse *)response;
- (void)transloaditAssemblyProcessError:(NSError *)error withResponse:(TransloaditResponse *)response;
- (void)transloaditAssemblyProcessProgress:(TransloaditResponse *)response;

@end
#endif /* TransloaditDelegate_h */
