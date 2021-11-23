#import "MPITLVParser.h"
#import "MPIBinaryUtil.h"
#import "MPITag.h"
#import "MPITLVObject.h"


@implementation MPITLVParser


#pragma mark - decode

+ (NSArray *)decodeWithBytes:(NSData *)bytes {
    
    NSMutableArray *tlvs = [NSMutableArray array];

    // Get whole data process
    NSUInteger i = 0;
    while (bytes != nil && i < bytes.length) {
        // Get first byte data (Tag object)
        NSUInteger topTag = [MPIBinaryUtil intWithByte:[MPIBinaryUtil byteWithBytes:bytes index:i]];
        NSUInteger tagID = topTag;
        NSUInteger tLength = 1;

        // Get another next byte, if there is 0x1F
        if ((tagID & 0x1F) == 0x1F) {
            for (NSUInteger j = i + 1; j < bytes.length; j++) {
                NSUInteger appendTagID = [MPIBinaryUtil intWithByte:[MPIBinaryUtil byteWithBytes:bytes index:j]];
                tagID = (tagID << 8) + appendTagID;
                tLength++;

                if ((appendTagID & 0x80) != 0x80) break;
            }
        }
        // End getting data for termination tag 0x0F
        if (tagID == 0x0F) break;
        MPITag *tag = [MPITag tagWithTag:tagID];
        i += tLength;

        // Get second byte data (Length object)
        // Length data is consisted until 0x7F
        // First byte would be Lengh size, if there is 0x80
        NSUInteger topLen = [MPIBinaryUtil intWithByte:[MPIBinaryUtil byteWithBytes:bytes index:i]];
        NSInteger vLength = 0;
        NSInteger lLength = 1;
        if ((topLen & 0x80) == 0x80) {
            NSUInteger byteLength = (topLen & 0x7F) & 0xFF;

            for (NSUInteger shift = 1; shift <= byteLength; shift++) {
                vLength = (vLength << 8) + [MPIBinaryUtil intWithByte:[MPIBinaryUtil byteWithBytes:bytes index:i + shift]];
                lLength++;
            }
        } else {
            vLength = (topLen & 0x7F) & 0xFF;
        }
        i += lLength;

        MPITLVObject *tlv = [MPITLVObject tlvObjectWithTag:tag tLength:tLength lLength:lLength vLength:vLength];

        // Get Value object
        // Check for constructed data
        if ([tlv isConstructed]) {
            // Decode loop process for constructed data
            tlv.rawData = [bytes subdataWithRange:NSMakeRange(i, vLength)];
            tlv.constructedTLVObject = [MPITLVParser decodeWithBytes:bytes offset:i length:vLength];
            i += tlv.constructedTLVLength;
        } else {
            // Decode data set process for unconstructed data
            [tlv setRawData:[bytes subdataWithRange:NSMakeRange(i, tlv.vLength)]];
            i += tlv.vLength;
        }
        [tlvs addObject:tlv];
        
    }
    return [tlvs copy];
}

+ (NSArray *)decodeWithBytes:(NSData *)bytes
                      offset:(NSUInteger)offset
                      length:(NSUInteger)length {

    NSData *newBytes = [bytes subdataWithRange:NSMakeRange(offset, length)];
    return [MPITLVParser decodeWithBytes:newBytes];
}


#pragma mark - encode

+ (NSData *)encodeWithTLVObject:(MPITLVObject *)tlv {
    
    if (tlv == nil) {
        return nil;
    }
    else if ([tlv isConstructed]) {
        if (tlv.rawData && tlv.rawData.length != 0 &&
            tlv.constructedTLVObject.count == 0) {
            return [self encodeWithTag:tlv.tag.tagDescription.tag
                                 value:tlv.rawData];
        }
        return [self encodeWithTag:tlv.tag.tagDescription.tag
                             value:[self encodeWithArray:tlv.constructedTLVObject]];
    }
    else {
        return [self encodeWithTag:tlv.tag.tagDescription.tag
                             value:tlv.rawData];
    }

}

+ (NSData *)encodeWithArray:(NSArray *)tlvs {
    
    NSMutableData *raw = [NSMutableData data];
    
    [tlvs enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj isKindOfClass:[MPITLVObject class]] == NO) {
            return;
        }
        
        MPITLVObject *tlv = (MPITLVObject *)obj;
        NSData *currentRaw = nil;
        if ([tlv isConstructed]) {
            if (tlv.rawData && tlv.rawData.length != 0 &&
                tlv.constructedTLVObject.count == 0) {
                currentRaw = tlv.rawData;
            }
            else {
                currentRaw = [self encodeWithArray:tlv.constructedTLVObject];
            }
        }
        else {
            currentRaw = tlv.rawData;
        }
        [raw appendData:[self encodeWithTag:tlv.tag.tagDescription.tag
                                      value:currentRaw]];
    }];

    return raw;
}

+ (NSData *)encodeWithTag:(TLVTag)tag value:(NSData *)value {
    
    NSMutableData *result = [NSMutableData dataWithData:[MPIBinaryUtil bytesWithHexString:[MPIBinaryUtil hexStringWithInt:tag]]];
    
    Byte lenByte = 0x00;
    
    NSUInteger valueLength = value.length;
    NSUInteger lenBytes = floor(valueLength / 128);
    if (lenBytes > 0) {
        lenByte = 0x80 + lenBytes;
        [result appendBytes:&lenByte length:1];
        for (NSInteger i = lenBytes; i > 0; i--) {
            lenByte = valueLength >> (8 * (i - 1)) & 0xFF;
            [result appendBytes:&lenByte length:1];
        }
    } else {
        lenByte = valueLength & 0xFF;
        [result appendBytes:&lenByte length:1];
    }
    
    [result appendData:value];
    
    return [result copy];
}


#pragma mark - Not available

- (instancetype)init {
    
    NSAssert(NO, @"This method is not available.");
    return nil;
}

@end
