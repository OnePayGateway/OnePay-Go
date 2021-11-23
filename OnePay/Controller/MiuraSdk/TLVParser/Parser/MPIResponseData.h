#import <Foundation/Foundation.h>
#import "MPITLVObject.h"


static const Byte MPIResponseData_cPCBUnsolicited = 0x40;


#pragma mark - Interface
@interface MPIResponseData: NSObject <NSCopying>


#pragma mark - Public Property
/// Original data
@property(nonatomic, readonly, copy) NSData *raw;

/// NAD
@property(nonatomic, readonly, copy) NSData *nad;
/// PCB
@property(nonatomic, readonly, copy) NSData *pcb;
/// LEN
@property(nonatomic, readonly, copy) NSData *len;

/// BODY
@property(nonatomic, readonly, copy) NSData *body;
/// TLV
@property(nonatomic, readonly, copy) NSArray *tlv;

/// SW1
@property(nonatomic, readonly, copy) NSData *sw1;
/// SW2
@property(nonatomic, readonly, copy) NSData *sw2;
/// SW
@property(nonatomic, readonly, copy) NSString *sw;
/// LRC
@property(nonatomic, readonly, copy) NSData *lrc;


#pragma mark - Shared

/// Parse for MPI response data
+ (instancetype)parseResponse:(NSData *)response;
/// Parse for multiple chunked MPI response data
+ (NSArray *)splitResponse:(NSData *)response;
+ (instancetype)simpleSuccessResponse;


#pragma mark - Public
/// Check for result of MPI command request
- (BOOL)isSuccess;

/// Check for Solicited response
- (BOOL)isSolicitedResponse;

/// Check for Chain response
- (BOOL)isChainResponse;

/// Check for Unsolicite response
- (BOOL)isUnsolicitedResponse;

@end