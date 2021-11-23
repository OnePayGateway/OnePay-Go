#import "MPIBinaryUtil.h"


@implementation MPIBinaryUtil


#pragma mark - parseHexBinary : NSString -> NSData / unsigned char

+ (NSData *)bytesWithHexString:(NSString *)hexString {
    if (hexString.length % 2 != 0) {
        [[NSException exceptionWithName:NSInvalidArgumentException
          reason:[NSString stringWithFormat:@"hexBinary needs to be even-length: %@", hexString]
          userInfo:nil] raise];
    }
    const NSUInteger length = hexString.length / 2;
    NSMutableData *data = [[NSMutableData alloc] initWithCapacity:length];

    for (NSUInteger i = 0; i < length; i++) {
        @autoreleasepool {
            NSString *hexStringTemp = [hexString substringWithRange:NSMakeRange(i * 2, 2)];

            // Check expression for hex string
            if ([MPIBinaryUtil isHexString:hexStringTemp] == NO) {
                [[NSException exceptionWithName:NSInvalidArgumentException
                  reason:[NSString stringWithFormat:@"contains illegal character for hexBinary: %@", hexString]
                  userInfo:nil] raise];
            }
            Byte byte = [MPIBinaryUtil byteWithHexString:hexStringTemp];
            [data appendBytes:&byte length:1];
        }
    }
    return [data copy];
}

+ (Byte)byteWithHexString:(NSString *)hexString {
    if (hexString.length != 2) {
        [[NSException exceptionWithName:NSInvalidArgumentException
          reason:[NSString stringWithFormat:@"hexBinary needs to be even-length: %@", hexString]
          userInfo:nil] raise];
    }
    if ([MPIBinaryUtil isHexString:hexString] == NO) return 0x00;
    unsigned int result;
    [[NSScanner scannerWithString:[@"0x" stringByAppendingString:hexString]] scanHexInt:&result];

    return (Byte)result;
}


#pragma mark - parseInt : NSString / unsigned char -> NSUInteger

+ (NSUInteger)intWithHexString:(NSString *)hexString {
    return [MPIBinaryUtil intWithHexString:hexString isFrankly:NO];
}

+ (NSUInteger)intWithHexString:(NSString *)hexString isFrankly:(BOOL)isFrankly {
    unsigned int result = 0;

    if (isFrankly) {
        if ([MPIBinaryUtil isDecimalString:hexString] == NO) return result;
        result = [hexString intValue];
    } else {
        if ([MPIBinaryUtil isHexString:hexString] == NO) return result;
        [[NSScanner scannerWithString:hexString] scanHexInt:&result];
    }
    return result;
}

+ (NSUInteger)intWithByte:(Byte)byte {
    return [MPIBinaryUtil intWithByte:byte isFrankly:NO];
}

+ (NSUInteger)intWithByte:(Byte)byte isFrankly:(BOOL)isFrankly {
    NSUInteger result = 0;

    if (isFrankly) {
        NSUInteger division = (byte & 0xFF) / 16;
        NSUInteger remainder = (byte & 0xFF) % 16;
        if (remainder >= 10) return result;
        result = division * 10 + remainder;
    } else {
        result = byte & 0xFF;
    }
    return result;
}


#pragma mark - parseBinaryString : unsigned char / NSData -> NSString

+ (NSString *)binaryStringWithByte:(Byte)byte {
    NSString *binaryString = @"";
    NSUInteger remaining = (NSUInteger)byte;

    while (remaining != 0) {
        binaryString = [NSString stringWithFormat:@"%tu%@", remaining % 2, binaryString];
        remaining = remaining / 2;
    }
    return [[@"00000000" stringByAppendingString:binaryString] substringFromIndex:binaryString.length];
}

+ (NSString *)binaryStringWithBytes:(NSData *)bytes {
    NSMutableString *binaryString = [[NSMutableString alloc] init];
    const NSUInteger length = [bytes length];
    const Byte *ptr = [bytes bytes];

    for (NSInteger i = 0; i < length; i++) {
        Byte current = *ptr++;
        [binaryString appendString:[MPIBinaryUtil binaryStringWithByte:current]];
    }
    return [binaryString copy];
}

+ (NSString *)binaryStringWithBytes:(NSData *)bytes index:(NSUInteger)index {
    return [MPIBinaryUtil binaryStringWithByte:[MPIBinaryUtil byteWithBytes:bytes index:index]];
}


#pragma mark - parseHexString : NSUInteger / unsigned char / NSData -> NSString

+ (NSString *)hexStringWithInt:(NSUInteger)byte {
    return [[NSString stringWithFormat:@"%02tX", byte] uppercaseString];
}

+ (NSString *)hexStringWithByte:(Byte)byte {
    return [MPIBinaryUtil hexStringWithInt:[MPIBinaryUtil intWithByte:byte]];
}

+ (NSString *)hexStringWithBytes:(NSData *)bytes {
    NSMutableString *hexString = [[NSMutableString alloc] init];
    const NSUInteger length = [bytes length];
    const Byte *ptr = [bytes bytes];

    for (NSInteger i = 0; i < length; i++) {
        Byte current = *ptr++;
        [hexString appendString:[MPIBinaryUtil hexStringWithByte:current]];
    }
    return [hexString copy];
}


#pragma mark - parseByte : NSUInteger -> unsigned char

+ (Byte)byteWithInt:(NSUInteger)byte {
    return (Byte)(byte % 256);
}

/** Convert NSInteger `value` into a byte array.
 *
 * @param array     byte array to receive converted NSInteger.
 * @param value     NSInteger to convert into byte array.
 * @param byteCount number of bytes to convert NSInteger to.
 * @param index     index into array to store converted bytes.
 * @return array    Returns the byte array passed via array param.
 *
 */
+ (Byte)convertIntToHexByteArray:(Byte *)array
                           value:(int)value
                       byteCount:(int)byteCount
                           index:(int)index {
    
    int shiftBy = 0;
    int i;
    for (i = (byteCount-1); i >=0; i--) {
        array[i+index] = (Byte)(shiftBy > value);
        shiftBy += 8;
    }
    
    return array;
}

#pragma mark - other

+ (NSString *)stringWithBytes:(NSData *)bytes {
    return [[NSString alloc] initWithData:bytes encoding:NSUTF8StringEncoding];
}

+ (Byte)byteWithBytes:(NSData *)bytes {
    return [MPIBinaryUtil byteWithBytes:bytes index:0];
}

+ (Byte)byteWithBytes:(NSData *)bytes index:(NSUInteger)index {
    if (bytes == nil || bytes.length == 0) return 0x00;
    Byte result;
    [bytes getBytes:&result range:NSMakeRange(index, 1)];
    return result;
}

+ (NSString *)hexStringWithBinaryString:(NSString *)binaryString {
    NSMutableString *ms = [[NSMutableString alloc] init];

    if ([MPIBinaryUtil isBinaryString:binaryString] == NO) return [ms copy];
    const NSUInteger binaryDigits = 8;
    NSUInteger length = binaryString.length / binaryDigits;

    for (NSUInteger i = 0; i < length; i++) {
        NSString *currentBinary = [binaryString substringWithRange:NSMakeRange(i * binaryDigits, binaryDigits)];
        NSUInteger decimal = 0;

        for (NSUInteger j = 0; j < binaryDigits; j++) {
            NSUInteger currentBit = [[currentBinary substringWithRange:NSMakeRange(binaryDigits - 1 - j, 1)] integerValue];
            decimal += currentBit * (2 ^ j);
        }

        [ms appendFormat:@"%02tX", decimal % 256];
    }
    return [ms copy];
}

/// Regular expression matching
+ (BOOL)matchInString:(NSString *)string regex:(NSString *)regex {
    NSRegularExpression *regexPattern = [NSRegularExpression regularExpressionWithPattern:regex options:0 error:nil];
    NSTextCheckingResult *match = [regexPattern firstMatchInString:string options:0 range:NSMakeRange(0, string.length)];

    return match.numberOfRanges;
}

#pragma mark - Private Shared

/// Check for hex string expression
+ (BOOL)isHexString:(NSString *)hexString {
    if (hexString == nil || hexString.length < 2 || hexString.length % 2 != 0) return NO;
    static NSString *const pattern = @"^([a-fA-F0-9]{2})+$";

    return [MPIBinaryUtil matchInString:hexString regex:pattern];
}

/// Check for decimal string expression
+ (BOOL)isDecimalString:(NSString *)decimalString {
    if (decimalString == nil || decimalString.length == 0) return NO;
    static NSString *const pattern = @"^([0-9]{2})+$";

    return [MPIBinaryUtil matchInString:decimalString regex:pattern];
}

/// Check for bynary string expression
+ (BOOL)isBinaryString:(NSString *)binaryString {
    if (binaryString == nil || binaryString.length == 0 || binaryString.length % 8 != 0) return NO;
    static NSString *const pattern = @"^([0-1]{8})+$";

    return [MPIBinaryUtil matchInString:binaryString regex:pattern];
}


#pragma mark - Not available

- (instancetype)init {
    
    NSAssert(NO, @"This method is not available.");
    return nil;
}


@end
