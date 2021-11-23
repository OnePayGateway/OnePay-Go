#import "MPIResponseData.h"
#import "DebugDefine.h"
#import "MPIBinaryUtil.h"
#import "MPITLVParser.h"


#pragma mark - Const/Enum/Struct
/// Chain response for PCB
static const Byte cPCBChain = 0x01;
/// Unsolicited response for PCB
static const Byte cPCBUnsolicited = MPIResponseData_cPCBUnsolicited;
/// SW1 for success response
static const Byte cSW1Success = 0x90;
/// SW2 for success response
static const Byte cSW2Success = 0x00;


@interface MPIResponseData ()
/// Original data
@property(nonatomic, readwrite, copy) NSData *raw;

/// NAD
@property(nonatomic, readwrite, copy) NSData *nad;
/// PCB
@property(nonatomic, readwrite, copy) NSData *pcb;
/// LEN
@property(nonatomic, readwrite, copy) NSData *len;

/// BODY
@property(nonatomic, readwrite, copy) NSData *body;
/// TLV
@property(nonatomic, readwrite, copy) NSArray *tlv;

/// SW1
@property(nonatomic, readwrite, copy) NSData *sw1;
/// SW2
@property(nonatomic, readwrite, copy) NSData *sw2;
/// LRC
@property(nonatomic, readwrite, copy) NSData *lrc;
@end


@implementation MPIResponseData


#pragma mark - Public Shared

/// Parse for multiple chunked MPI response data
+ (NSArray *)splitResponse:(NSData *)response {
    NSMutableArray *responses = [NSMutableArray array];

    unsigned long index = 0;
    const unsigned long responseLength = [response length];
    while (responseLength > index) {
        // Get data length
        //  NAD + PCB + LEN + BODY + LRC
        NSUInteger size = 3 + [MPIBinaryUtil intWithByte:[MPIBinaryUtil byteWithBytes:response index:index + 2]] + 1;
        [responses addObject:[response subdataWithRange:NSMakeRange(index, size)]];
        index += size;
    }
    return [responses copy];
}

/// Parse for MPI response data
+ (instancetype)parseResponse:(NSData *)response {
    MPIResponseData *mpi = [[MPIResponseData alloc] init];
    [mpi parseResponse:response];
    return mpi;
}

+ (instancetype)simpleSuccessResponse {
    MPIResponseData *mpi = [[MPIResponseData alloc] init];
    mpi.sw1 = [NSData dataWithBytes:&cSW1Success length:sizeof(cSW1Success)];
    mpi.sw2 = [NSData dataWithBytes:&cSW2Success length:sizeof(cSW2Success)];
    return mpi;
}


#pragma mark - Property

- (NSArray *)tlv {
    if (_tlv == nil) {
        @try {
            _tlv = [MPITLVParser decodeWithBytes:self.body];
        }
        @catch (id ex) {
            @throw;
        }
    }
    return _tlv;
}

- (NSString *)sw {
    return [[MPIBinaryUtil hexStringWithBytes:self.sw1] stringByAppendingString:[MPIBinaryUtil hexStringWithBytes:self.sw2]];
}


#pragma mark - Event

- (instancetype)copy {
    return [self copyWithZone:nil];
}

- (instancetype)copyWithZone:(NSZone *)zone {
    MPIResponseData *clone = [[[self class] allocWithZone:zone] init];
    [clone parseResponse:self.raw];
    return clone;
}

- (void)dealloc {
    _raw = nil;
    _nad = nil;
    _pcb = nil;
    _len = nil;
    _body = nil;
    _tlv = nil;
    _sw1 = nil;
    _sw2 = nil;
    _lrc = nil;
}


#pragma mark - Public

/// Check for result of MPI command request using SW1, SW2
- (BOOL)isSuccess {
    return (([MPIBinaryUtil byteWithBytes:self.sw1] == cSW1Success) &&
            ([MPIBinaryUtil byteWithBytes:self.sw2] == cSW2Success));
}

/// Check for Solicited response
- (BOOL)isSolicitedResponse {
    return ![self isUnsolicitedResponse];
}

/// Check for Chain response
- (BOOL)isChainResponse {
    return (([MPIBinaryUtil byteWithBytes:self.pcb] & cPCBChain) == cPCBChain);
}

/// Check for Unsolicited response
- (BOOL)isUnsolicitedResponse {
    return (([MPIBinaryUtil byteWithBytes:self.pcb] & cPCBUnsolicited) == cPCBUnsolicited);
}



#pragma mark - Private

/// Parse response data
- (void)parseResponse:(NSData *)response {
    NSMutableData *raw = [NSMutableData dataWithData:response];
    self.raw = [raw copy];
    
    unsigned char nad = [MPIBinaryUtil byteWithBytes:raw];
    self.nad = [NSData dataWithBytes:&nad length:sizeof(nad)];
    [raw replaceBytesInRange:NSMakeRange(0, 1) withBytes:nil length:0];
    
    unsigned char pcb = [MPIBinaryUtil byteWithBytes:raw];
    self.pcb = [NSData dataWithBytes:&pcb length:sizeof(pcb)];
    [raw replaceBytesInRange:NSMakeRange(0, 1) withBytes:nil length:0];
    
    unsigned char len = [MPIBinaryUtil byteWithBytes:raw];
    self.len = [NSData dataWithBytes:&len length:sizeof(len)];
    [raw replaceBytesInRange:NSMakeRange(0, 1) withBytes:nil length:0];
    
    unsigned char lrc = [MPIBinaryUtil byteWithBytes:raw index:raw.length - 1];
    self.lrc = [NSData dataWithBytes:&lrc length:sizeof(lrc)];
    [raw replaceBytesInRange:NSMakeRange(raw.length - 1, 1) withBytes:nil length:0];
    
    if (![self isChainResponse]) {
        unsigned char sw2 = [MPIBinaryUtil byteWithBytes:raw index:raw.length - 1];
        self.sw2 = [NSData dataWithBytes:&sw2 length:sizeof(sw2)];
        [raw replaceBytesInRange:NSMakeRange(raw.length - 1, 1) withBytes:nil length:0];
        
        unsigned char sw1 = [MPIBinaryUtil byteWithBytes:raw index:raw.length - 1];
        self.sw1 = [NSData dataWithBytes:&sw1 length:sizeof(sw1)];
        [raw replaceBytesInRange:NSMakeRange(raw.length - 1, 1) withBytes:nil length:0];
    }
    self.body = [raw copy];
}

@end
