#import <Foundation/Foundation.h>
#import "MPIDescription.h"
#import "MPIResponseData.h"


@interface MPIUtil: NSObject


#pragma mark - search tlv value

/// Retrieve tag data from child TLV object
+ (MPITLVObject *)tlvObjectFromTLVObject:(MPITLVObject *)tlv
                                     tag:(TLVTag)tag;

/// Retrieve tag data from child TLV object with index
+ (MPITLVObject *)tlvObjectFromTLVObject:(MPITLVObject *)tlv
                                     tag:(TLVTag)tag
                                   index:(NSUInteger)index;

/// Retrieve tag data from Array data
+ (MPITLVObject *)tlvObjectFromArray:(NSArray *)tlvs
                                 tag:(TLVTag)tag;

/// Retrieve tag data from Array data with index
+ (MPITLVObject *)tlvObjectFromArray:(NSArray *)tlvs
                                 tag:(TLVTag)tag
                               index:(NSUInteger)index;


/// Check for response, if it is connection event
+ (BOOL)isDeviceConnected:(MPIResponseData *)response;
/// Check for response, if it is reboot event
+ (BOOL)isDeviceRebooted:(MPIResponseData *)response;

/// Store configuration information with configuration name and revision
+ (NSDictionary *)configVersionsFromTLVObjectOfGetConfiguration:(MPITLVObject *)tlv;


#pragma mark - Not available

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
- (instancetype)new UNAVAILABLE_ATTRIBUTE;

@end