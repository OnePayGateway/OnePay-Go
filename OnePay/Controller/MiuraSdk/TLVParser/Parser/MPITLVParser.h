#import <Foundation/Foundation.h>
#import "MPITLVObject.h"


@interface MPITLVParser: NSObject


#pragma mark - decode

+ (NSArray *)decodeWithBytes:(NSData *)bytes;


#pragma mark - encode

+ (NSData *)encodeWithTLVObject:(MPITLVObject *)tlv;

+ (NSData *)encodeWithTag:(TLVTag)tag value:(NSData *)value;


#pragma mark - Not available

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
- (instancetype)new UNAVAILABLE_ATTRIBUTE;

@end