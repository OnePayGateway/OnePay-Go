#import "MPICommandExecutor.h"
#import "MPIKernelHashValues.h"
#import "DebugDefine.h"
#import "MPIBinaryUtil.h"
#import "MPICommandCreator.h"
#import "MPITLVParser.h"
#import "StringDefines.h"
#import "MPIUtil.h"
#import "MPIBinaryUtil.h"
#import "DisplayMediaData.h"

typedef NS_OPTIONS(NSUInteger, AddBit) {
    AddBit_0 = (1 << 0),
    AddBit_1 = (1 << 1),
    AddBit_2 = (1 << 2),
    AddBit_3 = (1 << 3),
    AddBit_4 = (1 << 4),
    AddBit_5 = (1 << 5),
    AddBit_6 = (1 << 6),
    AddBit_7 = (1 << 7),
};

typedef NS_ENUM(NSInteger, CashDrawerMode){
    CashDrawer_Query = 0x00,
    CashDrawer_Open = 0x01,
};

typedef NS_ENUM(NSInteger, ShowMenu) {
    ShowMenu_Show_Menu = 0x00,
    ShowMenu_Append_Option = 0x01,
    ShowMenu_Clear_Options = 0x02,
};

@implementation MPICommandExecutor


#pragma mark - Execute MPI command

+ (NSData *)resetDevice:(id<MiuraManagerDelegate>)delegate
                   type:(ResetDeviceType)type {
    
    MiuraManager *manager = [MiuraManager sharedInstance];
    manager.delegate = delegate;
    
    NSData *command = [self resetDeviceCommand:type];
    [manager writeData:command];
    
    return command;
}

+ (void)resetDeviceWithResetType:(ResetDeviceType)resetType
                      completion:(MPIBlocksSolicited)completion {
    
    MiuraManager *manager = [MiuraManager sharedInstance];
    [manager queueSolicitedBlock:completion];
    
    NSData *command = [self resetDeviceCommand:resetType];
    [manager writeData:command];
}

+ (void)getSoftwareInfoWithCompletion:(void(^)(SoftwareInfo *softwareInfo))completion {
    
    MiuraManager *manager = [MiuraManager sharedInstance];
    
    [manager queueSolicitedBlock:^(MiuraManager * manager, MPIResponseData * response) {
        if (completion == nil) return;
        if (!response.isSuccess) {
            completion(nil);
            return;
        }
        
        // Parse generic response
        NSString *serialNo   = [MPIUtil tlvObjectFromArray:response.tlv tag: TLVTag_Interface_Device_Serial_Number].data;
        NSString *osType     = [MPIUtil tlvObjectFromArray:response.tlv tag: TLVTag_Identifier index: 1].data;
        NSString *osVersion  = [MPIUtil tlvObjectFromArray:response.tlv tag: TLVTag_Version index: 1].data;
        NSString *mpiType    = [MPIUtil tlvObjectFromArray:response.tlv tag: TLVTag_Identifier].data;
        NSString *mpiVersion = [MPIUtil tlvObjectFromArray:response.tlv tag: TLVTag_Version].data;
        
        SoftwareInfo *result = [SoftwareInfo new];
        result.serialNumber = serialNo;
        result.OSVersion = osVersion;
        result.OSType = osType;
        result.MPIVersion = mpiVersion;
        result.MPIType = mpiType;
        
        completion(result);
        
    }];
    
    NSData *command = [self resetDeviceCommand:ResetDeviceType_Soft_Reset];
    [manager writeData:command];
}

+ (void)applyUpdateWithCompletion:(void(^)(BOOL success))completion {
    
    MiuraManager *manager = [MiuraManager sharedInstance];
    [manager queueSolicitedBlock:^(MiuraManager * manager, MPIResponseData * response) {
        if (completion == nil) return;
        completion([response isSuccess]);
    }];
    
    NSData *command = [self resetDeviceCommand:ResetDeviceType_Hard_Reset];
    [manager writeData:command];
}

+ (void)clearDeviceMemory:(void(^)(BOOL success))completion {
    
    MiuraManager *manager = [MiuraManager sharedInstance];
    [manager queueSolicitedBlock:^(MiuraManager * manager, MPIResponseData * response) {
        if (completion == nil) return;
        completion([response isSuccess]);
    }];
    
    NSData *command = [self resetDeviceCommand:ResetDeviceType_Clear_Files];
    [manager writeData:command];
}

+ (NSData *)resetDeviceCommand:(ResetDeviceType)type {
    
    Byte p1 = type & 0xFF;
    Byte *p_p1 = &p1;
    
    return [MPICommandCreator commandWithType:MPICommandType_Reset_Device
                                           p1:p_p1 p2:NULL
                                    dataField:nil];
}

+ (NSData *)resetDevice:(ResetDeviceType)type
              sizeOfMsd:(int)sizeOfMsd
            volumeLabel:(NSString *)volumeLabel
             completion:(MPIBlocksSolicited)completion {
    
    MiuraManager *manager = [MiuraManager sharedInstance];
    [manager queueSolicitedBlock:completion];
    
    NSData *command = [self resetDeviceCommand:type
                                     sizeOfMsd:sizeOfMsd
                                   volumeLabel:volumeLabel];
    [manager writeData:command];
    
    return command;
}

+ (NSData *)resetDeviceCommand:(ResetDeviceType)type
                     sizeOfMsd:(int)sizeOfMsd
                   volumeLabel:(NSString *)volumeLabel {
    
    Byte p1 = type & 0xFF;
    Byte *p_p1 = &p1;
    Byte p2;
    Byte *p_p2 = NULL;
    NSData *dataField = nil;
    
    switch (type) {
        case ResetDeviceType_Soft_Reset:
        case ResetDeviceType_Hard_Reset:
        case ResetDeviceType_Clear_Files: {
            // To implement, if necessary
            break;
        }
        case ResetDeviceType_Clear_Files_And_Reinitialise_MSD: {
            p2 = sizeOfMsd & 0xFF;
            p_p2 = &p2;
            if ([volumeLabel canBeConvertedToEncoding:NSASCIIStringEncoding]) {
                dataField = [volumeLabel dataUsingEncoding:NSASCIIStringEncoding];
            }
            break;
        }
    }
    
    return [MPICommandCreator commandWithType:MPICommandType_Reset_Device
                                           p1:p_p1 p2:p_p2
                                    dataField:dataField];
}

+ (void)getConfigurationWithCompletion:(void(^)(NSDictionary<NSString *, NSString *> *configVersions))completion {
    
    MiuraManager *manager = [MiuraManager sharedInstance];
    [manager queueSolicitedBlock:^(MiuraManager *manager, MPIResponseData *response) {
        if (!response.isSuccess) {
            if (completion != nil) completion(nil);
            return;
        }
        
        MPITLVObject *responseData = [MPIUtil tlvObjectFromArray:response.tlv tag:TLVTag_Response_Data];
        NSDictionary *configVersions = [MPIUtil configVersionsFromTLVObjectOfGetConfiguration:responseData];
        
        completion(configVersions);
    }];
    
    NSData *command = [self getConfigurationCommand];
    [manager writeData:command];
}

+ (NSData *)getConfigurationCommand {
    
    return [MPICommandCreator commandWithType:MPICommandType_Get_Configuration];
}

+ (void)getDeviceCapabilitiesWithCompletion:(void(^)(NSDictionary<NSString *, NSString *> *capabilities))completion {
    
    __block int i = 0;
    __block MPITLVObject *config = nil;
    
    MiuraManager *manager = [MiuraManager sharedInstance];
    [manager queueSolicitedBlock:^(MiuraManager *manager, MPIResponseData *response) {
        if (!response.isSuccess) {
            if (completion != nil) completion(nil);
            return;
        }
        
        NSMutableDictionary<NSString *, NSString *> *result = [NSMutableDictionary new];
        
        do {
            config = [MPIUtil tlvObjectFromArray:response.tlv tag:TLVTag_Configuration_Information index:i];
            if (config == nil) {
                break;
            }
            i++;
            
            NSString *identifier = [MPIUtil tlvObjectFromTLVObject:config tag:TLVTag_Identifier].data;
            NSString *version = [MPIUtil tlvObjectFromTLVObject:config tag:TLVTag_Version].data ?: @"";
            [result setValue:version forKey:identifier];
            
        } while (config != nil);
        
        completion(result);
    }];
    
    NSData *command = [self getDeviceInfoCommand];
    [manager writeData:command];
}

+ (NSData *)getDeviceInfoCommand {
    
    return [MPICommandCreator commandWithType:MPICommandType_Get_Device_Info];
}

+ (NSData *)selectFile:(SelectFileMode)mode
              fileName:(NSString *)fileName
            completion:(MPIBlocksSolicited)completion {
    
    MiuraManager *manager = [MiuraManager sharedInstance];
    [manager queueSolicitedBlock:completion];
    
    NSData *command = [self selectFileCommand:mode
                                     fileName:fileName];
    [manager writeData:command];
    
    return command;
}

+ (NSData *)selectFileCommand:(SelectFileMode)mode
                     fileName:(NSString *)fileName {
    
    Byte p1 = mode & 0xFF;
    Byte *p_p1 = &p1;
    NSData *dataField = nil;
    if ([fileName canBeConvertedToEncoding:NSASCIIStringEncoding]) {
        dataField = [fileName dataUsingEncoding:NSASCIIStringEncoding];
    }
    
    return [MPICommandCreator commandWithType:MPICommandType_Select_File
                                           p1:p_p1 p2:NULL
                                    dataField:dataField];
}

+ (NSData *)deleteFile:(NSString *)fileName
            completion:(MPIBlocksSolicited)completion {
    
    MiuraManager *manager = [MiuraManager sharedInstance];
    [manager queueSolicitedBlock:completion];
    
    NSData *command = [self deleteFileCommand:fileName];
    [manager writeData:command];
    
    return command;
}

+ (NSData *)deleteFileCommand:(NSString *)fileName {
    
    Byte p1 = 0x00;
    Byte *p_p1 = &p1;
    Byte p2 = 0x00;
    Byte *p_p2 = &p2;
    
    NSData *dataField = nil;
    
    if ([fileName canBeConvertedToEncoding:NSASCIIStringEncoding]) {
        dataField = [fileName dataUsingEncoding:NSASCIIStringEncoding];
    }
    
    return [MPICommandCreator commandWithType:MPICommandType_Delete_File
                                           p1:p_p1 p2:p_p2
                                    dataField:dataField];
}

+ (void)listFilesWithCompletion:(BOOL)selectFolder
                     completion:(void(^)(NSMutableArray *listOfFiles))completion {
    
    __block int i = 0;
    __block MPITLVObject *getList = nil;
    
    MiuraManager *manager = [MiuraManager sharedInstance];
    [manager queueSolicitedBlock:^(MiuraManager *manager, MPIResponseData *response) {
        if (!response.isSuccess) {
            if (completion != nil) completion(nil);
            return;
        }
        
        NSMutableArray *listOfFiles = [NSMutableArray new];
        
        do {
            getList = [MPIUtil tlvObjectFromArray:response.tlv tag:TLVTag_Response_Data index:i];
            if (getList == nil) {
                break;
            }
            i++;
            
            MPITLVObject *identifier = [MPIUtil tlvObjectFromTLVObject:getList tag:TLVTag_Identifier];
            MPITLVObject *fileSpaceUsed = [MPIUtil tlvObjectFromTLVObject:getList tag:TLVTag_File_Used];
            MPITLVObject *fileSlotsUsed = [MPIUtil tlvObjectFromTLVObject:getList tag:TLVTag_File_Space];
            
            if (fileSpaceUsed != nil || fileSlotsUsed != nil || identifier != nil) {
                [listOfFiles addObject:identifier];
                [listOfFiles addObject:fileSpaceUsed];
                [listOfFiles addObject:fileSlotsUsed];
            } else {
                DLog(@"Get list response - failed");
            }
            
        } while (getList != nil);
        
        completion(listOfFiles);
        
    }];
    
    NSData *command = [self listFileCommand:selectFolder];
    [manager writeData:command];
}

+ (NSData *)listFileCommand:(BOOL)selectFolder {
    
    Byte p1 = 0x00;
    Byte *p_p1 = &p1;
    Byte p2 = (selectFolder ? 0x00 : 0x01);
    Byte *p_p2 = &p2;
    
    return [MPICommandCreator commandWithType:MPICommandType_List_Files
                                           p1:p_p1 p2:p_p2];
}

+ (NSData *)readBinary:(long)fileSize
                offset:(long)offset
                  size:(long)size
            completion:(MPIBlocksSolicited)completion {
    
    MiuraManager *manager = [MiuraManager sharedInstance];
    [manager queueSolicitedBlock:completion];
    
    NSData *command = [self readBinaryCommand:fileSize
                                       offset:offset
                                         size:size];
    [manager writeData:command];
    
    return command;
}

+ (NSData *)readBinaryCommand:(long)fileSize
                       offset:(long)offset
                         size:(long)size {
    
    if (size > 0xFC) {
        size = 0xFC;
    }
    if (fileSize < offset + size) {
        size = fileSize - offset;
    }
    
    Byte p1;
    Byte *p_p1 = &p1;
    Byte p2;
    Byte *p_p2 = &p2;
    NSData *dataField = nil;
    Byte le = size & 0xFF;
    Byte *p_le = &le;
    
    if (offset <= 0x7FFF) {
        p1 = (offset >> 8) & 0xFF;
        p2 = offset & 0xFF;
    } else if (offset <= 0x7FFFFF) {
        p1 = 0x80 + ((offset >> 16) & 0xFF);
        p2 = (offset >> 8) & 0xFF;
        Byte additionsOffset = offset & 0xFF;
        dataField = [NSData dataWithBytes:&additionsOffset length:1];
    }
    
    return [MPICommandCreator commandWithType:MPICommandType_Read_Binary
                                           p1:p_p1 p2:p_p2
                                    dataField:dataField
                                           le:p_le];
}

+ (void)downloadSystemLogWithCompletion:(void(^)(NSData *fileData))completion {
    
    [self systemLog:SystemLogMode_Archive_Mode completion:^(MiuraManager *manager, MPIResponseData *response) {
        if (!response.isSuccess) {
            if (completion != nil) completion(nil);
            return;
        }
        
        NSString *logFileName = manager.targetDevice == TargetDevice_POS ? @"rpi.log" : @"mpi.log";
        
        [self downloadBinaryWithfileName:logFileName completion:^(NSData *fileData) {
            
            if (fileData == nil) {
                completion(nil);
            }
            
            [self systemLog:SystemLogMode_Remove_Mode completion:^(MiuraManager *manager, MPIResponseData *response) {
                if (!response.isSuccess) {
                    if (completion != nil) completion(nil);
                    return;
                }
                
                if (completion != nil) {
                    completion(fileData);
                }
            }];
        }];
    }];
}

static void (^downloadFileBlock)(void) = nil;

+ (void) downloadBinaryWithfileName:(NSString *)fileName completion:(void(^)(NSData * fileData)) completion {
    
    [self selectFile:SelectFileMode_Append_Mode fileName:fileName completion:^(MiuraManager *manager, MPIResponseData *response) {
        
        if (!response.isSuccess) {
            if (completion != nil) completion(nil);
            return;
        }
        
        NSData *sizeData = [MPIUtil tlvObjectFromArray:response.tlv tag:TLVTag_File_Size].rawData;
        
        __block NSUInteger fileSize = [MPIBinaryUtil intWithHexString:[MPIBinaryUtil hexStringWithBytes:sizeData]];
        __block NSMutableData *fileData = [NSMutableData data];
        __block NSInteger bufferOffset = 0;
        
        // Block to be called in recursion
        downloadFileBlock = ^(void) {
            long bufferSize = 256;
            if (bufferOffset + bufferSize > fileSize) {
                bufferSize = fileSize - bufferOffset;
            }
            [self readBinary:fileSize offset:bufferOffset size:bufferSize completion:^(MiuraManager *manager, MPIResponseData *response) {
                if (!response.isSuccess) {
                    if (completion != nil) completion(nil);
                    return;
                }
                
                [fileData appendData:response.body];
                bufferOffset += response.body.length; //bufferSize;
                if (fileSize > bufferOffset) {
                    downloadFileBlock();
                    return;
                }
                /*Assumtion here is that the data read in is bufferOffset is equal to the fileSize so we are done*/
                if (completion != nil) {
                    completion(fileData);
                    return;
                }
            }];
        };
        
        downloadFileBlock();
    }];
}

+ (void)deleteLog:(void (^)(BOOL success))completion {
    
    MiuraManager *manager = [MiuraManager sharedInstance];
    
    [manager queueSolicitedBlock:^(MiuraManager *manager, MPIResponseData *response) {
        if (completion == nil) {
            return;
        }
        completion([response isSuccess]);
    }];
    NSData *command = [self deleteLogCommand];
    [manager writeData:command];
}

+ (NSData *)deleteLogCommand {
    
    Byte p1 = 0x01;
    Byte *p_p1 = &p1;
    
    return [MPICommandCreator commandWithType:MPICommandType_System_Log
                                           p1:p_p1];
}

+ (NSData *)streamBinary:(id<MiuraManagerDelegate>)delegate
              needMd5sum:(BOOL)needMd5sum
                  binary:(NSData *)binary
                  offset:(long)offset
                    size:(long)size
                 timeout:(long)timeout {
    
    MiuraManager *manager = [MiuraManager sharedInstance];
    manager.delegate = delegate;
    
    NSData *command = [self streamBinaryCommand:needMd5sum
                                         binary:binary
                                         offset:offset
                                           size:size
                                        timeout:timeout];
    [manager writeData:command];
    [manager writeData:binary];
    
    return command;
}

+ (NSData *)streamBinary:(BOOL)needMd5sum
                  binary:(NSData *)binary
                  offset:(long)offset
                    size:(long)size
                 timeout:(long)timeout
              completion:(MPIBlocksSolicited)completion {
    
    MiuraManager *manager = [MiuraManager sharedInstance];
    [manager queueSolicitedBlock:completion];
    
    NSData *command = [self streamBinaryCommand:needMd5sum
                                         binary:binary
                                         offset:offset
                                           size:size
                                        timeout:timeout];
    [manager writeData:command];
    [manager writeData:binary];
    
    return command;
}

+ (void)streamBinary:(NSData *)binary
             timeout:(long)timeout
          completion:(MPIBlocksSolicited)completion {
    [self streamBinary:NO
                binary:binary
                offset:0
                  size:binary.length
               timeout:timeout
            completion:completion];
}

+ (void)uploadBinary:(NSData *)binary
             forName:(NSString *)fileName
          completion:(MPIBlocksSolicited)completion {
    [self selectFile:SelectFileMode_Truncate_Mode fileName:fileName completion:^(MiuraManager *manager, MPIResponseData *response) {
        if (!response.isSuccess && completion != nil) {
            completion(manager, response);
            return;
        }
        
        [self streamBinary:binary timeout:100 completion:^(MiuraManager *manager, MPIResponseData *response) {
            if (completion != nil) {
                completion(manager, response);
            }
        }];
    }];
}

+ (NSData *)streamBinaryCommand:(BOOL)needMd5sum
                         binary:(NSData *)binary
                         offset:(long)offset
                           size:(long)size
                        timeout:(long)timeout {
    
    Byte p1 = (needMd5sum ? 0x01 : 0x00);
    Byte *p_p1 = &p1;
    NSMutableData *dataField = [[NSMutableData alloc] init];
    
    // Offset tag
    unsigned char streamOffset[] = {(offset >> 16) & 0xFF, (offset >> 8) & 0xFF, offset & 0xFF};
    [dataField appendData:[MPITLVParser encodeWithTag:TLVTag_Stream_Offset
                                                value:[NSData dataWithBytes:&streamOffset length:sizeof(streamOffset)]]];
    
    // Size tag
    unsigned char streamSize[] = {(size >> 16) & 0xFF, (size >> 8) & 0xFF, size & 0xFF};
    [dataField appendData:[MPITLVParser encodeWithTag:TLVTag_Stream_Size
                                                value:[NSData dataWithBytes:&streamSize length:sizeof(streamSize)]]];
    
    // Timeout tag
    unsigned char streamTimeout[] = {timeout & 0xFF};
    [dataField appendData:[MPITLVParser encodeWithTag:TLVTag_Stream_timeout
                                                value:[NSData dataWithBytes:&streamTimeout length:sizeof(streamTimeout)]]];
    
    return [MPICommandCreator commandWithType:MPICommandType_Stream_Binary
                                           p1:p_p1 p2:NULL
                                    dataField:[MPITLVParser encodeWithTag:TLVTag_Command_Data
                                                                    value:dataField]];
}

+ (void)cardStatus:(BOOL)enableUnsolicited
         enableAtr:(BOOL)enableAtr
      enableTrack1:(BOOL)enableTrack1
      enableTrack2:(BOOL)enableTrack2
      enableTrack3:(BOOL)enableTrack3
        completion:(void (^)(BOOL success))completion {
    
    
    // Note: Since the protocol doesn't provide solicited response for this request,
    // instead of queueing completion block - we're firing it manually here.
    
    MiuraManager *manager = [MiuraManager sharedInstance];
    
    NSData *command = [self cardStatusCommand:enableUnsolicited
                                    enableAtr:enableAtr
                                 enableTrack1:enableTrack1
                                 enableTrack2:enableTrack2
                                 enableTrack3:enableTrack3];
    
    [manager writeData:command];
    
    // Fire completion block immediately
    if (completion) {
        MPIResponseData *response = [MPIResponseData simpleSuccessResponse];
        completion([response isSuccess]);
    }
}

+ (NSData *)cardStatusCommand:(BOOL)enableUnsolicited
                    enableAtr:(BOOL)enableAtr
                 enableTrack1:(BOOL)enableTrack1
                 enableTrack2:(BOOL)enableTrack2
                 enableTrack3:(BOOL)enableTrack3 {
    
    Byte p1 = 0x00;
    Byte *p_p1 = &p1;
    
    if (enableUnsolicited) {
        p1 += AddBit_0;
    }
    if (enableAtr) {
        p1 += AddBit_1;
    }
    if (enableTrack1) {
        p1 += AddBit_2;
    }
    if (enableTrack2) {
        p1 += AddBit_3;
    }
    if (enableTrack3) {
        p1 += AddBit_4;
    }
    
    return [MPICommandCreator commandWithType:MPICommandType_Card_Status
                                           p1:p_p1];
}

+ (void)keyboardStatus:(KeyPadStatusSettings)statusSetting
      backlightSetting:(BacklightSettings)backlightSetting
            completion:(MPIBlocksSolicited)completion {
    
    MiuraManager *manager = [MiuraManager sharedInstance];
    [manager queueSolicitedBlock:completion];
    
    NSData *command = [self keyboardStatusCommand:statusSetting
                                 backlightSetting:backlightSetting];
    [manager writeData:command];
}

+ (NSData *)keyboardStatusCommand:(KeyPadStatusSettings)statusSetting
                 backlightSetting:(BacklightSettings)backlightSetting {
    
    Byte p1 = statusSetting;
    Byte *p_p1 = &p1;
    Byte p2 = backlightSetting;
    Byte *p_p2 = &p2;
    
    return [MPICommandCreator commandWithType:MPICommandType_Keyboard_Status
                                           p1:p_p1 p2:p_p2];
}

+ (NSData *)batteryStatus:(BOOL)intoSleep
                setEvents:(BOOL)setEvents
         onChargingChange:(BOOL)onChargingChange
       onThresholdReached:(BOOL)onThresholdReached
               completion:(void(^)(ChargingStatus chargingStatus, NSUInteger batteryPercentage))completion {
    
    MiuraManager *manager = [MiuraManager sharedInstance];
    [manager queueSolicitedBlock:^(MiuraManager *manager, MPIResponseData *response) {
        if (completion == nil) return;
        
        MPITLVObject *dataObj = [MPIUtil tlvObjectFromArray:response.tlv tag:TLVTag_Charging_Status];
        MPITLVObject *percentObj = [MPIUtil tlvObjectFromArray:response.tlv tag:TLVTag_Battery_Percentage];
        Byte dataInt    = [MPIBinaryUtil byteWithBytes:dataObj.rawData];
        Byte percentInt = [MPIBinaryUtil byteWithBytes:percentObj.rawData];
        
        completion(dataInt, percentInt);
    }];
    
    NSData *command = [self batteryStatusCommand:intoSleep
                                       setEvents:setEvents
                                onChargingChange:onChargingChange
                              onThresholdReached:onThresholdReached];
    
    [manager writeData:command];
    
    return command;
}

+ (NSData *)batteryStatusCommand:(BOOL)intoSleep
                       setEvents:(BOOL)setEvents
                onChargingChange:(BOOL)onChargingChange
              onThresholdReached:(BOOL)onThresholdReached {
    
    Byte p1 = 0x00;
    Byte p2 = 0x00;
    Byte *p_p1 = &p1;
    Byte *p_p2 = &p2;
    
    if (intoSleep) {
        p1 = 1;
    }
    
    if (setEvents) {
        p1 = 3;
        if (onChargingChange) {
            p2 += AddBit_0;
        }
        if (onThresholdReached) {
            p2 += AddBit_1;
        }
    }
    
    return [MPICommandCreator commandWithType:MPICommandType_Battery_Status
                                           p1:p_p1
                                           p2:p_p2];
}

+ (void)peripheralStatusCommand:(void(^)(NSMutableArray *peripheral))completion {
    
    MiuraManager *manager = [MiuraManager sharedInstance];
    [manager queueSolicitedBlock:^(MiuraManager *manager, MPIResponseData *response) {
        if (!response.isSuccess) {
            if (completion != nil) completion(nil);
            return;
        }
        
        NSMutableArray *result = [NSMutableArray new];
        
        for (int i = 0; i < 99; i++) {
            MPITLVObject *items = [MPIUtil tlvObjectFromArray:response.tlv tag:TLVTag_Configuration_Information index:i];
            if (items == nil) {
                break;
            }
            NSString *identifier = [MPIUtil tlvObjectFromTLVObject:items tag:TLVTag_Identifier].data;
            [result addObject:identifier];
            
        }
        
        completion(result);
    }];
    
    NSData *command = [self getPeripheralStatus];
    [manager writeData:command];
}

+ (NSData *)getPeripheralStatus {
    
    return [MPICommandCreator commandWithType:MPICommandType_Peripheral_Status];
}

+ (void)barcodeScannerStatus:(BOOL)enable
                  completion:(void (^)(BOOL success))completion {
    
    MiuraManager *manager = [MiuraManager sharedInstance];
    
    [manager queueSolicitedBlock:^(MiuraManager *manager, MPIResponseData *response) {
        if (completion == nil) return;
        completion([response isSuccess]);
    }];
    
    NSData *command = [self barcodeScannerStatusCommand:enable];
    [manager writeData:command];
}

+ (void) getBluetoothInfo:(void(^)(NSDictionary<NSString *, NSString *> * blueInfo))completion {
    
    MiuraManager *manager = [MiuraManager sharedInstance];
    [manager queueSolicitedBlock:^(MiuraManager * manager, MPIResponseData * response) {
        if (!response.isSuccess) {
            if (completion != nil) completion(nil);
            return;
        }
        
        NSMutableDictionary<NSString *, NSString *> *result = [NSMutableDictionary new];
        
        for (int i = 0; i < 99; i++) {
            MPITLVObject *getaddress = [MPIUtil tlvObjectFromArray:response.tlv tag:TLVTag_Configuration_Information index:i];
            if (getaddress == nil) {
                break;
            }
            
            NSString *bt_name = [MPIUtil tlvObjectFromTLVObject:getaddress tag:TLVTag_Identifier].data;
            NSString *bt_address = [MPIUtil tlvObjectFromTLVObject:getaddress tag:TLVTag_Version].data ?: @"-";
            [result setValue:bt_address forKey:bt_name];
            
        }
        
        completion(result);
    }];
    
    NSData *command = [self bluetoothControlCommand];
    [manager writeData:command];
    
}

+ (NSData *) bluetoothControlCommand {
    
    Byte p1 = 0x00;
    Byte *p_p1 = &p1;
    
    return [MPICommandCreator commandWithType:MPICommandType_Bluetooth_Control
                                           p1:p_p1];
}

+ (NSData *)barcodeScannerStatusCommand:(BOOL)enable {
    
    Byte p1 = (enable ? 0x01 : 0x00);
    Byte *p_p1 = &p1;
    
    return [MPICommandCreator commandWithType:MPICommandType_BarcodeScan_Status
                                           p1:p_p1];
}

+ (void)queryCashDrawer:(BOOL)openDraw
             completion:(void (^)(BOOL drawIsOpen))completion {
    
    MiuraManager *manager = [MiuraManager sharedInstance];
    
    [manager queueSolicitedBlock:^(MiuraManager *manager, MPIResponseData *response) {
        if (completion == nil) return;
        completion([response isSuccess]);
    }];
    
    NSData *command = [self cashDrawerOpenCommand:openDraw];
    [manager writeData:command];
    
}

+ (NSData *)cashDrawerOpenCommand:(BOOL)openDraw {
    
    Byte p1 = (openDraw ? 0x01 : 0x00);
    Byte *p_p1 = &p1;
    
    return [MPICommandCreator commandWithType:MPICommandType_CashDrawerOpen
                                           p1:p_p1];
}

+ (void)displayText:(NSString *)text
         completion:(void(^)(BOOL success))completion {
    
    MiuraManager *manager = [MiuraManager sharedInstance];
    [manager queueSolicitedBlock:^(MiuraManager *manager, MPIResponseData *response) {
        if (completion == nil) return;
        completion([response isSuccess]);
    }];
    
    NSData *command = [self displayTextCommand:text
                                     isFourRow:YES
                                 isBacklightOn:YES
                                isUTF8Encoding:YES];
    
    [manager writeData:command];
}

+ (NSData *)displayTextCommand:(NSString *)text
                     isFourRow:(BOOL)isFourRow
                 isBacklightOn:(BOOL)isBacklightOn
                isUTF8Encoding:(BOOL)isUTF8Encoding {
    
    Byte p1 = (isFourRow ? 0x00 : 0x01);
    Byte *p_p1 = &p1;
    Byte p2 = 0x00;
    Byte *p_p2 = &p2;
    NSData *dataField = nil;
    
    if (isBacklightOn) {
        p2 += AddBit_0;
    }
    if (isUTF8Encoding) {
        p2 += AddBit_7;
        dataField = [text dataUsingEncoding:NSUTF8StringEncoding];
    }
    else if ([text canBeConvertedToEncoding:NSASCIIStringEncoding]) {
        dataField = [text dataUsingEncoding:NSASCIIStringEncoding];
    }
    
    return [MPICommandCreator commandWithType:MPICommandType_Display_Text
                                           p1:p_p1 p2:p_p2
                                    dataField:dataField];
}

+ (void)displayImageNamed:(NSString *)fileName
               completion:(void(^)(BOOL success))completion {
    
    MiuraManager *manager = [MiuraManager sharedInstance];
    [manager queueSolicitedBlock:^(MiuraManager *manager, MPIResponseData *response) {
        if (completion == nil) return;
        completion([response isSuccess]);
    }];
    
    NSData *command = [self displayImageCommand:YES
                                       filePath:fileName];
    [manager writeData:command];
}

+ (NSData *)displayImageCommand:(BOOL)isBacklightOn
                       filePath:(NSString *)filePath {
    
    Byte p2 = (isBacklightOn ? 0x01 : 0x00);
    Byte *p_p2 = &p2;
    NSData *dataField = nil;
    if ([filePath canBeConvertedToEncoding:NSASCIIStringEncoding]) {
        dataField = [filePath dataUsingEncoding:NSASCIIStringEncoding];
    }
    
    return [MPICommandCreator commandWithType:MPICommandType_Display_Image
                                           p1:NULL p2:p_p2
                                    dataField:dataField];
}

+ (NSData *)configureImage:(int)imageIndex
                  filePath:(NSString *)filePath
                completion:(MPIBlocksSolicited)completion {
    
    MiuraManager *manager = [MiuraManager sharedInstance];
    [manager queueSolicitedBlock:completion];
    
    NSData *command = [self configureImageCommand:imageIndex
                                         filePath:filePath];
    [manager writeData:command];
    
    return command;
}

+ (NSData *)configureImageCommand:(int)imageIndex
                         filePath:(NSString *)filePath {
    
    Byte p1 = imageIndex & 0xFF;
    Byte *p_p1 = &p1;
    NSData *dataField = nil;
    if ([filePath canBeConvertedToEncoding:NSASCIIStringEncoding]) {
        dataField = [filePath dataUsingEncoding:NSASCIIStringEncoding];
    }
    
    return [MPICommandCreator commandWithType:MPICommandType_Configure_Image
                                           p1:p_p1
                                           p2:NULL
                                    dataField:dataField];
}

+ (void)spoolTextWithString:(NSString *)text
                 completion:(void(^)(PrinterSpoolControlError result))completion {
    
    MiuraManager *manager = [MiuraManager sharedInstance];
    [manager queueSolicitedBlock:^(MiuraManager *manager, MPIResponseData *response) {
        if (completion == nil) {
            return;
        }
        
        if ([response isSuccess]) {
            completion(PrinterSpoolControlError_Success);
        } else {
            completion([MPIBinaryUtil byteWithBytes:response.body]);
        }
    }];
    
    NSData *command = [self spoolTextCommand:text];
    [manager writeData:command];
    
    return;
    
}

+ (NSData *)spoolTextCommand:(NSString *)text {
    
    NSData *dataField = nil;
    
    if ([text canBeConvertedToEncoding:NSUTF8StringEncoding]) {
        dataField = [text dataUsingEncoding:NSUTF8StringEncoding];
    }
    
    return [MPICommandCreator commandWithType:MPICommandType_Printer_Spool
                                           p1:NULL p2:NULL
                                    dataField:dataField];
    
}

+ (void)spoolImageWithFileName:(NSString *)fileName
                    completion:(void(^)(PrinterSpoolControlError result))completion {
    
    MiuraManager *manager = [MiuraManager sharedInstance];
    [manager queueSolicitedBlock:^(MiuraManager *manager, MPIResponseData *response) {
        if (completion == nil) {
            return;
        }
        
        if ([response isSuccess]) {
            completion(PrinterSpoolControlError_Success);
        } else {
            completion([MPIBinaryUtil byteWithBytes:response.body]);
        }
    }];
    
    NSData *command = [self spoolImageCommand:fileName];
    [manager writeData:command];
    
    return;
}

+ (NSData *)spoolImageCommand:(NSString *)fileName {
    
    NSData *dataField = nil;
    
    Byte p2 = 0x01;
    Byte *p_p2 = &p2;
    
    if ([fileName canBeConvertedToEncoding:NSUTF8StringEncoding]) {
        dataField = [fileName dataUsingEncoding:NSUTF8StringEncoding];
    }
    
    return [MPICommandCreator commandWithType:MPICommandType_Printer_Spool
                                           p1:NULL p2:p_p2
                                    dataField:dataField];
}

+ (void)spoolPrintWithCompletion:(void(^)(PrinterSpoolControlError result))completion {
    
    MiuraManager *manager = [MiuraManager sharedInstance];
    [manager queueSolicitedBlock:^(MiuraManager *manager, MPIResponseData *response) {
        if (completion == nil) {
            return;
        }
        
        if ([response isSuccess]) {
            completion(PrinterSpoolControlError_Success);
        } else {
            completion([MPIBinaryUtil byteWithBytes:response.body]);
        }
    }];
    
    NSData *command = [self spoolPrintCommand];
    [manager writeData:command];
    
    return;
    
}

+ (NSData *)spoolPrintCommand {
    
    Byte p1 = 0x02;
    Byte *p_p1 = &p1;
    return [MPICommandCreator commandWithType:MPICommandType_Printer_Spool
                                           p1:p_p1 p2:NULL];
    
}

+ (void)printESCPOSWithString:(NSString *)text
                   completion:(void(^)(PrinterSpoolControlError result))completion{
    
    MiuraManager *manager = [MiuraManager sharedInstance];
    [manager queueSolicitedBlock:^(MiuraManager *manager, MPIResponseData *response) {
        if (completion == nil) {
            return;
        }
        
        if ([response isSuccess]) {
            completion(PrinterSpoolControlError_Success);
        } else {
            completion([MPIBinaryUtil byteWithBytes:response.body]);
        }
    }];
    
    NSData *command = [self printESCPOSCommand:text];
    [manager writeData:command];
    
    return;
}

+ (NSData *)printESCPOSCommand:(NSString *)text{
    
    NSData *dataField = nil;
    
    if ([text canBeConvertedToEncoding:NSISOLatin1StringEncoding]) {
        dataField = [text dataUsingEncoding:NSISOLatin1StringEncoding];
    }
    
    return [MPICommandCreator commandWithType:MPICommandType_ESC_POS
                                           p1:NULL p2:NULL
                                    dataField:dataField];
}

+ (void)printerSledStatusEnable:(BOOL)statusEnabled
                     completion:(void(^)(PrinterSledStatus result))completion {
    
    MiuraManager *manager = [MiuraManager sharedInstance];
    [manager queueSolicitedBlock:^(MiuraManager *manager, MPIResponseData *response) {
        if (completion == nil) {
            return;
        }
        if (![response isSuccess]) {
            completion(PrinterSledStatus_Printer_Error);
        } else {
            MPITLVObject *printObj    = [MPIUtil tlvObjectFromArray:response.tlv tag:TLVTag_Printer_Status];
            Byte prStatus = [MPIBinaryUtil byteWithBytes:printObj.rawData];
            completion(prStatus);
        }
    }];
    
    NSData *command = [self printerSledStatusCommand:statusEnabled];
    [manager writeData:command];
    return;
    
}

+ (NSData *)printerSledStatusCommand:(BOOL)statusEnabled{
    
    Byte p1 = (statusEnabled ? 0x01 : 0x00);
    Byte *p_p1 = &p1;
    
    return [MPICommandCreator commandWithType:MPICommandType_Print_status
                                           p1:p_p1];
}

+ (NSData *)getNumericData:(BOOL)autoEnt
             securePrompts:(NSData *)securePrompts
             numericFormat:(NSData *)numericFormat
            numericTimeout:(NSInteger)numericTimeout
             isBacklightOn:(BOOL)isBacklightOn
                completion:(void(^)(Numeric_Data_Result result, NSString *selectedItem))completion {
    
    //secure prompt
    MPITLVObject *securePrompt = [[MPITLVObject alloc] initWithTag:TLVTag_Secure_Prompt value:securePrompts];
    //numeric element
    MPITLVObject *numericElement = [[MPITLVObject alloc] initWithTag:TLVTag_Number_Format value:numericFormat];
    //timeout
    NSData *timeData = [MPIBinaryUtil bytesWithHexString:[NSString stringWithFormat:@"%04lu", (unsigned long)numericTimeout]];
    MPITLVObject *timeoutTag = [[MPITLVObject alloc] initWithTag:TLVTAG_Timeout value:timeData];
    //E0 template send with tags above
    MPITLVObject *commandDataTag = [[MPITLVObject alloc] initWithTag:TLVTag_Command_Data construct:@[securePrompt, numericElement, timeoutTag]];
  
    MiuraManager *manager = [MiuraManager sharedInstance];
    [manager queueSolicitedBlock:^(MiuraManager *manager, MPIResponseData *response) {
        if (response.isSuccess) {
            NSString * selection = [MPIUtil tlvObjectFromArray:response.tlv tag:TLVTag_Numeric_Data].data;
            ALog(@"User Selected: %@", selection);
            completion(Numeric_Data_Result_Selected, selection);
        } else {
            
            UInt8 * p_sw2 = (UInt8 *) [response.sw2 bytes];
            switch (p_sw2[0]) {
                case 0x14 :
                    completion(Numeric_Data_Result_Command_Formatting_Error, @"Formatting error");
                    break;
                case 0x41 :
                    completion(Numeric_Data_Result_Cancelled, @"User Aborted");
                    break;
                case 0x0D:
                    completion(Numeric_Data_Result_Internal_Module_Error, @"Internal Module error");
                    break;
                default : completion(Numeric_Data_Result_NumericTimeout, @"Timed out");
                    break;
            }
        }
    }];
    
    NSData *command = [self getNumericDataCommand:autoEnt
                                    isBacklightOn:isBacklightOn
                                   commandDataTag:commandDataTag];
    [manager writeData:command];
    
    return command;
}

+ (NSData *)getNumericDataCommand:(BOOL)autoEnt
                    isBacklightOn:(BOOL)isBacklightOn
                   commandDataTag:commandDataTag {
    
    Byte p1 = (autoEnt ? 0x01 : 0x00);
    Byte *p_p1 = &p1;
    Byte p2 = (isBacklightOn ? 0x01 : 0x00);
    Byte *p_p2 = &p2;
    
    return [MPICommandCreator commandWithType:MPICommandType_Get_Numeric_Data
                                           p1:p_p1 p2:p_p2
                                    dataField:[MPITLVParser encodeWithTLVObject:commandDataTag]];
}

+ (NSData *)getDynamicTip:(BOOL)amount
          percentageValue:(NSData *)percentageValue
              templateTip:(NSData *)templateTip
             currencyCode:(NSData *)currencyCode
          currencyExponet:(NSData *)currencyExponet
        authorisedNumeric:(NSData *)authorisedNumeric
           dynamicTimeout:(NSInteger)dynamicTimeout
            keyPadSetting:(BacklightSettings)keyPadSetting
               completion:(void(^)(GetDynamicResult result, NSString *selectedItem))completion {
    
    //amount
    NSData *amountData = [MPIBinaryUtil bytesWithHexString:[NSString stringWithFormat:@"%012lu", (unsigned long)amount]];
    MPITLVObject *amountTag = [[MPITLVObject alloc] initWithTag:TLVTag_Amount_Authorised_Numeric value:amountData];
    //dynamic tip percentage
    MPITLVObject *percentTag = [[MPITLVObject alloc] initWithTag:TLVTag_Dynamic_tip_percentage value:percentageValue];
    //dynamic template
    MPITLVObject *templateTag = [[MPITLVObject alloc] initWithTag:TLVTag_Dynamic_tip_template value:templateTip];
    //transacation currency code
    MPITLVObject *currencyTag = [[MPITLVObject alloc] initWithTag:TLVTag_Transaction_Currency_Code value:currencyCode];
    //transacation currency exponent
    MPITLVObject *exponetdTag = [[MPITLVObject alloc] initWithTag:TLVTag_Transaction_Currency_Exponent value:currencyExponet];
    //authorised value
    MPITLVObject *authTag = [[MPITLVObject alloc] initWithTag:TLVTag_Amount_Authorised_Numeric value:authorisedNumeric];
    //timeout value
    NSData *timeData = [MPIBinaryUtil bytesWithHexString:[NSString stringWithFormat:@"%04lu", (unsigned long)dynamicTimeout]];
    MPITLVObject *timeoutTag = [[MPITLVObject alloc] initWithTag:TLVTAG_Timeout value:timeData];
    
    MPITLVObject *commandDataTag = [[MPITLVObject alloc] initWithTag:TLVTag_Command_Data construct:@[amountTag,
                                                                                                     percentTag,
                                                                                                     templateTag,
                                                                                                     currencyTag,
                                                                                                     exponetdTag,
                                                                                                     timeoutTag,
                                                                                                     authTag]];
    MiuraManager *manager = [MiuraManager sharedInstance];
    [manager queueSolicitedBlock:^(MiuraManager *manager, MPIResponseData *response) {
        if (response.isSuccess) {
            NSString * selection = [MPIUtil tlvObjectFromArray:response.tlv tag:TLVTag_Numeric_Data].data;
            ALog(@"User Selected: %@", selection);
            completion(GetDynamicResult_Selected, selection);
        } else {
            
            UInt8 * p_sw2 = (UInt8 *) [response.sw2 bytes];
            switch (p_sw2[0]) {
                case 0x14 :
                    completion(GetDynamicResult_Error, @"Formatting error");
                    break;
                case 0x41 :
                    completion(GetDynamicResult_Cancelled, @"User Aborted");
                    break;
                case 0x0D:
                    completion(GetDynamicResult_Internal_Module_Error, @"Internal error");
                    break;
                default : completion(GetDynamicResult_Timeout, @"Timed out");
                    break;
            }
        }
    }];
    
    NSData *command = [self dynamicTipDataCommand:amount
                                   commandDataTag:commandDataTag
                                    keyPadSetting:keyPadSetting];
    
    [manager writeData:command];
    
    return command;
    
}

+ (NSData *)dynamicTipDataCommand:(BOOL)amount
                   commandDataTag:(MPITLVObject *)commandDataTag
                    keyPadSetting:(BacklightSettings)keyPadSetting {
    
    Byte p1 = (amount ? 0x01 : 0x00);
    Byte *p_p1 = &p1;
    Byte p2 = (keyPadSetting ? 0x01 : 0x00);
    Byte *p_p2 = &p2;
    
    return [MPICommandCreator commandWithType:MPICommandType_Get_Dynamic_Tip
                                           p1:p_p1 p2:p_p2
                                    dataField:[MPITLVParser encodeWithTLVObject:commandDataTag]];
}

+ (NSData *)getSecurePan:(BOOL)isBacklightOn
                settings:(MPITLVObject *)settings
              completion:(MPIBlocksSolicited)completion {
    
    MiuraManager *manager = [MiuraManager sharedInstance];
    [manager queueSolicitedBlock:completion];
    
    NSData *command = [self getSecurePanCommand:isBacklightOn
                                       settings:settings];
    [manager writeData:command];
    
    return command;
}

+ (NSData *)getSecurePanCommand:(BOOL)isBacklightOn
                       settings:(MPITLVObject *)settings {
    
    Byte p2 = (isBacklightOn ? 0x01 : 0x00);
    Byte *p_p2 = &p2;
    
    return [MPICommandCreator commandWithType:MPICommandType_Get_Secure_PAN
                                           p1:NULL p2:p_p2
                                    dataField:[MPITLVParser encodeWithTLVObject:settings]];
}

//clear secure data
+ (NSData *)clearSecureData:(MPIBlocksSolicited)completion {
    
    MiuraManager *manager = [MiuraManager sharedInstance];
    [manager queueSolicitedBlock:completion];
    
    NSData *command = [self clearSecureDataCommand];
    [manager writeData:command];
    
    return command;
    
}

+ (NSData *)clearSecureDataCommand {
    
    Byte p1 = 0x00;
    Byte *p_p1 = &p1;
    
    return [MPICommandCreator commandWithType:MPICommandType_Get_Secure_DATA
                                           p1:p_p1 p2:nil];
    
}

//get secure data
+ (NSData *)requestSecureCardData:(NSData *)securePrompts
                   requestElement:(NSData *)requestElement
                    secureTimeout:(NSInteger)secureTimeout
                    keyPadSetting:(BacklightSettings)keyPadSetting
                       completion:(void(^)(SecureDataResult result, NSString *selectedItem))completion {
    
    //secure prompt
    MPITLVObject *securePrompt = [[MPITLVObject alloc] initWithTag:TLVTag_Secure_Prompt value:securePrompts];
    //request element
    MPITLVObject *secureElement = [[MPITLVObject alloc] initWithTag:TLVTag_Secure_element value:requestElement];
    //timeout value
    NSData *timeData = [MPIBinaryUtil bytesWithHexString:[NSString stringWithFormat:@"%04lu", (unsigned long)secureTimeout]];
    MPITLVObject *timeoutTag = [[MPITLVObject alloc] initWithTag:TLVTAG_Timeout value:timeData];
    //E0 template send with tags above
    MPITLVObject *commandDataTag = [[MPITLVObject alloc] initWithTag:TLVTag_Command_Data construct:@[securePrompt, secureElement, timeoutTag]];
    
    MiuraManager *manager = [MiuraManager sharedInstance];
    [manager queueSolicitedBlock:^(MiuraManager *manager, MPIResponseData *response) {
        if (response.isSuccess) {
            
            NSString * selection = [MPIUtil tlvObjectFromArray:response.tlv tag:TLVTag_Numeric_Data].data;
            ALog(@"User Selected: %@", selection);
            completion(SecureDataResult_Selected, selection);
            
        } else {
            
            UInt8 * p_sw2 = (UInt8 *) [response.sw2 bytes];
            switch (p_sw2[0]) {
                case 0x14 :
                    completion(SecureDataResult_CommandFormattingError, @"Formatting error");
                    break;
                case 0x41 :
                    completion(SecureDataResult_UserCancelled, @"User Aborted");
                    break;
                case 0x0D:
                    completion(SecureDataResult_InternalError, @"Internal error");
                    break;
                case 0xE0:
                    completion(SecureDataResult_InvalidP2PEStatus, @"Error returning SRED module");
                    break;
                default : completion(SecureDataResult_Timout, @"Timed out");
                    break;
            }
        }
        
    }];
    
    NSData *command = [self requestSecureCardDataCommand:keyPadSetting
                                          commandDataTag:commandDataTag];
    [manager writeData:command];
    
    return command;
    
}

+ (NSData *)requestSecureCardDataCommand:(BacklightSettings)keyPadSetting
                          commandDataTag:(MPITLVObject*)commandDataTag {
    
    Byte p1 = 0x01;
    Byte *p_p1 = &p1;
    Byte p2 = (keyPadSetting ? 0x01 : 0x00);
    Byte *p_p2 = &p2;
    
    return [MPICommandCreator commandWithType:MPICommandType_Get_Secure_DATA
                                           p1:p_p1 p2:p_p2
                                    dataField:[MPITLVParser encodeWithTLVObject:commandDataTag]];
    
}

//get secure retrieve data
+ (NSData *)retrieveSecureData:(MPIBlocksSolicited)completion {
    
    MiuraManager *manager = [MiuraManager sharedInstance];
    [manager queueSolicitedBlock:completion];
    
    NSData *command = [self retrieveSecureDataCommand];
    [manager writeData:command];
    return command;
    
}

+ (NSData *)retrieveSecureDataCommand {
    
    Byte p1 = 0x02;
    Byte *p_p1 = &p1;
    
    return [MPICommandCreator commandWithType:MPICommandType_Get_Secure_DATA
                                           p1:p_p1 p2:nil];
    
}

+ (NSData *)getNextTransactionSequenceCounterWithCompletion:(MPIBlocksSolicited)completion {
    
    MiuraManager *manager = [MiuraManager sharedInstance];
    [manager queueSolicitedBlock:completion];
    
    NSData *command = [self getNextTransactionSequenceCounterCommand];
    [manager writeData:command];
    
    return command;
}

+ (NSData *)getNextTransactionSequenceCounterCommand {
    
    return [MPICommandCreator commandWithType:MPICommandType_Get_Next_Transaction_Sequence_Counter];
}

+ (NSData *)getEmvHashValuesWithCompletion:(MPIBlocksSolicited)completion {
    
    MiuraManager *manager = [MiuraManager sharedInstance];
    [manager queueSolicitedBlock:completion];
    
    NSData *command = [self getEmvHashValuesCommand];
    [manager writeData:command];
    
    return command;
}

+ (NSData *)getEmvHashValuesCommand {
    
    return [MPICommandCreator commandWithType:MPICommandType_Get_EMV_Hash_Values];
    
}

+ (void)getContactlessHashValuesWithCompletion:(void(^)(NSDictionary <NSString *, NSString *> *kernelVersions))completion {
    
    __block int i = 0;
    __block MPITLVObject *getInfo = nil;
    
    MiuraManager *manager = [MiuraManager sharedInstance];
    [manager queueSolicitedBlock:^(MiuraManager *manager, MPIResponseData *response) {
        if (!response.isSuccess) {
            if (completion != nil) completion(nil);
            return;
        }
        
        NSMutableDictionary <NSString *, NSString *> *kernelVersions = [NSMutableDictionary new];
        
        do {
            getInfo = [MPIUtil tlvObjectFromArray:response.tlv tag:TLVTag_Software_Information index:i];
            if (getInfo == nil) {
                break;
            }
            i++;
            
            NSString *kernelName = [MPIUtil tlvObjectFromTLVObject:getInfo tag:TLVTag_Identifier].data;
            NSString *hashValue = [MPIUtil tlvObjectFromTLVObject:getInfo tag:TLVTag_Version].data;
            
            if ((kernelName == nil) || (hashValue == nil)) {
                
                DLog(@"Dodgy hash value in getContactlessHashValues tlvKernel: %@,tlvHashValue: %@", kernelName, hashValue);
            }
            
            MPIKernelHashValues *keys = [MPIKernelHashValues new];
            NSString *showKernel = [keys lookUp:kernelName hashValue:hashValue];
            
            if (showKernel != nil){
                
                [kernelVersions setValue:hashValue forKey:showKernel];
                
            } else {
                
                DLog(@"Unknown hash value:%@, for kernel: %@,", hashValue, kernelName);
            }
            
        } while (getInfo != nil);
        
        completion(kernelVersions);
    }];
    
    NSData *command = [self getContactlessHashValuesCommand];
    [manager writeData:command];
}

+ (NSData *)getContactlessHashValuesCommand {
    
    Byte p1 = 0x01;
    Byte *p_p1 = &p1;
    
    return [MPICommandCreator commandWithType:MPICommandType_Get_Contactless_Hash_Values
                                           p1:p_p1];
}

+ (void)startTransactionWithType:(TransactionType)transactionType
                          amount:(NSUInteger)amount
                    currencyCode:(NSUInteger)currencyCode
                      completion:(MPIBlocksSolicited)completion {
    
    MPITLVObject *typeTag = [[MPITLVObject alloc] initWithTag:TLVTag_Transaction_Type byteValue: transactionType]; //enum
    
    NSData *amountData = [MPIBinaryUtil bytesWithHexString:[NSString stringWithFormat:@"%012lu", (unsigned long)amount]];
    MPITLVObject *amountTag = [[MPITLVObject alloc] initWithTag:TLVTag_Amount_Authorised_Numeric value:amountData];
    
    NSData *currencyData = [MPIBinaryUtil bytesWithHexString:[NSString stringWithFormat:@"%04lu", (unsigned long)currencyCode]];
    MPITLVObject *currencyTag = [[MPITLVObject alloc] initWithTag:TLVTag_Transaction_Currency_Code value:currencyData];
    
    // Current date/time
    NSDate *date = [NSDate date];
    NSDateFormatter *df = [NSDateFormatter new];
    df.dateFormat = @"yyMMdd";
    NSString *dateStr = [df stringFromDate:date];
    df.dateFormat = @"HHmmss";
    NSString *timeStr = [df stringFromDate:date];
    
    NSData *dateData = [MPIBinaryUtil bytesWithHexString:dateStr];
    NSData *timeData = [MPIBinaryUtil bytesWithHexString:timeStr];
    
    MPITLVObject *dateTag = [[MPITLVObject alloc] initWithTag:TLVTag_Date value:dateData];
    MPITLVObject *timeTag = [[MPITLVObject alloc] initWithTag:TLVTag_Time value:timeData];
    
    MPITLVObject *appSelectionTag = [[MPITLVObject alloc] initWithTag:TLVTag_Configure_Application_Selection byteValue: 1];
    
    MPITLVObject *commandDataTag = [[MPITLVObject alloc] initWithTag:TLVTag_Command_Data construct:@[typeTag, amountTag, currencyTag, dateTag, timeTag, appSelectionTag]];
    
    [self startTransaction:commandDataTag completion:completion];
}

+ (NSData *)startTransaction:(MPITLVObject *)transactionInfo
                  completion:(MPIBlocksSolicited)completion {
    
    MiuraManager *manager = [MiuraManager sharedInstance];
    [manager queueSolicitedBlockWithSwitch:completion];
    
    NSData *command = [self startTransactionCommand:transactionInfo];
    [manager writeData:command];
    
    return command;
}

+ (NSData *)startTransactionCommand:(MPITLVObject *)transactionInfo {
    
    return [MPICommandCreator commandWithType:MPICommandType_Start_Transaction
                                           p1:NULL p2:NULL
                                    dataField:[MPITLVParser encodeWithTLVObject:transactionInfo]];
}

+ (void)continueTransaction:(MPITLVObject *)transactionInfo
                 completion:(MPIBlocksSolicited)completion {
    
    MiuraManager *manager = [MiuraManager sharedInstance];
    [manager queueSolicitedBlock:completion];
    
    NSData *command = [self continueTransactionCommand:transactionInfo];
    [manager writeData:command];
}

+ (NSData *)continueTransactionCommand:(MPITLVObject *)transactionInfo {
    
    return [MPICommandCreator commandWithType:MPICommandType_Continue_Transaction
                                           p1:NULL p2:NULL
                                    dataField:[MPITLVParser encodeWithTLVObject:transactionInfo]];
}

+ (void)startContactlessTransactionWithType:(TransactionType)transactionType
                                     amount:(NSUInteger)amount
                               currencyCode:(NSUInteger)currencyCode
                         languagePreference:(NSString*)languagePreference
                                 completion:(MPIBlocksSolicited)completion {
    
    MPITLVObject *typeTag = [[MPITLVObject alloc] initWithTag:TLVTag_Transaction_Type byteValue: transactionType]; //enum
    
    NSData *amountData = [MPIBinaryUtil bytesWithHexString:[NSString stringWithFormat:@"%012lu", (unsigned long)amount]];
    MPITLVObject *amountTag = [[MPITLVObject alloc] initWithTag:TLVTag_Amount_Authorised_Numeric value:amountData];
    
    NSData *currencyData = [MPIBinaryUtil bytesWithHexString:[NSString stringWithFormat:@"%04lu", (unsigned long)currencyCode]];
    MPITLVObject *currencyTag = [[MPITLVObject alloc] initWithTag:TLVTag_Transaction_Currency_Code value:currencyData];
    
    MPITLVObject *getLanguagePreference = NULL;
    if (languagePreference != NULL && languagePreference.length == 2){
        
        NSData *data = [languagePreference dataUsingEncoding:NSUTF8StringEncoding];
        getLanguagePreference = [[MPITLVObject alloc] initWithTag: TVLTag_Terminal_Language_Preference value:data];
    }
    
    // Current date/time
    NSDate *date = [NSDate date];
    NSDateFormatter *df = [NSDateFormatter new];
    df.dateFormat = @"yyMMdd";
    NSString *dateStr = [df stringFromDate:date];
    df.dateFormat = @"HHmmss";
    NSString *timeStr = [df stringFromDate:date];
    
    NSData *dateData = [MPIBinaryUtil bytesWithHexString:dateStr];
    NSData *timeData = [MPIBinaryUtil bytesWithHexString:timeStr];
    
    MPITLVObject *dateTag = [[MPITLVObject alloc] initWithTag:TLVTag_Date value:dateData];
    MPITLVObject *timeTag = [[MPITLVObject alloc] initWithTag:TLVTag_Time value:timeData];
    
    if(getLanguagePreference != NULL) {
        
        MPITLVObject *commandDataTag = [[MPITLVObject alloc] initWithTag:TLVTag_Command_Data construct:@[typeTag, amountTag, currencyTag, dateTag, timeTag, getLanguagePreference]];
        [self startContactlessTransaction:commandDataTag completion:completion];
        
    } else{
        
        MPITLVObject *commandDataTag = [[MPITLVObject alloc] initWithTag:TLVTag_Command_Data construct:@[typeTag, amountTag, currencyTag, dateTag, timeTag]];
        [self startContactlessTransaction:commandDataTag completion:completion];
    }
}

+ (NSData *)startContactlessTransaction:(MPITLVObject *)transactionInfo
                             completion:(MPIBlocksSolicited)completion {
    
    MiuraManager *manager = [MiuraManager sharedInstance];
    [manager queueSolicitedBlockWithSwitch:completion];
    
    NSData *command = [self startContactlessTransactionCommand:transactionInfo];
    [manager writeData:command];
    
    return command;
}

+ (NSData *)startContactlessTransactionCommand:(MPITLVObject *)transactionInfo {
    return [MPICommandCreator commandWithType:MPICommandType_Start_Contactless_Transaction
                                           p1:NULL p2:NULL
                                    dataField:[MPITLVParser encodeWithTLVObject:transactionInfo]];
}

+ (NSData *)abortWithCompletion:(void(^)(BOOL success))completion {
    
    MiuraManager *manager = [MiuraManager sharedInstance];
    [manager queueSolicitedBlock:^(MiuraManager *manager, MPIResponseData *response) {
        if (completion == nil) {
            return;
        }
        completion(response.isSuccess);
        return;
    }];
    
    NSData *command = [self abortCommand];
    [manager writeData:command];
    
    return command;
}

+ (NSData *)abortCommand {
    
    return [MPICommandCreator commandWithType:MPICommandType_Abort];
}

+ (void)onlinePinWithAmount:(NSUInteger)amount
               currencyCode:(NSUInteger)currencyCode
                 track2Data:(NSString *)track2Data
                  labelText:(NSString *)labelText
                 completion:(void(^)(OnlinePinResponse *response))completion {
    
    // Format input data
    NSData *amountData = [MPIBinaryUtil bytesWithHexString:[NSString stringWithFormat:@"%012lu", (unsigned long)amount]];
    MPITLVObject *amountTag = [[MPITLVObject alloc] initWithTag:TLVTag_Amount_Authorised_Numeric value:amountData];
    
    NSData *currencyData = [MPIBinaryUtil bytesWithHexString:[NSString stringWithFormat:@"%04lu", (unsigned long)currencyCode]];
    MPITLVObject *currencyTag = [[MPITLVObject alloc] initWithTag:TLVTag_Transaction_Currency_Code value:currencyData];
    
    NSData *PANData = [track2Data dataUsingEncoding:NSUTF8StringEncoding];
    MPITLVObject *PANTag = [[MPITLVObject alloc] initWithTag:TLVTag_Masked_Track_2 value:PANData];
    
    NSData *labelData = [labelText dataUsingEncoding:NSUTF8StringEncoding];
    MPITLVObject *labelTag = [[MPITLVObject alloc] initWithTag:TLVTag_Application_Label value:labelData];
    
    MPITLVObject *commandDataTag = [[MPITLVObject alloc] initWithTag:TLVTag_Command_Data construct:@[amountTag, labelTag, PANTag, currencyTag]];
    
    // Send the command
    MiuraManager *manager = [MiuraManager sharedInstance];
    [manager queueSolicitedBlock:^(MiuraManager *manager, MPIResponseData *response) {
        if (completion == nil) return;
        if (!response.isSuccess){
            completion(nil);
            return;
        }
        
        if (response.body.length > 1) {
      
            // Parse generic response
            NSString *pinData = [MPIUtil tlvObjectFromArray:response.tlv tag: TLVTag_Online_PIN_Data].data;
            NSString *pinKSN = [MPIUtil tlvObjectFromArray:response.tlv tag: TLVTag_Online_PIN_KSN].data;
            if (pinData == nil && pinKSN == nil) {
                int sw1 = [MPIBinaryUtil byteWithInt:(unsigned long)response.sw1];
                int sw2 = [MPIBinaryUtil byteWithInt:(unsigned long)response.sw2];
                ALog(@"%d%d", sw1, sw2);
                completion(nil);
                return;
            }
            
            OnlinePinResponse *result = [OnlinePinResponse new];
            result.pinData = pinData;
            result.pinKSN = pinKSN;
            completion(result);
        }
        
        // If the response message contains a single byte, this indicates an error condition.
        if (response.body.length == 1){
            
            NSInteger singleByte = [MPIBinaryUtil byteWithInt:[MPIBinaryUtil byteWithBytes:response.body index:0]];
            NSData *singleData = [MPIBinaryUtil bytesWithHexString:[NSString stringWithFormat:@"%02lu", (unsigned long)singleByte]];
            
            MPITLVObject *cancelOrTimeout = [[MPITLVObject alloc] initWithTag:TLVTag_Payment_Cancel_Or_PIN_Entry_Timeout value:singleData];
            MPITLVObject *bypassedPin = [[MPITLVObject alloc] initWithTag:TLVTag_Payment_User_Bypassed_PIN value:singleData];
            
            MPITLVObject *Payment_Internal_1 = [[MPITLVObject alloc] initWithTag:TLVTag_Payment_Internal_1 value:singleData];
            MPITLVObject *Payment_Internal_2 = [[MPITLVObject alloc] initWithTag:TLVTag_Payment_Internal_2 value:singleData];
            MPITLVObject *Payment_Internal_3 = [[MPITLVObject alloc] initWithTag:TLVTag_Payment_Internal_3 value:singleData];
            
            MPITLVObject *paymentInteral = [[MPITLVObject alloc] initWithTag:TLVTag_Response_Data construct:@[Payment_Internal_1,
                                                                                                              Payment_Internal_2,
                                                                                                              Payment_Internal_3]];
            if (cancelOrTimeout != nil){
                ALog(@"%@",cancelOrTimeout);
                
            } else if (bypassedPin != nil){
                ALog(@"%@",bypassedPin);
                
            } else if (paymentInteral != nil){
                ALog(@"%@",paymentInteral);
            }
            
            completion(nil);
            return;
        }
    }];
    
    NSData *command = [self onlinePinCommand:commandDataTag];
    [manager writeData:command];
}

+ (NSData *)onlinePinCommand:(MPITLVObject *)transactionInfo {
    
    return [MPICommandCreator commandWithType:MPICommandType_Online_PIN
                                           p1:NULL p2:NULL
                                    dataField:[MPITLVParser encodeWithTLVObject:transactionInfo]];
}

+ (void)getSystemClockWithCompletion:(void(^)(NSDate *date))completion {
    
    MiuraManager *manager = [MiuraManager sharedInstance];
    [manager queueSolicitedBlock:^(MiuraManager *manager, MPIResponseData *response) {
        if (completion == nil) return;
        if (!response.isSuccess) {
            completion(nil);
            return;
        }
        
        // Parse date & time strings into NSDate
        NSString *date = [MPIUtil tlvObjectFromArray:response.tlv tag: TLVTag_Date].data;
        NSString *time = [MPIUtil tlvObjectFromArray:response.tlv tag: TLVTag_Time].data;
        if (date.length != 6 || time.length != 6) {
            completion(nil);
            return;
        }
        NSString *datetime = [NSString stringWithFormat:@"%@ %@", date, time];
        
        NSDateFormatter *df = [[NSDateFormatter alloc] init];
        [df setDateFormat:@"yyMMdd HHmmss"];
        NSDate *result = [df dateFromString:datetime];
        
        completion(result);
    }];
    
    NSData *command = [self systemClockCommand];
    [manager writeData:command];
}

+ (NSData *)systemClockCommand {
    
    return [MPICommandCreator commandWithType:MPICommandType_System_Clock];
}

+ (void)setSystemClock:(NSDate *)date completion:(void(^)(BOOL success))completion {
    
    // Convert NSData into TLVObject
    NSDateFormatter *df = [NSDateFormatter new];
    df.dateFormat = @"yyMMdd";
    NSString *dateStr = [df stringFromDate:date];
    df.dateFormat = @"HHmmss";
    NSString *timeStr = [df stringFromDate:date];
    
    NSData *dateData = [MPIBinaryUtil bytesWithHexString:dateStr];
    NSData *timeData = [MPIBinaryUtil bytesWithHexString:timeStr];
    
    MPITLVObject *dateTLV = [[MPITLVObject alloc] initWithTag:TLVTag_Date value:dateData];
    MPITLVObject *timeTLV = [[MPITLVObject alloc] initWithTag:TLVTag_Time value:timeData];
    MPITLVObject *commandTLV = [[MPITLVObject alloc] initWithTag:TLVTag_Command_Data construct:@[dateTLV, timeTLV]];
    
    MiuraManager *manager = [MiuraManager sharedInstance];
    [manager queueSolicitedBlock:^(MiuraManager *manager, MPIResponseData *response) {
        if (completion == nil) return;
        completion(response.isSuccess);
    }];
    
    NSData *command = [self systemClockCommand:commandTLV];
    [manager writeData:command];
}

+ (NSData *)systemClockCommand:(MPITLVObject *)newDateTime {
    
    return [MPICommandCreator commandWithType:MPICommandType_System_Clock
                                           p1:NULL p2:NULL
                                    dataField:[MPITLVParser encodeWithTLVObject:newDateTime]];
}

+ (NSData *)usbSerialDisconnectWithCompletion:(MPIBlocksSolicited)completion {
    
    MiuraManager *manager = [MiuraManager sharedInstance];
    [manager queueSolicitedBlock:completion];
    
    NSData *command = [self usbSerialDisconnectCommand];
    [manager writeData:command];
    
    return command;
}

+ (NSData *)usbSerialDisconnectCommand {
    
    return [MPICommandCreator commandWithType:MPICommandType_USB_Serial_Disconnect];
}

+ (NSData *)p2peStatus:(id<MiuraManagerDelegate>)delegate {
    
    MiuraManager *manager = [MiuraManager sharedInstance];
    manager.delegate = delegate;
    
    NSData *command = [self p2peStatusCommand];
    [manager writeData:command];
    
    return command;
}

+ (void)p2peStatusWithCompletion:(void(^)(P2PEStatus *p2peStatus))completion {
    
    MiuraManager *manager = [MiuraManager sharedInstance];
    [manager queueSolicitedBlock:^(MiuraManager *manager, MPIResponseData *response) {
        if (completion == nil) return;
        if (!response.isSuccess) {
            completion(nil);
            return;
        }
        
        NSData *statusRaw = [MPIUtil tlvObjectFromArray:response.tlv tag:TLVTag_P2PE_Status].rawData;
        Byte statusByte = [MPIBinaryUtil byteWithBytes:statusRaw];
        
        P2PEStatus *p2peStatus = [P2PEStatus new];
        p2peStatus.isInitialised = (statusByte & (1 << 0)) > 0;
        p2peStatus.isPINReady    = (statusByte & (1 << 1)) > 0;
        p2peStatus.isSREDReady   = (statusByte & (1 << 2)) > 0;
        
        completion(p2peStatus);
    }];
    
    NSData *command = [self p2peStatusCommand];
    [manager writeData:command];
}

+ (NSData *)p2peStatusCommand {
    
    return [MPICommandCreator commandWithType:MPICommandType_P2PE_Status];
}

+ (NSData *)p2peInitialise:(id<MiuraManagerDelegate>)delegate {
    
    MiuraManager *manager = [MiuraManager sharedInstance];
    manager.delegate = delegate;
    
    NSData *command = [self p2peInitialiseCommand];
    [manager writeData:command];
    
    return command;
}

+ (void)p2peInitialiseWithCompletion:(BOOL)success
                          completion:(void(^)(RkiInitStatus result))completion {
    
    MiuraManager *manager = [MiuraManager sharedInstance];
    [manager queueSolicitedBlock:^(MiuraManager *manager, MPIResponseData *response) {
        if (completion == nil) {
            return;
        }
        if (![response isSuccess]) {
            completion(RkiInitStatus_InternalError);
        } else {
            completion(response.isSuccess);
        }
    }];
    
    NSData *command = [self p2peInitialiseCommand];
    [manager writeData:command];
}

+ (NSData *)p2peInitialiseCommand {
    
    return [MPICommandCreator commandWithType:MPICommandType_P2PE_Initialise];
}

+ (NSData *)p2peImport:(id<MiuraManagerDelegate>)delegate {
    
    MiuraManager *manager = [MiuraManager sharedInstance];
    manager.delegate = delegate;
    
    NSData *command = [self p2peImportCommand];
    [manager writeData:command];
    
    return command;
}

+ (void)p2peImportWithCompletion:(BOOL)success
                      completion:(void(^)(RkiImportStatus result))completion {
    
    MiuraManager *manager = [MiuraManager sharedInstance];
    [manager queueSolicitedBlock:^(MiuraManager *manager, MPIResponseData *response) {
        if (completion == nil) {
            return;
        }
        if (![response isSuccess]) {
            completion(RkiImportStatus_InternalError);
        } else {
            completion(RkiImportStatus_NoError);
        }
    }];
    
    NSData *command = [self p2peImportCommand];
    [manager writeData:command];
}

+ (NSData *)p2peImportCommand {
    
    return [MPICommandCreator commandWithType:MPICommandType_P2PE_Import];
}

+ (NSData *)p2peGetKsnForMacWithCompletion:(MPIBlocksSolicited)completion {
    
    MiuraManager *manager = [MiuraManager sharedInstance];
    [manager queueSolicitedBlock:completion];
    
    NSData *command = [self p2peGetKsnForMacCommand];
    [manager writeData:command];
    
    return command;
}

+ (NSData *)p2peGetKsnForMacCommand {
    
    return [MPICommandCreator commandWithType:MPICommandType_P2PE_Get_KSN_For_MAC];
}

+ (NSData *)p2peVerifyMac:(MPITLVObject *)verifyInfo
               completion:(MPIBlocksSolicited)completion {
    
    MiuraManager *manager = [MiuraManager sharedInstance];
    [manager queueSolicitedBlock:completion];
    
    NSData *command = [self p2peVerifyMacCommand:verifyInfo];
    [manager writeData:command];
    
    return command;
}

+ (NSData *)p2peVerifyMacCommand:(MPITLVObject *)verifyInfo {
    
    return [MPICommandCreator commandWithType:MPICommandType_P2PE_Verify_MAC
                                           p1:NULL p2:NULL
                                    dataField:[MPITLVParser encodeWithTLVObject:verifyInfo]];
}

+ (NSData *)p2peGetMacConfigurationFile:(MPITLVObject *)fileInfo
                             completion:(MPIBlocksSolicited)completion {
    
    MiuraManager *manager = [MiuraManager sharedInstance];
    [manager queueSolicitedBlock:completion];
    
    NSData *command = [self p2peGetMacConfigurationFileCommand:fileInfo];
    [manager writeData:command];
    
    return command;
}

+ (NSData *)p2peGetMacConfigurationFileCommand:(MPITLVObject *)fileInfo {
    
    return [MPICommandCreator commandWithType:MPICommandType_P2PE_Get_MAC_Configuration_File
                                           p1:NULL p2:NULL
                                    dataField:[MPITLVParser encodeWithTLVObject:fileInfo]];
}

+ (NSData *)systemLog:(SystemLogMode)mode
           completion:(MPIBlocksSolicited)completion {
    
    MiuraManager *manager = [MiuraManager sharedInstance];
    [manager queueSolicitedBlock:completion];
    
    NSData *command = [self systemLogCommand:mode];
    [manager writeData:command];
    
    return command;
}

+ (NSData *)systemLogCommand:(SystemLogMode)mode {
    
    Byte p1 = mode & 0xFF;
    Byte *p_p1 = &p1;
    
    return [MPICommandCreator commandWithType:MPICommandType_System_Log
                                           p1:p_p1];
}

+ (NSData *)getTouchScreenStatus:(MPIBlocksSolicited)completion {
    
    MiuraManager *manager = [MiuraManager sharedInstance];
    [manager queueSolicitedBlock:completion];
    
    NSData *command = [self touchStatusCommand];
    [manager writeData:command];
    
    return command;
}

+ (NSData *)touchStatusCommand {
    
    return [MPICommandCreator commandWithType:MPICommandType_Touch_Capture_Status];
}

+ (NSData *)getTouchScreenCalibrate:(MPIBlocksSolicited)completion {
    
    MiuraManager *manager = [MiuraManager sharedInstance];
    [manager queueSolicitedBlock:completion];
    
    NSData *command = [self touchCalibrateCommand];
    [manager writeData:command];
    
    return command;
}

+ (NSData *)touchCalibrateCommand {
    
    return [MPICommandCreator commandWithType:MPICommandType_Touch_Capture_Calibrate];
}
//touch Begin
+ (void)getTouchScreenBegin:(MPIBlocksSolicited)completion {
    
    MiuraManager *manager = [MiuraManager sharedInstance];
    [manager queueSolicitedBlock:^(MiuraManager *manager, MPIResponseData *response) {
        if (completion == nil) return;
        completion(manager, response);
    }];
    
    //The sample layout is composed of 4 areas:
    //area 0: x =   3, y =  32, width = 312, height = 163, parameter set to 05 (record, report);
    //area 1: x =   0, y = 199, width =  64, height =  41, parameter set to 04 (report);
    //area 2: x = 127, y = 199, width =  64, height =  41, parameter set to 04 (report);
    //area 3: x = 256, y = 199, width =  64, height =  41, parameter set to 04 (report);
    
    const unsigned char  bytes[] = { 0x00, 0x03, 0x00, 0x20, 0x01, 0x38, 0x00, 0xA3, 0x05 };
    const unsigned char aBytes[] = { 0x00, 0x00, 0x00, 0xC7, 0x00, 0x40, 0x00, 0x29, 0x04 };
    const unsigned char bBytes[] = { 0x00, 0x7F, 0x00, 0xC7, 0x00, 0x40, 0x00, 0x29, 0x04 };
    const unsigned char cBytes[] = { 0x01, 0x00, 0x00, 0xC7, 0x00, 0x40, 0x00, 0x29, 0x04 };
    
    NSData *bytes_1 = [NSData dataWithBytes:bytes length:9];
    NSData *bytes_2 = [NSData dataWithBytes:aBytes length:9];
    NSData *bytes_3 = [NSData dataWithBytes:bBytes length:9];
    NSData *bytes_4 = [NSData dataWithBytes:cBytes length:9];
    
    MPITLVObject *sendTag_1 = [[MPITLVObject alloc] initWithTag:TLVTag_Touch_Screen_Area value:bytes_1];
    MPITLVObject *sendTag_2 = [[MPITLVObject alloc] initWithTag:TLVTag_Touch_Screen_Area value:bytes_2];
    MPITLVObject *sendTag_3 = [[MPITLVObject alloc] initWithTag:TLVTag_Touch_Screen_Area value:bytes_3];
    MPITLVObject *sendTag_4 = [[MPITLVObject alloc] initWithTag:TLVTag_Touch_Screen_Area value:bytes_4];
    
    MPITLVObject *allSentTags = [[MPITLVObject alloc] initWithTag:TLVTag_Command_Data construct:@[sendTag_1,
                                                                                                  sendTag_2,
                                                                                                  sendTag_3,
                                                                                                  sendTag_4]];
    
    NSData *command = [self touchBeginCommand:allSentTags];
    [manager writeData:command];
    
}

+ (NSData *)touchBeginCommand:(MPITLVObject*)allSentTags {
    
    Byte p1 = 0x00;
    Byte *p_p1 = &p1;
    
    return [MPICommandCreator commandWithType:MPICommandType_Touch_Capture_Begin
                                           p1:p_p1 p2:NULL
                                    dataField:[MPITLVParser encodeWithTLVObject:allSentTags]];
    
}
//touch Screen clear
+ (NSData *)getTouchScreenClear:(MPIBlocksSolicited)completion {
    
    MiuraManager *manager = [MiuraManager sharedInstance];
    [manager queueSolicitedBlock:completion];
    
    NSData *command = [self touchClearCommand];
    [manager writeData:command];
    
    return command;
}

+ (NSData *)touchClearCommand {
    
    return [MPICommandCreator commandWithType:MPICommandType_Touch_Capture_Clear];
}

+ (NSData *)getTouchScreenEnd:(MPIBlocksSolicited)completion {
    
    MiuraManager *manager = [MiuraManager sharedInstance];
    [manager queueSolicitedBlock:completion];
    
    NSData *command = [self touchEndCommand];
    [manager writeData:command];
    
    return command;
}

+ (NSData *)touchEndCommand {
    
    return [MPICommandCreator commandWithType:MPICommandType_Touch_Capture_End];
}
//touch Screen Export
+ (void)getTouchScreenExport:(NSString *) fileName
                  completion:(MPIBlocksSolicited) completion  {
    
    MiuraManager *manager = [MiuraManager sharedInstance];
    [manager queueSolicitedBlock:^(MiuraManager *manager, MPIResponseData *response) {
        if (completion == nil) return;
        completion(manager, response);
    }];
    
    NSData *command = [self touchExportCommand:fileName];
    [manager writeData:command];
    
}

+ (NSData *)touchExportCommand:(NSString *) fileName {
    
    Byte p1 = 0x00;
    Byte *p_p1 = &p1;
    Byte p2 = 0x00;
    Byte *p_p2 = &p2;
    Byte le = 0x04;
    Byte *p_le = &le;
    
    NSData *dataField = nil;
    if ([fileName canBeConvertedToEncoding:NSASCIIStringEncoding]) {
        dataField = [fileName dataUsingEncoding:NSASCIIStringEncoding];
    }
    
    return [MPICommandCreator commandWithType:MPICommandType_Touch_Capture_Export
                                           p1:p_p1 p2:p_p2
                                    dataField:dataField
                                           le:p_le];
}

+ (NSData *) getMenuOption: (nonnull NSString *) menuTitle
             showStatusBar: (BOOL) showStatusBar
             enlargeHeader: (BOOL) enlargeHeader
             enlargeFooter: (BOOL) enlargerFooter
                 menuItems: (nonnull NSArray *) menuItems
                completion:(void(^_Nonnull)(GetMenuResult result, NSString * _Nullable selectedItem))completion {
    
    MiuraManager *manager = [MiuraManager sharedInstance];
    [manager queueSolicitedBlock:^(MiuraManager *manager, MPIResponseData *response) {
        if (response.isSuccess) {
            NSString * selection = [MPIUtil tlvObjectFromArray:response.tlv tag:TLVTag_Numeric_Data].data;
            DLog(@"User Slected: %@", selection);
            completion(GetMenuResult_Selected, selection);
        } else {
            UInt8 * p_sw2 = (UInt8 *) [response.sw2 bytes];
            
            switch (p_sw2[0]) {
                case 0x41 :
                    completion(GetMenuResult_Cancelled, NULL);
                    break;
                case 0x42 :
                    completion(GetMenuResult_Timeout, NULL);
                    break;
                default : completion(GetMenuResult_Error, NULL);
                    break;
            }
        }
    }];
    
    /*Array used to construct the body of the command message*/
    NSMutableArray * menuItemsTLV = [[NSMutableArray alloc]init];
    /*Create the title TLV object*/
    NSData * titleStringBuffer = [menuTitle dataUsingEncoding:NSUTF8StringEncoding];
    MPITLVObject *titleTag = [[MPITLVObject alloc] initWithTag:TLVTag_Menu_Title value:titleStringBuffer];
    [menuItemsTLV addObject:titleTag];
    
    /*Loop through array of input strings convert them to TLV objects and add to main array.*/
    MPITLVObject *menuTag;
    NSData * menuStringBuffer;
    for (id menuItemString in menuItems) {
        menuStringBuffer = [menuItemString dataUsingEncoding:NSUTF8StringEncoding];
        menuTag = [[MPITLVObject alloc] initWithTag:TLVTag_Menu_Option value:menuStringBuffer];
        [menuItemsTLV addObject:menuTag];
    }
    
    /*Add the array of TLV objects to the main command body*/
    MPITLVObject * commandData = [[MPITLVObject alloc] initWithTag:TLVTag_Command_Data  construct:menuItemsTLV];
    
    /*Construct the command*/
    NSData *command = [self getMenuOptionCommand:showStatusBar enlargeHeader:enlargeHeader enlargeFooter:enlargerFooter commandAction:ShowMenu_Show_Menu messageBody:commandData];
    
    /*Send the command*/
    [manager writeData:command];
    
    return command;
}

+ (NSData *) getMenuOptionCommand: (BOOL) showStatusBar
                    enlargeHeader: (BOOL) enlargeHeader
                    enlargeFooter: (BOOL) enlargeFotter
                    commandAction: (ShowMenu) commandAction
                     messageBody : (MPITLVObject *) messageBody
{
    
    Byte p1 = 0x00;
    Byte *p_p1;
    
    Byte p2 = 0x00;
    Byte *p_p2;
    
    if (commandAction == ShowMenu_Show_Menu) {
        p2 = 0x00;
        if (showStatusBar) {
            p1 |= 0x01;
        }
        if (enlargeHeader) {
            p1 |= 0x02;
        }
        if (enlargeFotter) {
            p1 |= 0x04;
        }
    } else {
        p1 = 0x00;
        switch (commandAction)
        {
            case ShowMenu_Append_Option:
                p2 = 0x01;
                break;
            case ShowMenu_Clear_Options:
                p2 = 0x02;
                break;
            default:
                /*Log an input error*/
                break;
        };
    }
    p_p1 = &p1;
    p_p2 = &p2;
    
    return [MPICommandCreator commandWithType:MPICommandType_Get_Menu_Option
                                           p1:p_p1 p2:p_p2
                                    dataField:[MPITLVParser encodeWithTLVObject:messageBody]];
}

+ (NSData *) displayMediaCommand:(void(^_Nonnull)(BOOL success))completion {
    
    __block  MPITLVObject *displayMedObj;
    __block DisplayMediaData *displayMediaData;
    
    MiuraManager *manager = [MiuraManager sharedInstance];
    [manager queueSolicitedBlock:^(MiuraManager *manager, MPIResponseData *response) {
        
        displayMedObj = [[MPITLVObject alloc] initWithTag:TLVTag_Command_Data construct:displayMediaData.tlvList];
        ALog(@"DisplayMedia: %@",displayMedObj);
        
    }];
    
    NSData *command = [self displayMediaStatus:displayMedObj];
    [manager writeData:command];
    
    return command;
}

+ (NSData *)displayMediaStatus:displayMedObj {
    
    __block int p2 = 0x00;
    __block DisplayMediaData *displayMediaData;
    
    if (displayMediaData.turnBacklightOn){
        p2 |= 0x01;
    }
    if (displayMediaData.useUTF8Encoding){
        p2 |= 0x80;
    }
    
    Byte p1 = 0x00;
    Byte *p_p1 = &p1;
    Byte *p_p2 = (unsigned char*)&p2;
        
    return [MPICommandCreator commandWithType:MPICommandType_Display_Media
                                           p1:p_p1 p2:p_p2
                                    dataField:displayMedObj];
}

+ (NSData *)buzzerSound:(BOOL)synchronousSound
               duration:(NSUInteger)duration
                volData:(NSUInteger)volume
               freqData:(NSUInteger)frequency
             completion:(void(^)(BOOL success))completion {
    
    MiuraManager *manager = [MiuraManager sharedInstance];
    [manager queueSolicitedBlock:^(MiuraManager *manager, MPIResponseData *response) {
        if (completion == nil) {
            return;
        }
        completion(response.isSuccess);
        return;
    }];
    
    /*Check the input parameters.*/
    if (frequency < 1 || frequency > 5000 ){
        DLog(@"frequency parameter is out of bounds: %lu", (unsigned long)frequency);
        completion(false);
        return nil;
    }
    if (volume < 1 || volume > 100 ){
        DLog(@"volume parameter is out of bounds: %lu", (unsigned long)volume);
        completion(false);
        return nil;
    }
    if (duration < 1 || duration > 5000 ){
        DLog(@"duration parameter is out of bounds: %lu", (unsigned long)duration);
        completion(false);
        return nil;
    }
    
    NSData *durationData = [MPIBinaryUtil bytesWithHexString:[NSString stringWithFormat:@"%08lu", (unsigned long)duration]];
    NSData *volumeData = [MPIBinaryUtil bytesWithHexString:[NSString stringWithFormat:@"%02lu", (unsigned long)volume]];
    NSData *frequencyData = [MPIBinaryUtil bytesWithHexString:[NSString stringWithFormat:@"%08lu", (unsigned long)frequency]];
    
    MPITLVObject *durationTLV = [[MPITLVObject alloc] initWithTag:TLVTag_Sound_Duration value:durationData];
    MPITLVObject *volumeTLV = [[MPITLVObject alloc] initWithTag:TLVTag_Sound_Volume value:volumeData];
    MPITLVObject *freqTLV = [[MPITLVObject alloc] initWithTag:TLVTag_Sound_Frequency value:frequencyData];
    
    MPITLVObject *commandTLV = [[MPITLVObject alloc] initWithTag:TLVTag_Command_Data construct:@[durationTLV, volumeTLV, freqTLV]];
    
    NSData *command = [self buzzerSoundCommand:synchronousSound
                                    commandTLV:commandTLV];
    [manager writeData:command];
    
    return command;
}

+ (NSData *)buzzerSoundCommand:(BOOL)synchronousSound
                    commandTLV:(MPITLVObject *)commandTLV {
    
    Byte p1 = 0x00;
    Byte *p_p1 = &p1;
    
    if(synchronousSound == true) {
        p1 += 0x01;
    }
    
    Byte p2 = 0x00;
    Byte *p_p2 = &p2;
    
    return [MPICommandCreator commandWithType:MPICommandType_Buzzer
                                           p1:p_p1 p2:p_p2
                                    dataField:[MPITLVParser encodeWithTLVObject:commandTLV]];
}

+ (NSData *)enableUsbStatus:(BOOL) enable completion:(void(^)(BOOL usbStatus))completion {
    
    MiuraManager *manager = [MiuraManager sharedInstance];
    [manager queueSolicitedBlock:^(MiuraManager *manager, MPIResponseData *response) {
        if (completion == nil)
            return;
        
        MPITLVObject *statusObj = [MPIUtil tlvObjectFromArray:response.tlv tag:TLVTag_Response_Data];
        Byte dataInt    = [MPIBinaryUtil byteWithBytes:statusObj.rawData];
     
        completion(dataInt);
    }];
    
    NSData *command = [self enableUSBStatus:enable];
    [manager writeData:command];
    
    return command;
    
}

+ (NSData *)enableUSBStatus:(BOOL)enable{
    
    Byte p1 =  (enable ? 0x01 : 0x00);
    Byte *p_p1 = &p1;
        
    return [MPICommandCreator commandWithType:MPICommandType_Usb_Status
                                           p1:p_p1];
}

+ (void)retreiveSignCaptureExport:(void(^)(NSData *pngData))completion {
    
    [self systemLog:SystemLogMode_Archive_Mode completion:^(MiuraManager *manager, MPIResponseData *response) {
        if (!response.isSuccess) {
            if (completion != nil) completion(nil);
            return;
        }
        
        NSString *signatureFileName = @"mySignature.png";
        
        [self downloadBinaryWithfileName:signatureFileName completion:^(NSData *pngData) {
            if (pngData == nil) {
                completion(nil);
            }
            
            if (completion != nil) {
                completion(pngData);
            }
        }];
    }];
}


#pragma mark - Not available

- (instancetype)init {
    
    NSAssert(NO, @"This method is not available.");
    return nil;
}

@end
