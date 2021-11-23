#import "MPIUtil.h"
#import "MPIBinaryUtil.h"
#import "MPITLVObject.h"


@implementation MPIUtil


#pragma mark - search tlv value

/// Retrieve tag data from child TLV object
+ (MPITLVObject *)tlvObjectFromTLVObject:(MPITLVObject *)tlv
                                     tag:(TLVTag)tag {
    
    return [MPIUtil tlvObjectFromArray:tlv.constructedTLVObject
                                   tag:tag
                                 index:0];
}

/// Retrieve tag data from child TLV object with index
+ (MPITLVObject *)tlvObjectFromTLVObject:(MPITLVObject *)tlv
                                     tag:(TLVTag)tag
                                   index:(NSUInteger)index {
    
    return [MPIUtil tlvObjectFromArray:tlv.constructedTLVObject
                                   tag:tag
                                 index:index];
}

/// Retrieve tag data from Array data
+ (MPITLVObject *)tlvObjectFromArray:(NSArray *)tlvs
                                 tag:(TLVTag)tag {
    
    return [MPIUtil tlvObjectFromArray:tlvs
                                   tag:tag
                                 index:0];
}

/// Retrieve tag data from Array data with index
+ (MPITLVObject *)tlvObjectFromArray:(NSArray *)tlvs
                                 tag:(TLVTag)tag
                               index:(NSUInteger)index {
    
    NSUInteger currentIndex = 0;
    return [MPIUtil tlvObjectFromArray:tlvs
                                   tag:tag
                                 index:index
                          currentIndex:&currentIndex];
}


#pragma mark - Private Shared

+ (MPITLVObject *)tlvObjectFromArray:(NSArray *)tlvs
                                 tag:(TLVTag)tag
                               index:(NSUInteger)index
                        currentIndex:(NSUInteger *)currentIndex {
    
    if (tlvs == nil || tlvs.count == 0) {
        return nil;
    }
    
    __block MPITLVObject *tlv = nil;
    
    [tlvs enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj isKindOfClass:[MPITLVObject class]] == NO) {
            return;
        }
        
        MPITLVObject *candidate = (MPITLVObject *)obj;
        if (candidate.tag.tagDescription.tag != tag) {
            return;
        }
        
        if (index == *currentIndex) {
            tlv = candidate;
            *stop = YES;
        }
        *currentIndex += 1;
    }];
    
    if (tlv == nil) {
        [tlvs enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            if ([obj isKindOfClass:[MPITLVObject class]] == NO) {
                return;
            }
            
            MPITLVObject *candidate = [self tlvObjectFromArray:((MPITLVObject *)obj).constructedTLVObject
                                                                tag:tag
                                                         index:index
                                                  currentIndex:currentIndex];
            
            if (candidate) {
                tlv = candidate;
                *stop = YES;
            }
        }];
    }
    
    return tlv;
}




+ (BOOL)isDeviceConnected:(MPIResponseData *)response {
    
    NSData *deviceState = [self tlvObjectFromArray:response.tlv tag:TLVTag_Status_Code].rawData;
    if (deviceState == nil || deviceState.length == 0) return NO;
    switch ([MPIBinaryUtil byteWithBytes:deviceState]) {
        case 0x01: {
            return YES;
        }
        default: {
            return NO;
        }
    }
}

+ (BOOL)isDeviceRebooted:(MPIResponseData *)response {
    
    NSData *deviceState = [MPIUtil tlvObjectFromArray:response.tlv tag:TLVTag_Status_Code].rawData;
    if (deviceState == nil || deviceState.length == 0) return NO;
    switch ([MPIBinaryUtil byteWithBytes:deviceState]) {
        case 0x0A:
        case 0x0B:
        case 0x0C: {
            return YES;
        }
        default: {
            return NO;
        }
    }
}

+ (NSDictionary *)configVersionsFromTLVObjectOfGetConfiguration:(MPITLVObject *)tlv {
    
    NSMutableDictionary *versions = [NSMutableDictionary dictionary];

    MPITLVObject *config = [MPIUtil tlvObjectFromTLVObject:tlv
                                                       tag:TLVTag_Configuration_Information];
    NSUInteger index = 1;
    while (config) {
        NSString *key = [MPIUtil tlvObjectFromTLVObject:config
                                                    tag:TLVTag_Identifier].data;
        NSString *value = [MPIUtil tlvObjectFromTLVObject:config
                                                      tag:TLVTag_Version].data;
        [versions setValue:value forKey:key];
        
        config = [MPIUtil tlvObjectFromTLVObject:tlv
                                             tag:TLVTag_Configuration_Information
                                           index:index];
        index ++;
    }
    return [versions copy];
}


#pragma mark - Not available

- (instancetype)init {
    
    NSAssert(NO, @"This method is not available.");
    return nil;
}

@end