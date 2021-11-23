#import <Foundation/Foundation.h>

#import "MiuraManager.h"
#import "MPITLVObject.h"


#pragma mark - Define enum for MPI command


typedef NS_ENUM (NSUInteger, SystemLogMode) {
    SystemLogMode_Archive_Mode = 0x00,
    SystemLogMode_Remove_Mode = 0x01,
};


/**
 Execute MPI command to PED.
 */
@interface MPICommandExecutor : NSObject


#pragma mark - Execute MPI command

/**
 * Performs reset of Miura device, followed by returning its basic configuration information.
 *
 * @param resetType The type of the reset
 * @param completion The block to execute
 */
+ (void)resetDeviceWithResetType:(ResetDeviceType)resetType
                      completion:(_Nullable MPIBlocksSolicited)completion;

/**
 * Returns information about software currently installed on Miura device.
 *
 * @param completion The block to execute. Its only parameter will contain the software info
 */
+ (void)getSoftwareInfoWithCompletion:(void(^_Nonnull)(SoftwareInfo * _Nonnull softwareInfo))completion;

/**
 * Call this to apply all pending updates.
 *
 * Note: This might result in Miura device reboot.
 *
 * @param completion The block to execute
 */
+ (void)applyUpdateWithCompletion:(void(^_Nullable)(BOOL success))completion;

/**
 * Clears old transfered files before new binary files are uploaded.
 *
 * @Note This will allow any transfered file to be cleard before updates are countined.
 *
 * @param completion the block to execute
 */
+ (void)clearDeviceMemory:(void(^_Nullable)(BOOL success))completion;

+ (NSData *_Nonnull)resetDevice:(ResetDeviceType)type
                      sizeOfMsd:(int)sizeOfMsd
                    volumeLabel:(NSString * _Nonnull)volumeLabel
                     completion:(MPIBlocksSolicited _Nonnull )completion;

/**
 * Returns a list of configuration files on the device, along with their versions.
 *
 * @param completion The block to execute
 */
+ (void)getConfigurationWithCompletion:(void(^_Nonnull)(NSDictionary<NSString *, NSString *> * _Nonnull configVersions))completion;

/**
 * Returns a list of capabilities of the device.
 *
 * Possible values include: "Smartcard", "Contactless", "USB_Bluetooth", "Display", "Keyboard", "Mag".
 *
 * For a full list, please refer to the documentation.
 *
 * @param completion The block to execute after the downloading finishes
 */
+ (void)getDeviceCapabilitiesWithCompletion:(void(^_Nonnull)(NSDictionary<NSString *, NSString *> * _Nonnull capabilities))completion;

+ (NSData * _Nullable)selectFile:(SelectFileMode)mode
                        fileName:(NSString * _Nonnull)fileName
                      completion:(MPIBlocksSolicited _Nonnull )completion;


/**
 * Delete File
 *
 * @brief Delete file can be used to remove a file from PED.
 *
 * @discussion This can be used for a file deletion of a file
 *  from the temp folder.
 **/
+ (NSData * _Nullable)deleteFile:(NSString * _Nonnull )fileName
                      completion:(MPIBlocksSolicited _Nonnull)completion;


+ (void)listFilesWithCompletion:(BOOL)selectFolder completion:(void(^_Nullable)(NSMutableArray * _Nullable listOfFiles))completion;

+ (NSData *_Nullable)readBinary:(long)fileSize
                         offset:(long)offset
                           size:(long)size
                     completion:(MPIBlocksSolicited _Nonnull )completion;

/**
 * Downloads system log data.
 *
 * Note: All text data is sent using ASCII encoding.
 *
 * @param completion The block to execute after the downloading finishes
 */
+ (void)downloadSystemLogWithCompletion:(void(^ _Nonnull)(NSData * _Nonnull fileData))completion;

+ (void)downloadBinaryWithfileName:(NSString *_Nonnull)fileName completion:(void(^_Nonnull)(NSData * _Nonnull fileData)) completion;

+ (NSData *_Nullable)streamBinary:(BOOL)needMd5sum
                           binary:(NSData *_Nonnull)binary
                           offset:(long)offset
                             size:(long)size
                          timeout:(long)timeout
                       completion:(MPIBlocksSolicited _Nonnull )completion;

/**
 * @brief Delete the current log generated on the PED or POS device.
 * @discussion This should be done at regular intervals. The recommendation is
 *before each transaction on a PED devcie and on each connection for POS devices
 */
+ (void)deleteLog:(void (^_Nullable)(BOOL success))completion;
/**
 * Streams binary data to Miura device.
 *
 * Note: Before calling this method, target file name must be set via selectFile: method.
 *
 * @param binary The data to be sent to Miura device
 * @param timeout The time after which device will break the connection
 * @param completion The block to execute after the streaming finishes
 */
+ (void)streamBinary:(NSData *_Nonnull)binary
             timeout:(long)timeout
          completion:(MPIBlocksSolicited _Nonnull )completion;

/**
 * Uploads binary data and puts it into file on Miura device.
 *
 * @param binary The data to be sent to Miura device
 * @param fileName The name of the file to be created and filled with the data
 * @param completion The block to execute after the streaming finishes
 */
+ (void)uploadBinary:(NSData *_Nonnull)binary
             forName:(NSString *_Nonnull)fileName
          completion:(MPIBlocksSolicited _Nonnull )completion;

+ (void)cardStatus:(BOOL)enableUnsolicited
         enableAtr:(BOOL)enableAtr
      enableTrack1:(BOOL)enableTrack1
      enableTrack2:(BOOL)enableTrack2
      enableTrack3:(BOOL)enableTrack3
        completion:(void(^_Nullable)(BOOL success))completion;


+ (void)keyboardStatus:(KeyPadStatusSettings)statusSetting
      backlightSetting:(BacklightSettings)backlightSetting
            completion:(MPIBlocksSolicited _Nullable )completion;

+ (NSData *_Nonnull)batteryStatus:(BOOL)intoSleep
            setEvents:(BOOL)setEvents
     onChargingChange:(BOOL)onChargingChange
   onThresholdReached:(BOOL)onThresholdReached
           completion:(void(^_Nullable)(ChargingStatus chargingStatus, NSUInteger batteryPercentage))completion;

+ (void)barcodeScannerStatus:(BOOL)enable
                  completion:(void (^_Nonnull)(BOOL success))completion;

+ (void)queryCashDrawer:(BOOL)openDraw
             completion:(void (^_Nonnull)(BOOL drawIsOpen))completion;
/**
 * Displays text on the screen.
 *
 * @param text The text to be displayed
 * @param completion The block to be executed afterwards
 */
+ (void)displayText:(NSString *_Nonnull)text
         completion:(void(^_Nullable)(BOOL success))completion;
/**
 * Displays image on the screen.
 *
 * @param fileName The file name of the image to display
 * @param completion The block to be executed afterwards
 */
+ (void)displayImageNamed:(NSString *_Nonnull)fileName
               completion:(void(^_Nullable)(BOOL success))completion;

+ (NSData *_Nullable)configureImage:(int)imageIndex
                           filePath:(NSString *_Nonnull)filePath
                         completion:(MPIBlocksSolicited _Nullable )completion;

+ (void)spoolTextWithString:(NSString *_Nonnull)text
                 completion:(void(^_Nonnull)(PrinterSpoolControlError result))completion;

+ (void)spoolImageWithFileName:(NSString *_Nonnull)fileName
                    completion:(void(^_Nonnull)(PrinterSpoolControlError result))completion;

+ (void)spoolPrintWithCompletion:(void(^_Nonnull)(PrinterSpoolControlError result))completion;

+ (void)printESCPOSWithString:(NSString *_Nonnull)text
                   completion:(void(^_Nonnull)(PrinterSpoolControlError result))completion;

+ (void)printerSledStatusEnable:(BOOL)statusEnabled
                     completion:(void(^_Nonnull)(PrinterSledStatus result))completion;

+ (NSData *_Nullable)getNumericData:(BOOL)autoEnt
                      securePrompts:(NSData *_Nonnull)securePrompts
                      numericFormat:(NSData *_Nonnull)numericFormat
                     numericTimeout:(NSInteger)numericTimeout
                      isBacklightOn:(BOOL) isBacklightOn
                         completion:(void(^_Nonnull)(Numeric_Data_Result result, NSString *_Nonnull selectedItem))completion;

+ (NSData *_Nullable)getDynamicTip:(BOOL)amount
                   percentageValue:(NSData *_Nonnull)percentageValue
                       templateTip:(NSData *_Nonnull)templateTip
                      currencyCode:(NSData *_Nonnull)currencyCode
                   currencyExponet:(NSData *_Nonnull)currencyExponet
                 authorisedNumeric:(NSData *_Nonnull)authorisedNumeric
                    dynamicTimeout:(NSInteger)dynamicTimeout
                     keyPadSetting:(BacklightSettings)keyPadSetting
                        completion:(void(^_Nonnull)(GetDynamicResult result, NSString *_Nonnull selectedItem))completion;

+ (NSData *_Nullable)getSecurePan:(BOOL)isBacklightOn
                         settings:(MPITLVObject *_Nonnull)settings
                       completion:(MPIBlocksSolicited _Nonnull )completion;

+ (NSData *_Nullable)clearSecureData:(MPIBlocksSolicited _Nonnull )completion;

+ (NSData *_Nullable)requestSecureCardData:(NSData *_Nonnull)securePrompts
                            requestElement:(NSData *_Nonnull)requestElement
                             secureTimeout:(NSInteger)secureTimeout
                             keyPadSetting:(BacklightSettings)keyPadSetting
                                completion:(void(^_Nonnull)(SecureDataResult result, NSString *_Nonnull selectedItem))completion;
                         
+ (NSData *_Nullable)retrieveSecureData:(MPIBlocksSolicited _Nonnull)completion;

+ (NSData *_Nullable)getNextTransactionSequenceCounterWithCompletion:(MPIBlocksSolicited _Nonnull )completion;

+ (NSData *_Nullable)getEmvHashValuesWithCompletion:(MPIBlocksSolicited _Nonnull )completion;

+ (void)getContactlessHashValuesWithCompletion:(void(^_Nonnull)(NSDictionary <NSString*, NSString*>* _Nonnull kernelVersions))completion;

/**
 * Starts EMV transaction.
 *
 * @param transactionType The transaction type
 * @param amount The amount
 * @param currencyCode ISO 4217 code, see here for details: https://en.wikipedia.org/wiki/ISO_4217
 * @param completion The block to execute
 */
+ (void)startTransactionWithType:(TransactionType)transactionType
                          amount:(NSUInteger)amount
                    currencyCode:(NSUInteger)currencyCode
                      completion:(MPIBlocksSolicited _Nonnull )completion;

/**
 * Continues EMV transaction.
 *
 * @param transactionInfo The transaction info
 * @param completion The block to execute
 */
+ (void)continueTransaction:(MPITLVObject *_Nonnull)transactionInfo
                 completion:(MPIBlocksSolicited _Nonnull )completion;

/**
 * Start contactless Transaction
 *
 * @param transactionType The transaction type
 * @param amount The amount
 * @param currencyCode ISO 4217 code, see here for details: https://en.wikipedia.org/wiki/ISO_4217
 * @param languagePreference 2 digit country code based on ISO 3166, but will match with the config file name installed on the device.
 * @param completion The block to execute
 */
+ (void)startContactlessTransactionWithType:(TransactionType)transactionType
                                     amount:(NSUInteger)amount
                               currencyCode:(NSUInteger)currencyCode
                         languagePreference:(NSString * _Nullable)languagePreference
                                 completion:(MPIBlocksSolicited _Nonnull )completion;

+ (NSData *_Nullable)abortWithCompletion:(void (^_Nullable)(BOOL success))completion;

/**
 * Initiates Online PIN process.
 *
 * If successful, response will contain at least those fields:
 * - Online PIN block
 * - Online PIN Key Serial Number
 *
 * @param amount The amount mantissa
 * @param currencyCode ISO 4217 code, see here for details: https://en.wikipedia.org/wiki/ISO_4217
 * @param track2Data The masked track 2 data
 * @param labelText The text to be displayed during PIN entry
 * @param completion The block to execute
 */
+ (void)onlinePinWithAmount:(NSUInteger)amount
               currencyCode:(NSUInteger)currencyCode
                 track2Data:(NSString *_Nonnull)track2Data
                  labelText:(NSString *_Nonnull)labelText
                 completion:(void(^_Nonnull)(OnlinePinResponse * _Nonnull response))completion;

/**
 * Returns current date on connected Miura device.
 *
 * Note: Returned date uses iOS system Time Zone.
 *
 * @param completion The block to execute
 */
+ (void)getSystemClockWithCompletion:(void(^_Nonnull)(NSDate * _Nonnull date))completion;

/**
 * Updates device's date using the given date.
 *
 * Note: The date should be provided in iOS system Time Zone.
 *
 * @param date The date to be set on the Miura device
 * @param completion The block to execute
 */
+ (void)setSystemClock:(NSDate *_Nonnull)date completion:(void(^_Nonnull)(BOOL success))completion;

+ (NSData *_Nullable)usbSerialDisconnectWithCompletion:(MPIBlocksSolicited _Nonnull )completion;

/**
 * Returns the status of the PED's payment encryption key injection process.
 *
 * @param completion The block to execute. It has only one parameter - the current P2PE status
 */
+ (void)p2peStatusWithCompletion:(void(^_Nonnull)(P2PEStatus * _Nonnull p2peStatus))completion;

/**
 * Instructs the PED to prepare the files required for a HSM to exchange keys.
 *
 * This process can take up to 2 minutes, but usually takes around 30 seconds.
 *
 * @param completion The block to execute after the initialisation finishes
 */
+ (void)p2peInitialiseWithCompletion:(BOOL) success
                          completion:(void(^_Nullable)(RkiInitStatus result))completion;

/**
 * Instruct the PED to import the payment data encryption key.
 *
 * @param completion The block to execute after the import finishes
 */
+ (void)p2peImportWithCompletion:(BOOL) success
                      completion:(void(^_Nullable)(RkiImportStatus result))completion;

+ (NSData *_Nullable)p2peGetKsnForMacWithCompletion:(MPIBlocksSolicited _Nonnull )completion;

+ (NSData *_Nullable)p2peVerifyMac:(MPITLVObject *_Nonnull)verifyInfo
                        completion:(MPIBlocksSolicited _Nonnull )completion;

+ (NSData *_Nullable)p2peGetMacConfigurationFile:(MPITLVObject *_Nonnull)fileInfo
                                      completion:(MPIBlocksSolicited _Nonnull )completion;

+ (NSData *_Nullable)systemLog:(SystemLogMode)mode
                    completion:(MPIBlocksSolicited _Nonnull )completion;
/**
 * This checks for presence of the support peripherals.
 * An entry in the response message will appear for
 * each supported peripheral which is currently connected/operational.
 */
+ (void)peripheralStatusCommand:(void(^_Nonnull)(NSMutableArray * _Nonnull peripher))completion;

/**
 * This is used when USB lead is attacted to a POSzle device/over
 * bluetooth to get name & address(Mac) of the device, NSDictionary
 * values include: 'name' & address'.
 *
 */
+ (void) getBluetoothInfo:(void(^_Nonnull)(NSDictionary<NSString *, NSString *> * _Nonnull blueInfo))competion;

+ (NSData *_Nullable)getTouchScreenStatus:(MPIBlocksSolicited _Nonnull )completion;

+ (NSData *_Nullable)getTouchScreenEnd:(MPIBlocksSolicited _Nonnull )completion;

+ (NSData *_Nullable)getTouchScreenClear:(MPIBlocksSolicited _Nonnull )completion;

/**
 * This is used to calibrate the touch screen device.
 *
 */
+ (NSData *_Nullable)getTouchScreenCalibrate:(MPIBlocksSolicited _Nonnull )completion;

/**
 * This captures area, location, size and parameters on M021 screen.
 * Command starts the capture process.
 */
+ (void)getTouchScreenBegin:(MPIBlocksSolicited _Nonnull )completion;

/**
 * This can be used to save any of the current drawable areas to an
 * image for it to be then retrieved later.
 */
+ (void)getTouchScreenExport:(NSString *_Nonnull) fileName
                  completion:(MPIBlocksSolicited _Nonnull ) completion;

/**
 * Shows a scrollable menu of choices to user and return index they choose.
 */
+ (NSData *_Nullable) getMenuOption: (nonnull NSString *) menuTitle
                      showStatusBar: (BOOL) showStatusBar
                      enlargeHeader: (BOOL) enlargeHeader
                      enlargeFooter: (BOOL) enlargerFooter
                          menuItems: (nonnull NSArray *) menuItems
                         completion:(void(^_Nonnull)(GetMenuResult result, NSString * _Nullable selectedItem)) completion;


+ (NSData *_Nullable) displayMediaCommand:(void(^_Nonnull)(BOOL success))completion;

/**
 * This command allows integrators to produce a sound from the PED.-
 *
 */
+ (NSData *_Nullable)buzzerSound:(BOOL)synchronousSound
                        duration:(NSUInteger)duration
                         volData:(NSUInteger)volume
                        freqData:(NSUInteger)frequency
                      completion:(void(^_Nullable)(BOOL success))completion;

+ (NSData *_Nullable)enableUsbStatus:(BOOL) enable completion:(void(^_Nullable)(BOOL usbStatus))completion;

+ (void)retreiveSignCaptureExport:(void(^ _Nonnull)(NSData * _Nonnull pngData))completion;

#pragma mark - Not available

- (_Nonnull instancetype)init UNAVAILABLE_ATTRIBUTE;
- (_Nonnull  instancetype)new UNAVAILABLE_ATTRIBUTE;

@end
