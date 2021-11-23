#import "MiuraManager.h"

#import "DebugDefine.h"
#import "MPICommandExecutor.h"
#import "StringDefines.h"
#import "MPIUtil.h"
#import "MPIBinaryUtil.h"


static const NSInteger cReadBufferSize = 288;
static MiuraManager *sharedInstance;


@interface MiuraManager ()
@property(nonatomic, weak) EAAccessoryManager *accessoryManager;
@property(nonatomic, strong) EAAccessory *accessory;
@property(nonatomic, strong) EASession *session;
@property(nonatomic, weak) NSInputStream *inputStream;
@property(nonatomic, weak) NSOutputStream *outputStream;
@property(nonatomic, strong) NSMutableData *writeStack;
@property(nonatomic, strong) NSMutableData *readStack;
@property BOOL  commandInProgress;

@property(nonatomic, assign) CFReadStreamRef readStream;
@property(nonatomic, assign) CFWriteStreamRef writeStream;

@property(nonatomic, strong) NSMutableData *chainResponse;
@property(nonatomic, copy) NSArray *allProtocolNames;

@property(nonatomic, strong) UIImage *originalImage;
@property(nonatomic, copy) NSString * receipt;
@property(nonatomic, copy) UIImage *imagePng;

@property(nonatomic, strong) id< MiuraManagerDelegate > originalDelegate;

@property NSMutableArray *allSolicitedBlocks;
@end

@implementation ServiceCode
- (NSString *)stringValue {
    return [NSString stringWithFormat:@"%lu%lu%lu", (unsigned long)self.firstDigit, (unsigned long)self.secondDigit, (unsigned long)self.thirdDigit];
}
- (NSString *)description {
    return [NSString stringWithFormat:@"ServiceCode [%lu%lu%lu]", (unsigned long)self.firstDigit, (unsigned long)self.secondDigit, (unsigned long)self.thirdDigit];
}
@end

@implementation Track2Data
- (NSString *)description {
    return [NSString stringWithFormat:@"Track2Data [PAN=%@, exp=%@, serviceCode=%@]", self.PAN, self.expirationDate, self.serviceCode];
}
@end

@implementation CardStatus
- (NSString *)description {
    return [NSString stringWithFormat:@"CardStatus [isInserted=%d, isEMV=%d, isMSR=%d, isTrack1=%d, isTrack2=%d, isTrack3=%d]", self.isCardPresent, self.isEMVCompatible, self.isMSRDataAvailable, self.isTrack1DataAvailable, self.isTrack2DataAvailable, self.isTrack3DataAvailable];
}
@end

@implementation CardData
- (NSString *)description {
    return [NSString stringWithFormat:@"CardData [status=%@, ATR=%@, sred=%@, KSN=%@, track2=%@]", self.cardStatus, self.answerToReset, self.sredData, self.sredKSN, self.track2Data];
}
@end

@implementation OnlinePinResponse
- (NSString *)description {
    return [NSString stringWithFormat:@"OnlinePinResponse [pinData=%@, pinKSN=%@]", self.pinData, self.pinKSN];
}
@end

@implementation P2PEStatus
- (NSString *)description {
    return [NSString stringWithFormat:@"P2PEStatus [isInitialised=%d, isPINReady=%d, isSREDReady=%d]", self.isInitialised, self.isPINReady, self.isSREDReady];
}
@end

@implementation SoftwareInfo
- (NSString *)description {
    return [NSString stringWithFormat:@"SoftwareInfo [serialNo=%@, OSVersion=%@, OSType=%@, MPIVersion=%@, MPIType=%@]", self.serialNumber, self.OSVersion, self.OSType, self.MPIVersion, self.MPIType];
}
@end

@implementation MiuraManager


#pragma mark - Singleton

+ (instancetype)sharedInstance {
    
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        MiuraManager *instance = [[self alloc] initForInternal];
        if (instance == nil && sharedInstance) {
            instance = [sharedInstance initForInternal];
        }
    });
    
    return sharedInstance;
}

- (instancetype)initForInternal {
    if (self = [super init]) {
        _targetDevice = TargetDevice_PED;
        _allSolicitedBlocks = [NSMutableArray array];
    }
    return self;
}

#pragma mark - Queue of Solicited Blocks

- (void)queueSolicitedBlock:(MPIBlocksSolicited)block {
    if (self.commandInProgress == false)  {
        [self.allSolicitedBlocks addObject: block != nil ? [block copy] : [NSNull null]];
    } else {
        [self.allSolicitedBlocks insertObject:block != nil ? [block copy] : [NSNull null] atIndex:0];
    }
}

/**
 * Func: queueSolicitedBlockWithSwitch
 * Notes:
 * This functions is used to add a completion block to the end of the queue,
 * it then sets the commandInProgress flag to true.
 * The flag is used to put new messages at the start of the queue.
 * The reason we need to do this is that when MPI is doing certian commands which take some time, for example:
 * START TRANSACTION
 * START CONTACTLESS TRANSACTION
 * ONLINE PIN
 * it still allows commands to be processed but the response will come straight away and not wait for the running command to finish.
 */
-(void)queueSolicitedBlockWithSwitch:(MPIBlocksSolicited)block {
    [self queueSolicitedBlock:block ];
    self.commandInProgress = true;
}

- (MPIBlocksSolicited)dequeueSolicitedBlock {
    id block = [self.allSolicitedBlocks firstObject];
    if (block != nil) {
        [self.allSolicitedBlocks removeObjectAtIndex:0];
    }
    if (block == [NSNull null]) {
        block = nil;
    }
    return block;
}

#pragma mark - Getter / Setter

- (NSString *)deviceName {
    
    if (self.accessory) {
        return self.accessory.name;
    }
    return nil;
}

- (BOOL)isConnected {
    
    return (self.session != nil);
}

- (NSUInteger)readableBytesLength {
    
    return (self.readStack == nil ? 0 : self.readStack.length);
}


#pragma mark - Lifecycle / Super class overrides

+ (instancetype)allocWithZone:(NSZone *)zone {
    
    __block id instance = nil;
    
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        sharedInstance = [super allocWithZone:zone];
        instance = sharedInstance;
    });
    
    return instance;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    
    return self;
}

- (void)dealloc {
    
    [self closeSession];
    
    _delegate = nil;
    
    _protocolNames = nil;
    
    _chainResponse.length = 0;
    _chainResponse = nil;
}


#pragma mark - External accessory


#pragma mark - - EAAccessoryDelegate

- (void)accessoryDidDisconnect:(EAAccessory *)accessory {
    
    if (self.delegate) {
        [self.delegate miuraManager:self accessoryDidDisconnect:accessory];
    }
    else {
        ALog(@"Not found log : delegate and disconnect blocks not found");
    }
    
    [self closeSession];
}


#pragma mark - - Search

- (NSArray *)connectedAccessories {
    
    return [self connectedAccessoriesWithProtocolNames:self.protocolNames];
    ALog(@"Connected Accessories : %@", self.protocolNames);
    
}

- (NSArray *)connectedAccessoriesWithProtocolName:(NSString *)protocolName {
    
    return [self connectedAccessoriesWithProtocolNames:@[protocolName]];
    ALog(@"Connected accessories With protocol names : %@", self.protocolNames);
    
}

- (NSArray *)connectedAccessoriesWithProtocolNames:(NSArray *)protocolNames {
    
    self.accessoryManager = [EAAccessoryManager sharedAccessoryManager];
    
    NSMutableArray *accessories = [[self.accessoryManager connectedAccessories] mutableCopy];
    
    if (protocolNames == nil || protocolNames.count == 0) {
        NSMutableArray *candidateProtocolNames = [NSMutableArray array];
        [accessories enumerateObjectsUsingBlock:^(EAAccessory *accessory, NSUInteger idx, BOOL *stop) {
            [accessory.protocolStrings enumerateObjectsUsingBlock:^(NSString *name, NSUInteger idx, BOOL *stop) {
                if ([candidateProtocolNames containsObject:name] == NO) {
                    [candidateProtocolNames addObject:name];
                }
            }];
        }];
        if (candidateProtocolNames.count != 0) {
            self.allProtocolNames = [candidateProtocolNames copy];
        }
    }
    else {
        [accessories enumerateObjectsWithOptions:NSEnumerationReverse
                                      usingBlock:^(EAAccessory *accessory, NSUInteger idx, BOOL *stop) {
                                          __block BOOL existsProtocol = NO;
                                          __weak NSArray *protocolStrings = accessory.protocolStrings;
                                          [protocolNames enumerateObjectsUsingBlock:^(NSString *name, NSUInteger idx, BOOL *stop) {
                                              if ([protocolStrings containsObject:name]) {
                                                  existsProtocol = YES;
                                                  *stop = YES;
                                              }
                                          }];
                                          if (existsProtocol == NO) {
                                              [accessories removeObject:accessory];
                                          }
                                      }];
    }
    
    return [accessories copy];
}

- (BOOL)selectPriorityDevice:(MPIBlocksSelectAccessory)selectAccessory {
    
    NSArray *accessories = [self connectedAccessories];
    
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    NSString *priorityDeviceIdentify = [ud stringForKey:MIURASDK_USERDEFAULT_PRIORITY_DEVICE_IDENTIFY];
    
    self.priorityDeviceIdentify = nil;
    
    // Search possible PED from device list, if there is priority device list
    if (priorityDeviceIdentify && priorityDeviceIdentify.length != 0) {
        [accessories enumerateObjectsUsingBlock:^(EAAccessory *accessory, NSUInteger idx, BOOL *stop) {
            if ([accessory.serialNumber isEqualToString:priorityDeviceIdentify]) {
                self.priorityDeviceIdentify = accessory.serialNumber;
                *stop = YES;
            }
        }];
    }
    // Display candidate device, if there is no priority device list
    if (self.priorityDeviceIdentify == nil) {
        if (accessories != nil && accessories.count > 0 && selectAccessory) {
            selectAccessory(accessories);
        } else if (priorityDeviceIdentify != nil && priorityDeviceIdentify.length != 0) {
            self.priorityDeviceIdentify = priorityDeviceIdentify;
        }
    }
    
    if (self.priorityDeviceIdentify) {
        [ud setValue:self.priorityDeviceIdentify forKey:MIURASDK_USERDEFAULT_PRIORITY_DEVICE_IDENTIFY];
        [ud synchronize];
    }
    return (self.priorityDeviceIdentify != nil);
}


#pragma mark - - Open

- (BOOL)openSession {
    
    __block __weak EAAccessory *accessory = nil;
    NSArray *accessories = [self connectedAccessories];
    self.commandInProgress = false;
    if (self.priorityDeviceIdentify) {
        [accessories enumerateObjectsUsingBlock:^(EAAccessory *priorityCandidate, NSUInteger idx, BOOL *stop) {
            if ([priorityCandidate.serialNumber isEqualToString:self.priorityDeviceIdentify]) {
                accessory = priorityCandidate;
                *stop = YES;
            }
        }];
    }
    else {
        ALog(@"priorityDeviceIdentify is not specified. It must be set before openSession is called.");
        return NO;
    }
    
    if (self.protocolNames && self.protocolNames.count != 0) {
        return [self openSession:accessory protocolNames:self.protocolNames];
    }
    else {
        return [self openSession:accessory protocolNames:self.allProtocolNames];
    }
}

- (BOOL)openWiFiAccessory:(nonnull NSString *)ipAddress {
    
    if ([ipAddress isEqual:@""]) {
        
        if (!ipAddress) {
            ALog(@"Network address Failed:%@", ipAddress);
            return NO;
        }
        return YES;
    }
    
    if ([self isConnected]) {
        return YES;
    }
    
    CFStreamCreatePairWithSocketToHost(kCFAllocatorDefault,
                                       (__bridge CFStringRef) ipAddress, 6543,
                                       &_readStream, &_writeStream);
    
    if (self.readStream == nil || self.writeStream == nil)
        return NO;
    
    //Indicate that we want socket to be closed whenever streams are closed.
    CFReadStreamSetProperty(self.readStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
    
    if (!CFReadStreamOpen(self.readStream))
    {
        ALog(@"Error reading from Socket Host");
    }
    
    CFWriteStreamSetProperty(self.writeStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
    if (!CFWriteStreamOpen(self.writeStream))
    {
        ALog(@"Error write to Socket Host");
    }
    
    // Setup input stream.
    self.inputStream = (__bridge NSInputStream*)self.readStream;
    self.inputStream.delegate = self;
    [self.inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.inputStream open];
    
    // Setup output stream.
    self.outputStream = (__bridge NSOutputStream*)self.writeStream;
    self.outputStream.delegate = self;
    [self.outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.outputStream open];
    
    return YES;
    
}

- (BOOL)openSessionWithAccessorySerialNumber:(NSString *)serialNumber {
    
    EAAccessory *accessory = nil;
    NSArray *accessories = [self connectedAccessories];
    
    for (EAAccessory *obj in accessories) {
        if ([serialNumber isEqualToString:obj.serialNumber]) {
            accessory = obj;
            break;
        }
    }
    
    if (accessory) {
        [self openSession:accessory protocolName:accessory.protocolStrings[0]];
        return YES;
    }
    
    return NO;
}

- (BOOL)openSession:(EAAccessory *)accessory protocolName:(NSString *)protocolName {
    
    return [self openSession:accessory protocolNames:@[protocolName]];
}

- (BOOL)openSession:(EAAccessory *)accessory protocolNames:(NSArray *)protocolNames {
    
    if ([self isConnected]) {
        return YES;
    }
    
    __block NSString *connectionProtocolName = nil;
    [protocolNames enumerateObjectsUsingBlock:^(NSString *name, NSUInteger idx, BOOL *stop) {
        if ([[accessory protocolStrings] containsObject:name]) {
            connectionProtocolName = [name copy];
            *stop = YES;
        }
    }];
    
    if (connectionProtocolName == nil) {
        return NO;
    }
    
    self.accessory = accessory;
    if (self.accessory) {
        self.accessory.delegate = self;
        self.session = [[EASession alloc] initWithAccessory:self.accessory
                                                forProtocol:connectionProtocolName];
        
        if (self.session) {
            self.inputStream = self.session.inputStream;
            self.outputStream = self.session.outputStream;
            
            self.inputStream.delegate = self;
            self.outputStream.delegate = self;
            
            [self.inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
            [self.outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
            
            [self.inputStream open];
            [self.outputStream open];
            
            NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
            self.priorityDeviceIdentify = self.accessory.serialNumber;
            [ud setValue:self.priorityDeviceIdentify forKey:MIURASDK_USERDEFAULT_PRIORITY_DEVICE_IDENTIFY];
            [ud synchronize];
        }
    }
    
    return [self isConnected];
}

#pragma mark - - Close

- (void)closeSession {
    
#if DEBUG
    if ([self isConnected]) {
        ALog(@"Disconnect log : Device disconnected");
    }
#endif
    self.commandInProgress = false;
    [self.allSolicitedBlocks removeAllObjects];
    
    if (self.inputStream) {
        self.inputStream.delegate = nil;
        [self.inputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [self.inputStream close];
        self.inputStream = nil;
    }
    if (self.outputStream) {
        self.outputStream.delegate = nil;
        [self.outputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [self.outputStream close];
        self.outputStream = nil;
    }
    
    if (self.session != nil) {
        self.session = nil;
    }
    
    self.readStream = nil;
    self.writeStream = nil;
    
    self.writeStack = nil;
    self.readStack = nil;
    
    if (self.accessory) {
        self.accessory.delegate = nil;
    }
    self.accessory = nil;
    self.accessoryManager = nil;
}


#pragma mark - External accessory stream


#pragma mark - - NSStreamDelegate

- (void)stream:(NSStream *)stream handleEvent:(NSStreamEvent)eventCode {
    
    switch (eventCode) {
        case NSStreamEventNone:
        case NSStreamEventOpenCompleted:
        case NSStreamEventErrorOccurred:
        case NSStreamEventEndEncountered: {
            break;
        }
        case NSStreamEventHasBytesAvailable: {
            if ([stream isKindOfClass:[NSInputStream class]]) {
                [self readStreamData];
            }
            break;
        }
        case NSStreamEventHasSpaceAvailable: {
            if ([stream isKindOfClass:[NSOutputStream class]]) {
                [self writeStreamData];
            }
            break;
        }
        default: {
            break;
        }
    }
}


#pragma mark - - Writer

- (void)writeData:(NSData *)data {
    
    if (self.writeStack == nil) {
        self.writeStack = [[NSMutableData alloc] init];
    }
    [self.writeStack appendData:data];
    
    if (self.chainResponse == nil) {
        self.chainResponse = [[NSMutableData alloc] init];
    }
    else {
        self.chainResponse.length = 0;
    }
    [self writeStreamData];
}

- (void)writeStreamData {
    @try {
        if (self.outputStream && self.writeStack) {
            
            while ([self.outputStream hasSpaceAvailable] && self.writeStack.length > 0) {
                NSInteger bytesWritten = [self.outputStream write:self.writeStack.bytes
                                                        maxLength:self.writeStack.length];
                if (bytesWritten == -1) {
                    break;
                }
                else if (bytesWritten > 0) {
                    NSRange range = NSMakeRange(0, bytesWritten);
                    DLog(@"Write log : %@", [self.writeStack subdataWithRange:range].description);
                    [self.writeStack replaceBytesInRange:range withBytes:nil length:0];
                    
                }
            }
        }
        
    } @catch (NSException *e) {
        ALog(@"WriteStreamData Exception: %@",e);
    }
}

#pragma mark - - Reader

- (NSData *)readData {
    
    return [self readData:[self readableBytesLength]];
}

- (NSData *)readData:(NSUInteger)length {
    
    NSData *data = nil;
    
    if (self.readStack) {
        NSRange range = NSMakeRange(0, MIN(self.readStack.length, length));
        data = [self.readStack subdataWithRange:range];
        [self.readStack replaceBytesInRange:range withBytes:nil length:0];
    }
    return data;
}

- (void)readStreamData {
    
    if (self.inputStream) {
        unsigned char buf[cReadBufferSize];
        while ([self.inputStream hasBytesAvailable]) {
            NSInteger bytesRead = [self.inputStream read:buf maxLength:cReadBufferSize];
            if (self.readStack == nil) {
                self.readStack = [[NSMutableData alloc] init];
            }
            [self.readStack appendBytes:buf length:bytesRead];
        }
        NSData *rawData = [self readData];
        DLog(@"Read log : %@", rawData.description);
        [self receiveResponse:rawData];
    }
}


#pragma mark - Related to the MPI

- (void)receiveResponse:(NSData *)rawResponse {
    
    if (rawResponse == nil || rawResponse.length == 0) {
        return;
    }
    
    NSArray *responses = [MPIResponseData splitResponse:rawResponse];
    [responses enumerateObjectsUsingBlock:^(NSData *data, NSUInteger idx, BOOL *stop) {
        MPIResponseData *response = [MPIResponseData parseResponse:data];
        
        if ([response isChainResponse]) {
            if (self.chainResponse == nil) {
                self.chainResponse = [[NSMutableData alloc] init];
            }
            if (self.chainResponse.length == 0) {
                [self.chainResponse appendData:response.nad];
                
                unsigned char pcb;
                [response.pcb getBytes:&pcb length:1];
                pcb = pcb & MPIResponseData_cPCBUnsolicited;
                [self.chainResponse appendBytes:&pcb length:sizeof(pcb)];
                
                unsigned char len = 0xFF;
                [self.chainResponse appendBytes:&len length:sizeof(len)];
            }
            [self.chainResponse appendData:response.body];
        }
        else {
            if (self.chainResponse.length != 0) {
                [self.chainResponse appendData:response.body];
                [self.chainResponse appendData:response.sw1];
                [self.chainResponse appendData:response.sw2];
                [self.chainResponse appendData:response.lrc];
                
                response = [MPIResponseData parseResponse:self.chainResponse];
            }
            self.chainResponse.length = 0;
            
            if ([response isSolicitedResponse]) {
                MPIBlocksSolicited block = [self dequeueSolicitedBlock];
                if (block != nil) {
                    block(self, response);
                }
                else {
#if DEBUG
                    ALog(@"Not found log : delegate and solicited blocks not found");
#endif
                }
            }
            else if ([response isUnsolicitedResponse]) {
                if (self.delegate) {
                    [self parseUnsolicitedResponse:response];
                }
                else {
#if DEBUG
                    ALog(@"Not found log : delegate and unsolicited blocks not found");
#endif
                }
            }
        }
    }];
}

- (void)parseUnsolicitedResponse:(MPIResponseData *)response {
    if (![response isSuccess]) {
        ALog(@"Unsolicited response failed: %@", response);
        return;
    }
    
    if (!self.delegate) {
        ALog(@"Unsolicited response ignored! Reason: Delegate not set");
        return;
    }
    
    // CARD STATUS CHANGE
    MPITLVObject *cardStatusTag = [MPIUtil tlvObjectFromArray:response.tlv tag:TLVTag_Card_Status];
    if (cardStatusTag) {
        NSString *answerToReset = [MPIUtil tlvObjectFromArray:response.tlv tag:TLVTag_ICC_Answer_To_Reset].data;
        NSString *sredData      = [MPIUtil tlvObjectFromArray:response.tlv tag:TLVTag_SRED_Data].data;
        NSString *sredKSN       = [MPIUtil tlvObjectFromArray:response.tlv tag:TLVTag_SRED_KSN].data;
        NSString *maskedTrack2  = [MPIUtil tlvObjectFromArray:response.tlv tag:TLVTag_Masked_Track_2].data;
        
        NSData *cardStatusRaw = cardStatusTag.rawData;
        Byte insertStatus = [MPIBinaryUtil byteWithBytes:cardStatusRaw];
        Byte swipeStatus = [MPIBinaryUtil byteWithBytes:cardStatusRaw index:1];
        
        CardStatus *cardStatus = [CardStatus new];
        cardStatus.isCardPresent   = (insertStatus & (1 << 0)) > 0;
        cardStatus.isEMVCompatible = (insertStatus & (1 << 1)) > 0;
        cardStatus.isMSRDataAvailable    = (swipeStatus & (1 << 0)) > 0;
        cardStatus.isTrack1DataAvailable = (swipeStatus & (1 << 1)) > 0;
        cardStatus.isTrack2DataAvailable = (swipeStatus & (1 << 2)) > 0;
        cardStatus.isTrack3DataAvailable = (swipeStatus & (1 << 3)) > 0;
        
        CardData *cardData = [CardData new];
        cardData.raw = response.raw;
        cardData.cardStatus = cardStatus;
        cardData.answerToReset = answerToReset;
        cardData.sredData = sredData;
        cardData.sredKSN = sredKSN;
        cardData.track2Data = [self parseMaskedTrack2:maskedTrack2];
        
        [self.delegate miuraManager:self cardStatusChange:cardData];
        return;
    }
    
    // KEY PRESSED
    MPITLVObject *keyboardData = [MPIUtil tlvObjectFromArray:response.tlv tag:TLVTag_Keyboard_Data];
    if (keyboardData) {
        Byte keyCode = [MPIBinaryUtil byteWithBytes:keyboardData.rawData];
        
        [self.delegate miuraManager:self keyPressed:keyCode];
        return;
    }
    
    // DEVICE STATUS CHANGE
    MPITLVObject *statusCode = [MPIUtil tlvObjectFromArray:response.tlv tag:TLVTag_Status_Code];
    if (statusCode) {
        Byte statusCodeInt = [MPIBinaryUtil byteWithBytes:statusCode.rawData];
        NSString *statusText = [MPIUtil tlvObjectFromArray:response.tlv tag:TLVTag_Status_Text].data;
        
        [self.delegate miuraManager:self deviceStatusChange:statusCodeInt text:statusText];
        return;
    }
    
    // SCAN
    MPITLVObject *scanBarcodeTag = [MPIUtil tlvObjectFromArray:response.tlv tag:TLVTag_Bar_Code_Data];
    if (scanBarcodeTag) {
        NSString *barCodeText = [MPIUtil tlvObjectFromArray:response.tlv tag:TLVTag_Bar_Code_Data].data;
        
        [self.delegate miuraManager:self barCodeScan:barCodeText];
        return;
    }
    
    // PRINTER STATUS CHANGED
    MPITLVObject *printerSled = [MPIUtil tlvObjectFromArray:response.tlv tag:TLVTag_Printer_Status];
    if (printerSled) {
        Byte printerStatusChanged = [MPIBinaryUtil byteWithBytes:printerSled.rawData];
        [self.delegate miuraManager:self printerSledStatus:printerStatusChanged];
        return;
    }
    
    // USB STATUS 
    MPITLVObject *usbStatusChanged = [MPIUtil tlvObjectFromArray:response.tlv tag:TLVTag_Usb_Status];
    if (usbStatusChanged) {
        Byte usbChangeStatus = [MPIBinaryUtil byteWithBytes:usbStatusChanged.rawData];
        [self.delegate miuraManager:self usbStatusChange:usbChangeStatus];
        return;
    }
    
    // BATTERY STATUS CHANGE
    MPITLVObject *batteryStatusChange = [MPIUtil tlvObjectFromArray:response.tlv tag:TLVTag_Charging_Status];
    if (batteryStatusChange) {
        Byte batteryChangeStatus = [MPIBinaryUtil byteWithBytes:batteryStatusChange.rawData];
        [self.delegate miuraManager:self batteryStatusChange:batteryChangeStatus];
        return;
    }
    
    ALog(@"Unknown unsolicited message!");
    
}

- (Track2Data *)parseMaskedTrack2:(NSString *)track2String {
    NSString *track2Temp = [track2String copy];
    Track2Data *result = [Track2Data new];
    result.data = [track2String copy];
    
    // STX
    if ([track2Temp hasPrefix:@";"]) {
        track2Temp = [track2Temp substringFromIndex:1];
    } else {
        return nil;
    }
    
    // PAN/FS
    NSRange fsRange = [track2Temp rangeOfString:@"="];
    result.PAN = [track2Temp substringToIndex:fsRange.location];
    track2Temp = [track2Temp substringFromIndex:fsRange.location + 1];
    
    // Expiration date
    if ([track2Temp hasPrefix:@"="]) {
    } else {
        result.expirationDate = [track2Temp substringToIndex:4];
    }
    track2Temp = [track2Temp substringFromIndex:MAX(result.expirationDate.length, 1)];
    
    // Service code
    if ([track2Temp hasPrefix:@"="]) {
    } else {
        result.serviceCode = [self parseServiceCode:[track2Temp substringToIndex:3]];
    }
    
    return result;
}

- (ServiceCode *)parseServiceCode:(NSString *)serviceCodeString {
    if (serviceCodeString.length != 3) return nil;
    
    Byte first  = [[serviceCodeString substringWithRange:NSMakeRange(0, 1)] intValue];
    Byte second = [[serviceCodeString substringWithRange:NSMakeRange(1, 1)] intValue];
    Byte third  = [[serviceCodeString substringWithRange:NSMakeRange(2, 1)] intValue];
    
    ServiceCode *result = [ServiceCode new];
    result.firstDigit  = first;
    result.secondDigit = second;
    result.thirdDigit  = third;
    
    return result;
}


#pragma mark - Commands

- (void)displayText:(NSString *)text
         completion:(void(^)(BOOL success))completion {
    [MPICommandExecutor displayText:text completion:completion];
}

- (void)displayImageNamed:(NSString *)fileName
               completion:(void(^)(BOOL success))completion {
    [MPICommandExecutor displayImageNamed:fileName completion:completion];
}

- (void)keyboardStatus:(KeyPadStatusSettings)statusSetting
      backlightSetting:(BacklightSettings)backlightSetting
            completion:(MPIBlocksSolicited)completion {
    [MPICommandExecutor keyboardStatus:statusSetting backlightSetting:backlightSetting completion:completion];
}

- (void)magAndChipCardStatusEnable:(BOOL)enableStatus
                        completion:(void(^ _Nullable)(BOOL success))completion
{
    [MPICommandExecutor cardStatus:enableStatus enableAtr:FALSE enableTrack1:TRUE enableTrack2:TRUE enableTrack3:FALSE completion:completion];
}

- (void)cardStatus:(BOOL)enableUnsolicited
         enableAtr:(BOOL)enableAtr
      enableTrack1:(BOOL)enableTrack1
      enableTrack2:(BOOL)enableTrack2
      enableTrack3:(BOOL)enableTrack3
        completion:(void(^)(BOOL success))completion {
    [MPICommandExecutor cardStatus:enableUnsolicited enableAtr:enableAtr enableTrack1:enableTrack1 enableTrack2:enableTrack2 enableTrack3:enableTrack3 completion:completion];
}

- (void) setPedSleep:(void(^_Nullable)(ChargingStatus chargingStatus, NSUInteger batteryPercentage))completion {
    [MPICommandExecutor batteryStatus:TRUE setEvents:FALSE onChargingChange:FALSE onThresholdReached:FALSE completion:completion];
}

- (void)getBatteryStatus:(void(^_Nullable)(ChargingStatus chargingStatus, NSUInteger batteryPercentage))completion {
    [MPICommandExecutor batteryStatus:FALSE setEvents:FALSE onChargingChange:FALSE onThresholdReached:FALSE completion:completion];
}

- (void) setBatteryStatusEvents:(BOOL)onChargingChange
             onThresholdReached:(BOOL)onThresholdReached
                     completion:(void(^_Nullable)(ChargingStatus chargingStatus, NSUInteger batteryPercentage))completion {
    [MPICommandExecutor batteryStatus:FALSE setEvents:TRUE onChargingChange:onChargingChange onThresholdReached:onThresholdReached completion:completion];
}

- (void)barcodeScanStatus:(BOOL)enable
               completion:(void(^ _Nullable)(BOOL success))completion {
    [MPICommandExecutor barcodeScannerStatus:enable completion:completion];
}

- (void)queryCashDraw:(BOOL)openDraw
           completion:(void(^ _Nullable)(BOOL drawIsOpen))completion {
    [MPICommandExecutor queryCashDrawer:openDraw completion:completion];
}

- (void)spoolTextWithString:(nonnull NSString *) text
                 completion:(void(^ _Nullable)(PrinterSpoolControlError result))completion {
    [MPICommandExecutor spoolTextWithString:text completion:completion];
}

- (void)spoolImageWithFileName:(nonnull NSString *)fileName
                    completion:(void(^ _Nullable)(PrinterSpoolControlError result))completion {
    [MPICommandExecutor spoolImageWithFileName:fileName completion:completion];
}

- (void)spoolPrintWithCompletion:(void(^ _Nullable)(PrinterSpoolControlError result))completion {
    [MPICommandExecutor spoolPrintWithCompletion:completion];
}

- (void)printESCPOSWithString:(nonnull NSString *) text
                   completion:(void(^ _Nullable)(PrinterSpoolControlError result))completion {
    [MPICommandExecutor printESCPOSWithString:text completion:completion];
}

- (void)printerSledStatusEnable:(BOOL) statusMessageEnabled
                     completion:(void(^ _Nullable)(PrinterSledStatus))completion{
    [MPICommandExecutor printerSledStatusEnable:statusMessageEnabled completion:completion];
}

- (void)getConfigurationWithCompletion:(void(^)(NSDictionary<NSString *, NSString *> *configVersions))completion {
    [MPICommandExecutor getConfigurationWithCompletion:completion];
}

- (void)getDeviceCapabilitiesWithCompletion:(void(^)(NSDictionary<NSString *, NSString *> *capabilities))completion {
    [MPICommandExecutor getDeviceCapabilitiesWithCompletion:completion];
}

- (void)startTransactionWithType:(TransactionType)transactionType
                          amount:(NSUInteger)amount
                    currencyCode:(NSUInteger)currencyCode
                      completion:(MPIBlocksSolicited)completion {
    [MPICommandExecutor startTransactionWithType:transactionType amount:amount currencyCode:currencyCode completion:^(MiuraManager * _Nonnull manager, MPIResponseData * _Nonnull response) {
        self.commandInProgress = false;
        if (completion != nil) {
            completion(manager, response);
        }
    }];
}

- (void)continueTransaction:(MPITLVObject *)transactionInfo
                 completion:(MPIBlocksSolicited)completion {
    [MPICommandExecutor continueTransaction:transactionInfo completion:completion];
}

- (void)startContactlessTransactionWithType:(TransactionType)transactionType
                                     amount:(NSUInteger)amount
                               currencyCode:(NSUInteger)currencyCode
                                 completion:(nullable MPIBlocksSolicited)completion{
    [MPICommandExecutor startContactlessTransactionWithType:transactionType amount:amount currencyCode:currencyCode languagePreference:NULL completion:^(MiuraManager * _Nonnull manager, MPIResponseData * _Nonnull response)  {
        self.commandInProgress = false;
        if (completion != nil) {
            completion(manager, response);
        }
    }];
}

- (void)startContactlessTransactionWithType:(TransactionType)transactionType
                                     amount:(NSUInteger)amount
                               currencyCode:(NSUInteger)currencyCode
                         languagePreference:(nonnull NSString *)languagePreference
                                 completion:(nullable MPIBlocksSolicited)completion {
    [MPICommandExecutor startContactlessTransactionWithType:transactionType amount:amount currencyCode:currencyCode languagePreference:languagePreference completion:^(MiuraManager * _Nonnull manager, MPIResponseData * _Nonnull response)  {
        self.commandInProgress = false;
        if (completion != nil) {
            completion(manager, response);
        }
    }];
}

- (void)abortTransactionWithCompletion:(void(^_Nullable)(BOOL result))completion {
    [MPICommandExecutor abortWithCompletion:completion];
}

- (void)onlinePinWithAmount:(NSUInteger)amount
               currencyCode:(NSUInteger)currencyCode
                 track2Data:(NSString *)track2Data
                  labelText:(NSString *)labelText
                 completion:(void(^)(OnlinePinResponse *response))completion {
    [MPICommandExecutor onlinePinWithAmount:amount currencyCode:currencyCode track2Data:track2Data labelText:labelText completion:^(OnlinePinResponse *response) {
        self.commandInProgress = false;
        if (completion != nil) {
            completion(response);
        }
    }];
}

- (void)deleteFile:(NSString *)fileName completion:(MPIBlocksSolicited)completion {
    [MPICommandExecutor deleteFile:fileName completion:completion];
}

- (void)listFilesWithCompletion:(BOOL)selectFolder completion:(void(^)(NSMutableArray *listOfFiles))completion {
    [MPICommandExecutor listFilesWithCompletion:selectFolder completion:completion];
}

- (void)downloadSystemLogWithCompletion:(void(^)(NSData *fileData))completion {
    [MPICommandExecutor downloadSystemLogWithCompletion:completion];
}

- (void)downloadBinaryWithFileName:(NSString *)fileName
                        completion:(void(^)(NSData *fileData))completion {
    [MPICommandExecutor downloadBinaryWithfileName:fileName completion:completion];
}

- (void)deleteLogWithCompletion:(void (^)(BOOL success))completion {
    [MPICommandExecutor deleteLog:completion];
}

- (void)resetDeviceWithResetType:(ResetDeviceType)resetType
                      completion:(MPIBlocksSolicited)completion {
    [MPICommandExecutor resetDeviceWithResetType:resetType completion:completion];
}

- (void)getSystemClockWithCompletion:(void(^)(NSDate *date))completion {
    [MPICommandExecutor getSystemClockWithCompletion:completion];
}

- (void)setSystemClock:(NSDate *)date completion:(void(^)(BOOL success))completion {
    [MPICommandExecutor setSystemClock:date completion:completion];
}

- (void)uploadBinary:(NSData *)binary
             forName:(NSString *)fileName
          completion:(MPIBlocksSolicited)completion {
    [MPICommandExecutor uploadBinary:binary forName:fileName completion:completion];
}

- (void)p2peStatusWithCompletion:(void(^)(P2PEStatus *p2peStatus))completion {
    [MPICommandExecutor p2peStatusWithCompletion:completion];
}

- (void)p2peInitialiseWithCompletion:(BOOL)result
                          completion:(void(^)(RkiInitStatus result))completion {
    [MPICommandExecutor p2peInitialiseWithCompletion:result completion:completion];
}

- (void)p2peImportWithCompletion:(BOOL)result
                      completion:(void(^)(RkiImportStatus result))completion {
    [MPICommandExecutor p2peImportWithCompletion:result completion:completion];
}

- (void)getSoftwareInfoWithCompletion:(void(^ _Nullable)(SoftwareInfo * _Nullable softwareInfo))completion {
    [MPICommandExecutor getSoftwareInfoWithCompletion:completion];
}

- (void)applyUpdateWithCompletion:(void(^ _Nullable)(BOOL success))completion {
    [MPICommandExecutor applyUpdateWithCompletion:completion];
}

- (void)clearDeviceMemory:(void(^_Nullable)(BOOL success))completion {
    [MPICommandExecutor clearDeviceMemory:completion];
}

- (void)peripheralStatusCommand:(void(^)(NSMutableArray *peripheral))completion {
    [MPICommandExecutor peripheralStatusCommand:completion];
}

- (void)getBluetoothInfo:(void(^)(NSDictionary<NSString *, NSString *> * blueInfo))competion {
    [MPICommandExecutor getBluetoothInfo:competion];
}

- (void)getNumericData:(BOOL)autoEnt
         securePrompts:(NSData *)securePrompts
         numericFormat:(NSData *)numericFormat
        numericTimeout:(NSInteger)numericTimeout
         isBacklightOn:(BOOL) isBacklightOn
            completion:(void(^)(Numeric_Data_Result result, NSString *selectedItem))completion {
    [MPICommandExecutor getNumericData:autoEnt securePrompts:securePrompts numericFormat:numericFormat numericTimeout:numericTimeout
                         isBacklightOn:isBacklightOn completion:completion];
}

- (void)getDynamicTip:(BOOL)amount
      percentageValue:(NSData *)percentageValue
          templateTip:(NSData *)templateTip
         currencyCode:(NSData *)currencyCode
      currencyExponet:(NSData *)currencyExponet
    authorisedNumeric:(NSData *)authorisedNumeric
       dynamicTimeout:(NSInteger)dynamicTimeout
        keyPadSetting:(BacklightSettings)keyPadSetting
           completion:(void(^)(GetDynamicResult result, NSString *selectedItem))completion {
    [MPICommandExecutor getDynamicTip:amount percentageValue:percentageValue templateTip:templateTip currencyCode:currencyCode
                      currencyExponet:currencyExponet authorisedNumeric:authorisedNumeric dynamicTimeout:dynamicTimeout keyPadSetting:keyPadSetting completion:completion];
}

- (void)getSecurePan:(BOOL)isBacklightOn settings:(MPITLVObject *)settings completion:(MPIBlocksSolicited)completion {
    [MPICommandExecutor getSecurePan:true settings:settings completion:completion];
}

- (void)clearSecureData:(MPIBlocksSolicited)completion {
    [MPICommandExecutor clearSecureData:completion];
}

- (void)requestSecureCardData:(NSData *)securePrompts
               requestElement:(NSData *)requestElement
                secureTimeout:(NSInteger)secureTimeout
                keyPadSetting:(BacklightSettings)keyPadSetting
                   completion:(void(^)(SecureDataResult result, NSString *selectedItem))completion {
    [MPICommandExecutor requestSecureCardData:securePrompts requestElement:requestElement secureTimeout:secureTimeout keyPadSetting:keyPadSetting completion:completion];
}

- (void)retrieveSecureData:(MPIBlocksSolicited _Nonnull)completion {
    [MPICommandExecutor retrieveSecureData:completion];
}

- (void)getEmvHashValuesWithCompletion:(nonnull MPIBlocksSolicited)completion {
    [MPICommandExecutor getEmvHashValuesWithCompletion:completion];
}

- (void)getContactlessHashValuesWithCompletion:(void(^)(NSDictionary <NSString*, NSString*> *kernelVersions))completion {
    [MPICommandExecutor getContactlessHashValuesWithCompletion:completion];
}

- (void)getTouchScreenStatus:(nonnull MPIBlocksSolicited)completion {
    [MPICommandExecutor getTouchScreenStatus:completion];
}

- (void)getTouchScreenEnd:(nonnull MPIBlocksSolicited)completion {
    [MPICommandExecutor getTouchScreenEnd:completion];
}

- (void)getTouchScreenClear:(nonnull MPIBlocksSolicited)completion {
    [MPICommandExecutor getTouchScreenClear:completion];
}

- (void)getTouchScreenCalibrate:(nonnull MPIBlocksSolicited)completion {
    [MPICommandExecutor getTouchScreenCalibrate:completion];
}

- (void)retreiveSignCaptureExport:(void(^)(NSData *pngData))completion {
    [MPICommandExecutor retreiveSignCaptureExport:completion];
}

- (void)getTouchScreenBegin:(nonnull MPIBlocksSolicited)completion {
    [MPICommandExecutor getTouchScreenBegin:completion];
}

- (void)getTouchScreenExport:(NSString *) fileName
                  completion:(nonnull MPIBlocksSolicited) completion {
    [MPICommandExecutor getTouchScreenExport:fileName completion:completion];
}

- (void) getMenuOption: (nonnull NSString *) menuTitle
         showStatusBar: (BOOL) showStatusBar
         enlargeHeader: (BOOL) enlargeHeader
         enlargeFooter: (BOOL) enlargeFooter
             menuItems: (nonnull NSArray *) menuItems
            completion:(void(^_Nonnull)(GetMenuResult result, NSString * _Nullable selectedItem)) completion {
    [MPICommandExecutor getMenuOption:menuTitle showStatusBar:showStatusBar enlargeHeader:enlargeHeader enlargeFooter:enlargeFooter menuItems:menuItems completion:completion];
    
}

- (void) displayMediaCommand:(void(^_Nonnull)(BOOL success))completion  {
    [MPICommandExecutor displayMediaCommand:completion];
}

- (void)buzzerSound:(BOOL)synchronousSound
           duration:(NSUInteger)duration
            volData:(NSUInteger)volume
           freqData:(NSUInteger)frequency
         completion:(void(^_Nullable)(BOOL success))completion {
    [MPICommandExecutor buzzerSound:synchronousSound duration:duration volData:volume freqData:frequency completion:completion];
}

- (void)enableUsbStatus:(BOOL)enable completion:(void(^_Nullable)(BOOL usbStatus))completion{
    [MPICommandExecutor enableUsbStatus:enable completion:completion];
}

- (void)printUIImage:(UIImage *) image
          completion:(void(^)(PrinterSpoolControlError result))completion {
    
    NSData *fileData;
    NSString *strBase = @"image.png";
    
    if (image !=nil) {
        fileData = UIImagePNGRepresentation(image);
        [self uploadBinary:fileData forName:strBase completion:^(MiuraManager * _Nonnull manager, MPIResponseData * _Nonnull response) {
            
            if (![response isSuccess]) {
                if (completion != nil) {
                    completion(PrinterSpoolControlError_transferFailed);
                }
            } else {
                
                [self applyUpdateWithCompletion:^(BOOL success) {
                    if (!success) {
                        if (completion != nil) {
                            completion(PrinterSpoolControlError_transferFailed);
                        }
                    } else {
                        [self spoolImageWithFileName:strBase completion:^(PrinterSpoolControlError result) {
                            if (result != PrinterSpoolControlError_Success) {
                                if (completion != nil) {
                                    completion(result);
                                }
                            } else {
                                [self spoolPrintWithCompletion:^(PrinterSpoolControlError result) {
                                    if (completion != nil) {
                                        completion(result);
                                    }
                                }];
                            }
                        }];
                    }
                }];
            }
        }];
    }
    
}

@end
