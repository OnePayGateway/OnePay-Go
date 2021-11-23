#import <Foundation/Foundation.h>
#import "MPIDescription.h"


@interface MPIBinaryUtil: NSObject


#pragma mark - parseHexBinary : NSString -> NSData / unsigned char
+ (NSData *)bytesWithHexString:(NSString *)hexString;
+ (Byte)byteWithHexString:(NSString *)hexString;

#pragma mark - parseInt : NSString / unsigned char -> NSUInteger
+ (NSUInteger)intWithHexString:(NSString *)hexString;
+ (NSUInteger)intWithHexString:(NSString *)hexString isFrankly:(BOOL)isFrankly;
+ (NSUInteger)intWithByte:(Byte)byte;
+ (NSUInteger)intWithByte:(Byte)byte isFrankly:(BOOL)isFrankly;

#pragma mark - parseBinaryString : unsigned char / NSData -> NSString
+ (NSString *)binaryStringWithByte:(Byte)byte;
+ (NSString *)binaryStringWithBytes:(NSData *)bytes;
+ (NSString *)binaryStringWithBytes:(NSData *)bytes index:(NSUInteger)index;

#pragma mark - parseHexString : NSUInteger / unsigned char / NSData -> NSString
+ (NSString *)hexStringWithInt:(NSUInteger)byte;
+ (NSString *)hexStringWithByte:(Byte)byte;
+ (NSString *)hexStringWithBytes:(NSData *)bytes;

#pragma mark - parseByte : NSUInteger -> unsigned char
+ (Byte)byteWithInt:(NSUInteger)byte;

#pragma mark - other
/// Convert from byte array (NSData) to UTF-8 string
+ (NSString *)stringWithBytes:(NSData *)bytes;
/// Retrieve first byte from byte array (NSData)
+ (Byte)byteWithBytes:(NSData *)bytes;
/// Retrieve specified index byte from byte array (NSData)
+ (Byte)byteWithBytes:(NSData *)bytes index:(NSUInteger)index;
/// Convert from bynary string to hex string
+ (NSString *)hexStringWithBinaryString:(NSString *)binaryString;
/// Regular expression mathing
+ (BOOL)matchInString:(NSString *)string regex:(NSString *)regex;
/// NSInteger `value` into a byte array
+ (Byte)convertIntToHexByteArray:(Byte *)array value:(int)value
                       byteCount:(int)byteCount index:(int)index;


#pragma mark - Not available

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
- (instancetype)new UNAVAILABLE_ATTRIBUTE;

@end
