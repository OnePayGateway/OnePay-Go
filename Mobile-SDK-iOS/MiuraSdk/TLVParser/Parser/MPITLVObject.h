#import <Foundation/Foundation.h>
#import "MPITag.h"


@interface MPITLVObject: NSObject


#pragma mark - Property

/// Tag object
@property(nonatomic, strong, readonly) MPITag *tag;
/// Length for tag
@property(nonatomic, assign, readonly) NSUInteger tLength;
/// Length for length
@property(nonatomic, assign, readonly) NSUInteger lLength;
/// Length for data
@property(nonatomic, assign, readonly) NSUInteger vLength;
/// Amount length
@property(nonatomic, assign, readonly) NSUInteger fullLength;
/// Data object for string
@property(nonatomic, weak, readonly) NSString *data;
/// Data object for byte array
@property(nonatomic, weak) NSData *rawData;
/// Data object for cosutructed TLV
@property(nonatomic, copy) NSArray *constructedTLVObject;


#pragma mark - Create TLVObject

+ (instancetype)tlvObjectWithTag:(MPITag *)tag tLength:(NSUInteger)tLength lLength:(NSUInteger)lLength vLength:(NSUInteger)vLength;

- (instancetype)initWithTag:(MPITag *)tag tLength:(NSUInteger)tLength lLength:(NSUInteger)lLength vLength:(NSUInteger)vLength;

- (instancetype)initWithTag:(TLVTag)tag value:(NSData *)value;

- (instancetype)initWithTag:(TLVTag)tag byteValue:(Byte)byteValue;

- (instancetype)initWithTag:(TLVTag)tag construct:(NSArray *)construct;


#pragma mark - Public

/// Existing check for constructed data
- (BOOL)isConstructed;
/// Amount length for constructed TLV
- (NSUInteger)constructedTLVLength;
/// Check data type for byte array or string
- (BOOL)isRawData;
/// logging
- (NSString *)outline;
/// logging
- (NSString *)outlineWithLevel:(NSUInteger)level;

@end
