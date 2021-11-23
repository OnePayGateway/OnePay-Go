#import "MPICommandCreator.h"
#import "MiuraManager.h"
#import "MPITLVObject.h"


#pragma mark - Const/Enum/Struct

typedef NS_ENUM (NSUInteger, PrologueIndex) {
    PrologueIndex_NAD = 0,
    PrologueIndex_PCB,
    PrologueIndex_LEN
};
//static const Byte cPrologueNAD = 0x01;
static const Byte cProloguePCB = 0x00;
static const Byte cPrologueLEN = 0x04;
//static const Byte cCommandPrologue[] = {cPrologueNAD, cProloguePCB, cPrologueLEN};


@implementation MPICommandCreator


#pragma mark - Shared

/// Create MPI command.
+ (NSData *)commandWithType:(MPICommandType)type {
    
    return [self commandWithType:type
                              p1:NULL];
}

/// Create MPI command.
+ (NSData *)commandWithType:(MPICommandType)type
                         p1:(Byte *)p1 {
    
    return [self commandWithType:type
                              p1:p1 p2:NULL];
}

/// Create MPI command.
+ (NSData *)commandWithType:(MPICommandType)type
                         p1:(Byte *)p1 p2:(Byte *)p2 {
    
    return [self commandWithType:type
                              p1:p1 p2:p2
                       dataField:nil];
}

/// Create MPI command.
+ (NSData *)commandWithType:(MPICommandType)type
                         p1:(Byte *)p1 p2:(Byte *)p2
                  dataField:(NSData *)dataField {
    
    return [self commandWithType:type
                              p1:p1 p2:p2
                       dataField:dataField
                              le:nil];
}

/// Create MPI command.
+ (NSData *)commandWithType:(MPICommandType)type
                         p1:(Byte *)p1 p2:(Byte *)p2
                  dataField:(NSData *)dataField
                         le:(Byte *)le {
    
    return [self commandWithHeader:type
                                p1:p1 p2:p2
                         dataField:dataField
                                le:le];
}

/// Create MPI command.
+ (NSData *)commandWithHeader:(NSUInteger)Header
                           p1:(Byte *)p1 p2:(Byte *)p2
                    dataField:(NSData *)dataField
                           le:(Byte *)le {
    
    Byte claTemp = (Header >> 24) & 0xFF;
    Byte insTemp = (Header >> 16) & 0xFF;
    Byte p1Temp = (p1 == NULL ? (Header >> 8) & 0xFF : *p1);
    Byte p2Temp = (p2 == NULL ? Header & 0xFF : *p2);
    return [self commandWithCla:&claTemp
                            ins:&insTemp
                             p1:&p1Temp
                             p2:&p2Temp
                      dataField:dataField
                             le:le];
}

/// Create MPI command.
+ (NSData *)commandWithCla:(Byte *)cla
                       ins:(Byte *)ins
                        p1:(Byte *)p1 p2:(Byte *)p2
                 dataField:(NSData *)dataField
                        le:(Byte *)le {
    
    NSMutableData *command = [NSMutableData data];

    Byte prologueNAD = [MiuraManager sharedInstance].targetDevice;
    Byte cCommandPrologue[] = {prologueNAD, cProloguePCB, cPrologueLEN};
    
    // Prologue
    NSMutableData *prologueTemp = [NSMutableData dataWithBytes:cCommandPrologue length:sizeof(cCommandPrologue)];
    
    // APDU - Header
    Byte header[] = {*cla, *ins, *p1, *p2};
    NSMutableData *headerTemp = [NSMutableData dataWithBytes:header length:sizeof(header)];
    
    // APDU - Body
    NSMutableData *bodyTemp = [NSMutableData data];
    if (dataField && dataField.length != 0) {
        // APDU - Body - Lc
        Byte lcTemp = (Byte)dataField.length;
        [bodyTemp appendBytes:&lcTemp length:sizeof(lcTemp)];
        // APDU - Body
        [bodyTemp appendData:dataField];
    }
    
    // APDU - Body - Le
    if (le != NULL) {
        [bodyTemp appendBytes:le length:1];
    }
    
    // Prologue - LEN
    if (bodyTemp.length != 0) {
        Byte len;
        [prologueTemp getBytes:&len range:NSMakeRange(PrologueIndex_LEN, 1)];
        len = len + bodyTemp.length;
        [prologueTemp replaceBytesInRange:NSMakeRange(PrologueIndex_LEN, 1)
                                withBytes:&len length:1];
    }
    
    [command appendData:prologueTemp];
    [command appendData:headerTemp];
    [command appendData:bodyTemp];
    
    return [self addLRC:command];
}


#pragma mark - Private Shared

+ (NSData *)addLRC:(NSMutableData *)data {
    
    Byte lrc = [self calculateLRC:data];
    
    [data appendBytes:&lrc length:sizeof(lrc)];
    return [data copy];
}

+ (Byte)calculateLRC:(NSData *)data {
    
    NSInteger checksum = 0;
    const Byte *byteData = data.bytes;
    NSUInteger dataLength = data.length;
    
    for (NSUInteger i = 0; i < dataLength; i++) {
        checksum = (checksum ^ byteData[i]) & 0xFF;
    }
    return (Byte)checksum;
}


#pragma mark - Not available

- (instancetype)init {
    
    NSAssert(NO, @"This method is not available.");
    return nil;
}

@end