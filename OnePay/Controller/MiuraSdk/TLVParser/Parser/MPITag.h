#import <Foundation/Foundation.h>
#import "MPIDescription.h"


@interface MPITag: NSObject

@property(nonatomic, strong, readonly) MPIDescription *tagDescription;

+ (instancetype)tagWithTag:(TLVTag)tag;
- (instancetype)initWithTag:(TLVTag)tag;
- (NSString *)outline;

@end