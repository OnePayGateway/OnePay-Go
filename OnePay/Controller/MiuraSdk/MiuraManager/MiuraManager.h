/*!
 * @header MiuraManager.h
 *
 * @brief This describes the interface to the Miura SDK.
 * This covers connecting to and communicating with Miura PED and POS products.
 *
 * @copyright 2017 Miura Systems Ltd. All rights reserved.
 * @Version M000-MOBILESDK-V1-0-IOS-V1
 */

#import <ExternalAccessory/ExternalAccessory.h>
#import "MPIResponseData.h"

@import UIKit;

@class MiuraManager;

#pragma mark - Enums

typedef NS_ENUM(NSInteger, UsbStatus) {
    UsbStatus_Disconnected = 0x00,
    UsbStatus_Connected = 0x01,
};

typedef NS_ENUM (NSUInteger, OnlinePinError) {
    OnlinePinError_CanceledOrTimed_Out = 0x08,
    OnlinePinError_Internal_Code_Error = 0x09,
    OnlinePinError_Internal_Error = 0x0A,
    OnlinePinError_InternalError_Codes = 0x0B,
    OnlinePinError_User_Bypassed_PIN = 0x0C,
    
};

typedef NS_ENUM (NSUInteger, ResetDeviceType) {
    ResetDeviceType_Soft_Reset = 0x00,
    ResetDeviceType_Hard_Reset = 0x01,
    ResetDeviceType_Clear_Files = 0x02,
    ResetDeviceType_Clear_Files_And_Reinitialise_MSD = 0x03,
};

/*!
 * @typedef GetDynamicResult
 * @brief Result of getDynamicTip method.
 *
 * @discussion This result code is provided afer the user has selected tip
 * on the Miura deivce. It can alos be used to determine if the user cancelled,
 * selected tip or some other error.
 *
 * @constant GetDynamicResult_Selected User selected tip.
 * @constant GetDynamicResult_Cancelled User cancelled by pressing the Red X key.
 * @constant GetDynamicResult_Error Some other error occoured.
 * @constant GetDynamicResult_Timeout This is optional, to be used to set a timeout.
 * @constant GetDynamicResult_Internal_Module_Error Used if an error has occurs internally.
 */
typedef NS_ENUM(NSUInteger, GetDynamicResult) {
    GetDynamicResult_Selected,
    GetDynamicResult_Cancelled,
    GetDynamicResult_Error,
    GetDynamicResult_Timeout,
    GetDynamicResult_Internal_Module_Error,
};


typedef NS_ENUM(NSUInteger, Numeric_Data_Result) {
    Numeric_Data_Result_Selected,
    Numeric_Data_Result_Cancelled,
    Numeric_Data_Result_Command_Formatting_Error,
    Numeric_Data_Result_Internal_Module_Error,
    Numeric_Data_Result_NumericTimeout,
};

/*!
 * @typedef RkiImportStatus
 * @brief RkiImportStatus fields
 * @constant RkiImportStatus_NoError is for no error found.
 * @constant RkiImportStatus_HSMMissing file is missing.
 * @constant RkiImportStatus_HSMCertFailure problem with hsm certificate.
 * @constant RkiImportStatus_ErrorWithRSAKey error found with rsa key.
 * @constant RkiImportStatus_ErrorWithTransportKey error found with the transport key.
 * @constant RkiImportStatus_ErrorWithDUKPT_Key error with the dukpt key.
 * @constant RkiImportStatus_ErrorWithDUKPT_Init error with the intailisation of dukpt.
 * @constant RkiImportStatus_InternalError we have an internal error contact miura.
 */
typedef NS_ENUM(NSUInteger, RkiImportStatus) {
    RkiImportStatus_NoError = 0x00,
    RkiImportStatus_HSMFileMissing = 0xE0,
    RkiImportStatus_FailedToValidateHSM = 0xE1,
    RkiImportStatus_FailedToLoadRSAKey = 0xE2,
    RkiImportStatus_FailedToValidateTransportKey = 0xE3,
    RkiImportStatus_FailedToInstallDUKPT_Key = 0xE4,
    RkiImportStatus_FailedToInstallDUKPT_Init = 0xE5,
    RkiImportStatus_InternalError = 0xE6,
};

/*!
 * @typedef RkiInitStatus
 * @brief RkiInitStatus fields
 * @constant RkiInitStatus_FileMissing missing a file.
 * @constant RkiInitStatus_FailedToGenerateRSAKey we have failed to gentrate teh rsa key.
 * @constant RkiInitStatus_FailedToLoadRSAKey failed to load the rsa key
 * @constant RkiInitStatus_FailedToCreateRSACert failed to create the rsa certificate.
 * @constant RkiInitStatus_FailedToPrepareOutputFiles we didn't get eth output files.
 * @constant RkiInitStatus_InternalError we have a an internar error contact miura.
 */
typedef NS_ENUM(NSUInteger, RkiInitStatus) {
    RkiInitStatus_FileMissing = 0xE0,
    RkiInitStatus_FailedToGenerateRSAKey = 0xE1,
    RkiInitStatus_FailedToLoadRSAKey = 0xE2,
    RkiInitStatus_FailedToCreateRSACert = 0xE3,
    RkiInitStatus_FailedToPrepareOutputFiles = 0xE4,
    RkiInitStatus_InternalError = 0xE5,
};

/*!
 * @typedef SecureDataResult
 * @brief SecureDataResult fields
 * contstant SecureDataResult_User pressed the Cancel button.
 * contstant SecureDataResult_Command timed-out without any user-input.
 * contstant SecureDataResult_Command formatting error. Indicates an SDK problem.
 * contstant SecureDataResult_Internal module error. Indicates an SDK or MPI problem.
 * contstant SecureDataResult_Incorrect P2PE status for this command, status include "SRED Ready".
 **/
typedef NS_ENUM(NSInteger, SecureDataResult) {
    SecureDataResult_Selected,
    SecureDataResult_UserCancelled,
    SecureDataResult_CommandFormattingError,
    SecureDataResult_InternalError,
    SecureDataResult_InvalidP2PEStatus,
    SecureDataResult_Timout,
};

/*!
 * @typedef ChargingStatus
 * @brief ChargingStatus fields
 * @constant ChargingStatus_OnBattery Unit is running on its internal battery.
 * @constant ChargingStatus_Charging Unit is connected to a power source and is charging the battery.
 * @constant ChargingStatus_Charged Unit is connected to a power source and the battery is fully charged.
 * @constant ChargingStatus_OnThresholdReached is set at a given threshold level. 
 * @constant ChargingStatus_ChargeError Unit has a charing error.
 * @constant ChargingStatus_ChargeTimerExpired Unit has a charing error.
 * @constant ChargingStatus_UnhandledVaule Unit has an unknown charging error.
 */
typedef NS_ENUM (NSUInteger, ChargingStatus) {
    ChargingStatus_OnBattery = 0x00,
    ChargingStatus_Charging = 0x01,
    ChargingStatus_Charged = 0x02,
    ChargingStatus_OnThresholdReached = 0x03,
    /**
     * The unit has a charging error.
     *
     * Error reported from battery charger.
     * If this persists or is causing other issues please contact the solution provider.
     */
    ChargingStatus_ChargeError = 0xF0,
    /**
     * The unit has a charging error.
     *
     * Error reported from battery charger.
     * If this persists or is causing other issues please contact the solution provider.
     */
    ChargingStatus_ChargeTimerExpired = 0xF1,
    /**
     * The unit has a charging error.
     *
     * Error reported from battery charger.
     * If this persists or is causing other issues please contact the solution provider.
     */
    ChargingStatus_UnhandledVaule = 0xF2,
};

/*!
 * @typedef PrinterSledStatus
 * @brief PrinterSledStatus fields
 * @constant PrinterSledStatus_Printer_Power unit has power or not.
 * @constant PrinterSledStatus_Printer_Present printer is attached or detached to PED.
 * @constant PrinterSledStatus_Reserved paper is OK or out
 * @constant PrinterSledStatus_Print_Data_Scheduled reports if printing scheduled or not.
 * @constant PrinterSledStatus_Printing used if device is printing or not printing
 * @constant PrinterSledStatus_Printer_Error this is used for weaver and Error is shown or not.
 */
typedef NS_ENUM(NSUInteger, PrinterSledStatus){
    PrinterSledStatus_Printer_Power = 0x00,
    PrinterSledStatus_Printer_Present = 0x01,
    PrinterSledStatus_Printer_Status = 0x02,
    PrinterSeldStatus_Print_Data_Scheduled = 0x03,
    PrinterSeldStatus_Printing = 0x04,
    PrinterSledStatus_Printer_Error = 0x05,
    PrinterSeldStatus_Printer_Unused = 0x06,
    PrinterSledStatus_Printer_Unknown = 0x07,
};

/*!
 * @typedef DeviceStatus
 * @brief Device status params
 * @constant DeviceStatus_DevicePoweredOn This is always sent when opening a session with the PED.
 * @constant DeviceStatus_PinEntryEvent This is sent when the user enters a PIN digit. NOTE: the digit is not sent!
 * @constant DeviceStatus_DevicePoweringOff This is sent immediatley before the device powers down.
 * @constant DeviceStatus_ErrorBeep Used to indicate the app should emit an error beep during a contactless transaction
 * @constant DeviceStatus_SeePhone This is sent during a contactless transaction when the user is asked to enter the PIN on the phone used for the payment
 * @constant DeviceStatus_SuccessBeep Used to indicate the app should emit a success beep during a contactless transaction
 */
typedef NS_ENUM (NSUInteger, DeviceStatus) {
    DeviceStatus_DevicePoweredOn = 0x01,
    DeviceStatus_PinEntryEvent = 0x02,
    DeviceStatus_ApplicationSelection = 0x03,
    DeviceStatus_DevicePoweringOff = 0x0A,
    DeviceStatus_DeviceRebooting = 0x0B,
    DeviceStatus_MPIRestarting = 0x0C,
    DeviceStatus_SeePhone = 0xC0,
    DeviceStatus_SuccessBeep = 0xCB,
    DeviceStatus_ErrorBeep = 0xCE,
};

/*!
 * @typedef KeyPadStatusSettings
 * @brief Enum used to enable or disable the keyboard status messages
 * @constant KeyPadStatusSettings_Disable Disable keyboard messages
 * @constant KeyPadStatusSettings_Enable Enable keyboard messages
 * @constant KeyPadStatusSettings_No_Change Do not change the current status
 */
typedef NS_ENUM (NSUInteger, KeyPadStatusSettings) {
    KeyPadStatusSettings_Disable = 0x00,
    KeyPadStatusSettings_Enable = 0x01,
    KeyPadStatusSettings_No_Change = 0xFF,
};

/*!
 * @typedef BacklightSettings
 * @brief Enum used to switch the display backlight on or off. Note some units do not have a backlit display.
 * @constant BacklightSettings_Disable Disable display backlight
 * @constant BacklightSettings_Enable Enable display backlight
 * @constant BacklightSettings_No_Change Do not change the current backlight status
 */
typedef NS_ENUM (NSUInteger, BacklightSettings) {
    BacklightSettings_Disable = 0x00,
    BacklightSettings_Enable = 0x01,
    BacklightSettings_No_Change = 0xFF,
};

/*!
 * @typedef TransactionType
 * @brief Enum used to specify the type of transaction. This is used for chip transactions.
 * @constant TransactionType_Purchase Standard goods transaction
 * @constant TransactionType_Cash Used to with draw cash from an account, used in cash at POS solutions.
 * @constant TransactionType_PurchaseWithCashback Standard goods transaction with cash back
 * @constant TransactionType_Refund Refund transaction.
 */
typedef NS_ENUM (NSUInteger, TransactionType) {
    TransactionType_Purchase = 0x00,
    TransactionType_Cash = 0x01,
    TransactionType_PurchaseWithCashback = 0x09,
    TransactionType_Refund = 0x20,
};

/*!
 * @typedef ContactlessResponse
 * @brief Enum to responsed to  contactless transaction.
 * @constant ContactlessResponse_Command_Not_Allowed not allowed in this state.
 * @constant ContactlessResponse_User_Cancelled cancel key during the transaction or the abort command was sent.
 * @constant ContactlessResponse_Contactless_Timedout contactless transaction timed out.
 * @constant ContactlessResponse_Aborted_By_Card_Insert Card was inserted whilst waiting for a contactless card.
 * @constant ContactlessResponse_Aborted_By_Swipe not possible on the contactless interface.
 * @constant ContactlessResponse_Insert_Or_Swiped transaction not possible with this card.
 * @constant ContactlessResponse_Insert_Swipe_Or_Other_Card insert or swipe the card or try another card.
 * @constant ContactlessResponse_Insert_Card requested transaction to be processed on the contact interface.
 * @constant ContactlessResponse_Hardware_Error internal hardware error
 * @constant ContactlessResponse_Unknown unknown response from device/unsupported
 */
typedef NS_ENUM (NSUInteger, ContactlessResponse) {
    ContactlessResponse_Command_Not_Allowed = 0x26,
    ContactlessResponse_User_Cancelled = 0x41,
    ContactlessResponse_Contactless_Timedout = 0x42,
    ContactlessResponse_Aborted_By_Card_Insert = 0x43,
    ContactlessResponse_Aborted_By_Swipe = 0x44,
    ContactlessResponse_Insert_Or_Swiped = 0xC1,
    ContactlessResponse_Insert_Swipe_Or_Other_Card = 0xC2,
    ContactlessResponse_Insert_Card = 0xC3,
    ContactlessResponse_Hardware_Error = 0xCF,
    ContactlessResponse_Unknown = 0xFF,
};

/*!
 * @typedef TransactionResponse
 * @brief Enum to responsed to transaction response.
 * @constant TransactionResponse_Invalid_Data_In_Command invalid data in command APDU
 * @constant TransactionResponse_Terminal_Not_Ready terminal not ready
 * @constant TransactionResponse_No_Smartcard_In_Slot no smartcard in slot
 * @constant TransactionResponse_Invalid_Card_Responded_Incorrectly invalid card, card responded incorrectly, no MSR fall back allowed.
 * @constant TransactionResponse_Command_Not_Allows_At_This_State command not allowed at this state
 * @constant TransactionResponse_Data_Missing_From_Command_APDU data missing from command APDU (data field should list missing object
 * @constant TransactionResponse_Unsupported_Card_EMV_Kernal unsupported card, EMV Kernel not configured for this card, MSR fall back allowed
 * @constant TransactionResponse_Missing_File data field should list missing file
 * @constant TransactionResponse_ICC_Read_Error ICC read error
 * @constant TransactionResponse_Invalid_Issuer_Public_Key invalid issuer public key, hash check failed
 * @constant TransactionResponse_User_Cancelled the user cancelled the transaction.
 * @constant TransactionResponse_Missing_Mandatory_Input_Parameters missing mandatory input parameters
 */
typedef NS_ENUM(NSUInteger, TransactionResponse) {
    TransactionResponse_Invalid_Data_In_Command = 0x21,
    TransactionResponse_Terminal_Not_Ready = 0x22,
    TransactionResponse_No_Smartcard_In_Slot = 0x23,
    TransactionResponse_Invalid_Card_Responded_Incorrectly = 0x25,
    TransactionResponse_Command_Not_Allows_At_This_State = 0x26,
    TransactionResponse_Data_Missing_From_Command_APDU = 0x27,
    TransactionResponse_Unsupported_Card_EMV_Kernal = 0x28,
    TransactionResponse_Missing_File = 0x2A,
    TransactionResponse_ICC_Read_Error = 0x30,
    TransactionResponse_Invalid_Issuer_Public_Key = 0x40,
    TransactionResponse_User_Cancelled = 0x41,
    TransactionResponse_Missing_Mandatory_Input_Parameters = 0x88,
};

/*!
 * @typedef TargetDevice
 * @brief Enum used to specify the type of device the SDK is communicating with.
 * @constant TargetDevice_PED PIN Entry Device, typically an Miura M006 M007 or M010
 * @constant TargetDevice_POS POS Smart Hub, Typically a POSzel or an ITP
 */
typedef NS_ENUM (NSUInteger, TargetDevice) {
    TargetDevice_PED = 0x01,
    TargetDevice_POS = 0x02,
};

/*!
 * @typedef ServiceCodeFirstDigit
 * @brief Enum used to evaluate the first digit of the service code on the magnetic swipe data of a card.
 * More information can be found here: https://en.wikipedia.org/wiki/Magnetic_stripe_card#Financial_cards
 */
typedef NS_ENUM (NSUInteger, ServiceCodeFirstDigit) {
    ServiceCodeFirstDigit_InternationalInterchange = 1,
    ServiceCodeFirstDigit_InternationalInterchange_UseIC = 2,
    ServiceCodeFirstDigit_NationalInterchangeOnly = 5,
    ServiceCodeFirstDigit_NationalInterchangeOnly_UseIC = 6,
    ServiceCodeFirstDigit_NoInterchange = 7,
    ServiceCodeFirstDigit_Test = 9,
};

/*!
 * @typedef ServiceCodeSecondDigit
 * @brief Enum used to evaluate the second digit of the service code on the magnetic swipe data of a card.
 * More information can be found here: https://en.wikipedia.org/wiki/Magnetic_stripe_card#Financial_cards
 */
typedef NS_ENUM (NSUInteger, ServiceCodeSecondDigit) {
    ServiceCodeSecondDigit_Normal = 0,
    ServiceCodeSecondDigit_AuthorizedOnline = 2,
    ServiceCodeSecondDigit_AuthorizedOnlineExceptBilateralAgreement = 4,
};

/*!
 * @typedef ServiceCodeThirdDigit
 * @brief Enum used to evaluate the third digit of the service code on the magnetic swipe data of a card.
 * More information can be found here: https://en.wikipedia.org/wiki/Magnetic_stripe_card#Financial_cards
 */
typedef NS_ENUM (NSUInteger, ServiceCodeThirdDigit) {
    ServiceCodeThirdDigit_NoRestrictions_PINRequired = 0,
    ServiceCodeThirdDigit_NoRestrictions = 1,
    ServiceCodeThirdDigit_GoodsAndServicesOnly_NoCash = 2,
    ServiceCodeThirdDigit_ATMOnly_PINRequired = 3,
    ServiceCodeThirdDigit_CashOnly = 4,
    ServiceCodeThirdDigit_GoodsAndServicesOnly_NoCash_PINRequired = 5,
    ServiceCodeThirdDigit_NoRestrictions_PINOptional = 6,
    ServiceCodeThirdDigit_GoodsAndServicesOnly_NoCash_PINOptional = 7,
};

/*!
 * @typedef PrinterSpoolControlError
 * @brief Error codes returned from the printer.
 * @constant PrinterSpoolControlError_Success If successful printing
 * @constant PrinterSpoolControlError_noPrinter Cannot complete the print as no printer can be found by the device.
 * @constant PrinterSpoolControlError_noPaper Printer is out of paper
 * @constant PrinterSpoolControlError_internalError Internal error
 * @constant PrinterSpoolControlError_imageNotFound Request to print an image which has not previously been installed to the device.
 * @constant PPrinterSpoolControlError_incorrectImageFormat Request to print an image from an unsupported format
 * @constant PrinterSpoolControlError_SpoolFull Spool buffer used to store print data is full.
 * @constant PrinterSpoolControlError_transferFailed Failed to transfer the image to the device.
 */
typedef NS_ENUM (NSUInteger, PrinterSpoolControlError) {
    PrinterSpoolControlError_Success = 0,
    PrinterSpoolControlError_noPrinter = 1,
    PrinterSpoolControlError_noPaper = 2,
    PrinterSpoolControlError_reservedStatus = 3,
    PrinterSpoolControlError_internalPrintError = 4,
    PrinterSpoolControlError_imageNotPresent = 5,
    PrinterSpoolControlError_imageFileIncorrectFormat = 6,
    PrinterSpoolControlError_spoolBufferFull = 7,
    PrinterSpoolControlError_transferFailed = 0x100,
};

/*!
 * @typedef SelectFilemode
 * @brief Select file mode sets current file.
 * @constant SelectFileMode_Append_Mode current logical channel for future file access.
 * @constant SelectFileMode_Truncate_Mode implicitly refer to the current file through that logical channel
 */
typedef NS_ENUM (NSUInteger, SelectFileMode) {
    SelectFileMode_Append_Mode = 0x00,
    SelectFileMode_Truncate_Mode = 0x01,
};

/*!
 * @typedef TouchCaptureError
 * @brief Returned Error messages from touch screen.
 * @constant TouchCaptureError_Internal_Error If error happens while buidling.
 * @constant TouchCaptureError_Internal_Error this is for invaild command parameter
 * @constant TouchCaptureError_Internal_Error Invaild command (check CLA and INS parameters).
 * @constant TouchCaptureError_Internal_Error This is used for empty command received.
 * @constant TouchCaptureError_Internal_Error If user has an invaild area.
 * @constant TouchCaptureError_Internal_Error Thsi will show if screen module not available.
 */
typedef NS_ENUM(NSUInteger, TouchCaptureError) {
    TouchCaptureError_Error_Building = 0x00,
    TouchCaptureError_Internal_Error = 0x0D,
    TouchCaptureError_InvalisCommand = 0x0F,
    TouchCaptureError_Empty_Command = 0x14,
    TouchCaptureError_Invalid_Area = 0x21,
    TouchCaptureError_Not_Available = 0xCE,
};

/*!
 * @typedef GetMenuResult
 * @brief Result of getMenuOption method.
 *
 * @discussion This result code is provided afer the user has selected an option
 * on the Miura deivce. It can be used to determine if the user cancelled,
 * selected an option, the process timed out or some other error.
 *
 * @constant GetMenuResult_Selected User slected an option.
 * @constant GetMenuResult_Cancelled User cancelled by pressing the Red X key.
 * @constant GetMenuResult_Timeout The User did not select anything and the process timed out.
 * @constant GetMenuResult_Error Some other error occoured.
 */
typedef NS_ENUM(NSUInteger, GetMenuResult) {
    GetMenuResult_Selected,
    GetMenuResult_Cancelled,
    GetMenuResult_Timeout,
    GetMenuResult_Error,
    
};

/*!
 * @interface ServiceCode
 * @brief Class containing the service code from a mag swipe card
 * @discussion Contains a property for each service code digit from the mag swipe data.
 */
@interface ServiceCode: NSObject
/*!
 * @brief Service code digit 1
 */
@property ServiceCodeFirstDigit firstDigit;
/*!
 * @brief Service code digit 2
 */
@property ServiceCodeSecondDigit secondDigit;
/*!
 * @brief Service code digit 3
 */
@property ServiceCodeThirdDigit thirdDigit;
/*!
 * @brief String containing full Service code
 */
@property (readonly, nonnull) NSString *stringValue;
@end

#pragma mark - Interface
/*!
 * @interface Track2Data
 * @brief Class containing the data received on the track 2 of a mag swipe card
 */
@interface Track2Data: NSObject
#pragma mark - Property
/*!
 * @brief Raw masked track 2 data
 */
@property (nullable) NSString *data;
/*!
 * @brief String containing the masked PAN
 */
@property (nullable) NSString *PAN;
/*!
 * @brief String containing card expiry date
 */
@property (nullable) NSString *expirationDate;
/*!
 * @brief Service code object containing 3 digits.
 */
@property (nullable) ServiceCode *serviceCode;
@end

#pragma mark - Interface
/*!
 * @interface CardStatus
 * @brief Class used to decide what type of card has been used on the PED.
 */
@interface CardStatus: NSObject
#pragma mark - Property
/*!
 * @brief A card has been detected in the SmartCard or Magnetic swipe slot.
 */
@property BOOL isCardPresent;
/*!
 * @brief If this is true the card is detected on the SmartCard slot and the chip is operational.
 * This indicates a Contact Transaction can start.
 */
@property BOOL isEMVCompatible;
/*!
 * @brief This is set to true if valid mag-swipe data was read from a card swipe
 */
@property BOOL isMSRDataAvailable;
/*!
 * @brief This is set to true if the Track 1 data was successfully decoded
 */
@property BOOL isTrack1DataAvailable;
/*!
 * @brief This is set to true if the Track 2 data was successfully decoded
 */
@property BOOL isTrack2DataAvailable;
/*!
 * @brief This is set to true if the Track 3 data was successfully decoded
 */
@property BOOL isTrack3DataAvailable;
@end

#pragma mark - Interface
/*!
 * @interface CardData
 * @brief Object containing card data.
 */
@interface CardData: NSObject
#pragma mark - Property
/*!
 * @brief The raw data received from the PED
 */
@property (nonnull) NSData *raw;
/*!
 * @brief Populated CardStatus data
 */
@property (nonnull) CardStatus *cardStatus;
/*!
 * @brief Low level data from the chip card. Not required for most implementations.
 */
@property (nullable) NSString *answerToReset;
/*!
 * @brief DUKPT encrypted block containing track data from a mag swipe card.
 */
@property (nullable) NSString *sredData;
/*!
 * @brief DUPKT Key serial number. Required by the host for the decrypt operation
 */
@property (nullable) NSString *sredKSN;
/*!
 * @brief Track 2 data object. See relevant class.
 */
@property (nullable) Track2Data *track2Data;
@end

#pragma mark - Interface
/*!
 * @interface OnlinePinResponse
 * @brief Object containing the data captured from an online PIN request to the PED.
 */
@interface OnlinePinResponse: NSObject
#pragma mark - Property
/*!
 * @brief DUPKT encrypted PIN block.
 */
@property (nullable) NSString *pinData;
/*!
 * @brief DUPKT Key serial number. Required by the host for the decrypt or translate operation
 */
@property (nullable) NSString *pinKSN;
@end

#pragma mark - Interface
/*!
 * @interface P2PEStatus
 * @brief Helper class used to determine what keys are installed on a Miura device
 */
@interface P2PEStatus: NSObject
#pragma mark - Property
/*!
 * @brief This is true after the P2PE Initialise call
 */
@property BOOL isInitialised;
/*!
 * @brief This is true when a valid online PIN key is installed
 */
@property BOOL isPINReady;
/*!
 * @brief This is true when a valid Account Data or SRED encryption key is installed
 */
@property BOOL isSREDReady;
@end

#pragma mark - Interface
/*!
 * @interface SoftwareInfo
 * @brief Helper class to access software version information
 */
@interface SoftwareInfo: NSObject
#pragma mark - Property
/*!
 * @brief Gives access to the raw binary data stream
 */
@property (nonnull) NSData *raw;
/*!
 * @brief String containing device serial number in EMV compatible format 8 digits long
 */
@property (nullable) NSString *serialNumber;
/*!
 * @brief String describing the OS Version number
 */
@property (nullable) NSString *OSVersion;
/*!
 * @brief String describing the OS type, typically M000-OS or M000-TESTOS
 */
@property (nullable) NSString *OSType;
/*!
 * @brief String giving the MPI or RPI version number
 */
@property (nullable) NSString *MPIVersion;
/*!
 * @brief String describing the MPI or RPI installed. Typically M000-MPI or M000-TESTMPI for PED devices and M000-RPI for POS devices
 */
@property (nullable) NSString *MPIType;
@end

#pragma mark - Define protocol
/*!
 * @protocol MiuraManagerDelegate
 * @brief The MiuraManagerDelegate Protocol.
 * This is used to handle event messages from the PED or POS device
 */
@protocol MiuraManagerDelegate <NSObject>
@required
/*!
 * @brief Method called when a device is disconnected. It may have gone to sleep or moved out of range.
 */
- (void)miuraManager:(nonnull MiuraManager *)manager accessoryDidDisconnect:(nonnull EAAccessory *)accessory;
/*!
 * @brief Called when the user presses a key on the Miura device. This will only be called if the events have been enabled by the keyboardStatus method
 */
- (void)miuraManager:(nonnull MiuraManager *)manager keyPressed:(NSUInteger)keyCode;
/*!
 * @brief Called when the user inserts or swipes a card in the PED. This is enabled and disabled by the cardStatus method
 */
- (void)miuraManager:(nonnull MiuraManager *)manager cardStatusChange:(nonnull CardData *)cardData;
/*!
 * @brief Called when any device status change event occurs. See ENUM above for full list.
 */
- (void)miuraManager:(nonnull MiuraManager *)manager deviceStatusChange:(DeviceStatus)deviceStatus text:(nonnull NSString *)statusText;
/*!
 * @brief Called when the POS unit receives some bar code data from a scan
 */
- (void)miuraManager:(nonnull MiuraManager *)manager barCodeScan:(nonnull NSString *)barCodeSrting;
/*!
 * @brief Called when any printer Sled device status change event occurs, if enabled. See ENUM for full list.
 */
-(void)miuraManager:(nonnull MiuraManager *) manager printerSledStatus:(PrinterSledStatus)printerStatus;
/*!
 * @brief Called when the usb is connected or disconnected and the event was enabled..
 */
-(void)miuraManager:(nonnull MiuraManager *)manager usbStatusChange:(UsbStatus)usbStatusChanged;
/*!
* @brief Called when battery status events have changed..
*/
-(void)miuraManager:(nonnull MiuraManager *)manager batteryStatusChange:(ChargingStatus)batteryStatusChange;

@end


#pragma mark - Define blocks
typedef void (^MPIBlocksSelectAccessory)(NSArray * _Nullable accessories);

typedef void (^MPIBlocksSolicited)(MiuraManager * _Nonnull manager, MPIResponseData * _Nonnull response);
typedef void (^MPIExecutorCompletion)(BOOL result);


#pragma mark - Interface
/*!
 * @class MiuraManager
 * @classdesign Singleton
 * @brief Main class of the Miura SDK.
 *
 * @discussion To communicate with Miura device follow these steps:
 * <ul>
 * <li>Obtain singleton instance by calling `[sharedInstance]`
 * <li>List available devices with `[connectedAccessories]`
 * <li>Open a session with the device of choice by using one of `[openSession...]` methods
 * </ul>
 *
 */
@interface MiuraManager: NSObject< EAAccessoryDelegate, NSStreamDelegate >


#pragma mark - Property
@property(nonatomic, weak, nullable) id< MiuraManagerDelegate > delegate;

/*!
 * @brief List of protocols
 */
@property(nonatomic, copy, nullable) NSArray *protocolNames;
@property(nonatomic, readonly, copy, nullable) NSString *deviceName;
@property(nonatomic, readonly, assign) NSUInteger readableBytesLength;
@property(nonatomic, readonly, assign, getter=isConnected) BOOL connected;
@property(nonatomic, copy, nullable) NSString *priorityDeviceIdentify;
@property TargetDevice targetDevice;


/*!
 * @brief Returns the singleton instance of `MiuraManager` class, creating it if needed.
 */
+ (nonnull instancetype)sharedInstance;

#pragma mark - Commands

/*!
 * @brief Returns an array of EAAccessorys, containing connected Miura devices.
 *
 * @return NSArray of EAAccessory
 */
- (nullable NSArray *)connectedAccessories;

/*!
 * @brief Returns an array of EAAccessorys, containing connected Miura devices that support at least one of provided protocol names.
 *
 * @param protocolNames The NSString array of protocol names
 * @return NSArray of EAAccessory
 */
- (nullable NSArray *)connectedAccessoriesWithProtocolNames:(nonnull NSArray *)protocolNames;

/*!
 * @brief Returns an array of EAAccessorys, containing connected Miura devices that support the given protocol name.
 *
 * @param protocolName The protocol name
 * @return NSArray for EAAccessory
 */
- (nullable NSArray *)connectedAccessoriesWithProtocolName:(nonnull NSString *)protocolName;

//- (BOOL)selectPriorityDevice;
- (BOOL)selectPriorityDevice:(nullable MPIBlocksSelectAccessory)selectAccessory;

/*!
 * @brief Opens Miura Session with the previously connected device, if any.
 *
 * @return True if successful
 */
- (BOOL)openSession;

/*!
 * @brief Opens Miura Session for a device with the given serial number.
 *
 * @param serialNumber The serial number of the Miura device
 * @return True on successful connection false on failure
 */
- (BOOL)openSessionWithAccessorySerialNumber:(nonnull NSString *)serialNumber;

/*!
 * @brief Opens a socket to a Miura device over WiFi. Device must have WiFi enabled and configured. Default port number of 6543 is used.
 *
 * @param ipAddress The IP address of the Miura device
 * @returns Yes on successful connection No on failure
 */
- (BOOL)openWiFiAccessory:(nonnull NSString *)ipAddress;

/*!
 * @brief Opens Miura Session for a given device and given protocol names.
 *
 * @param accessory The accessory to connect with
 * @param protocolNames The array of protocol names
 * @return True on successful connection false on failure
 */
- (BOOL)openSession:(nonnull EAAccessory *)accessory protocolNames:(nonnull NSArray *)protocolNames;

/*!
 * @brief Opens Miura Session for a given device and given protocol name.
 *
 * @param accessory The accessory to connect with
 * @param protocolName The protocol names
 * @return True on successful connection false on failure
 */
- (BOOL)openSession:(nonnull EAAccessory *)accessory protocolName:(nonnull NSString *)protocolName;

/*!
 * @brief Closes currently open Session with the device.
 */
- (void)closeSession;

- (void)writeData:(nonnull NSData *)data;

- (nullable NSData *)readData;

- (nullable NSData *)readData:(NSUInteger)length;

- (void)queueSolicitedBlock:(nullable MPIBlocksSolicited)block;

- (void)queueSolicitedBlockWithSwitch:(nullable MPIBlocksSolicited)block;

- (nullable MPIBlocksSolicited)dequeueSolicitedBlock;

/*!
 * @brief Displays text on the screen.
 *
 * @param text The text to be displayed
 * @param completion The block to be executed when response message is received. This will indicate if the command was successful or not.
 */
- (void)displayText:(nonnull NSString *)text
         completion:(void(^ _Nullable)(BOOL success))completion;

/*!
 * @brief Displays image on the screen.
 *
 * @param fileName The file name of the image to display
 * @param completion The block to be executed when response message is received. This will indicate if he command was successful or not.
 */
- (void)displayImageNamed:(nonnull NSString *)fileName
               completion:(void(^ _Nullable)(BOOL success))completion;

/*!
 * @brief Enable or Disable key press events from the connected device.
 * @discussion If the events are enabled, they can be handled by the application by implementing the connection delegate.
 *
 * @param statusSetting Use it to enable/disable sending keyboard events. See Enum for details.
 * @param backlightSetting Use it to enable/disable keyboard backlight (on selected devices). See Enum for details
 */
- (void)keyboardStatus:(KeyPadStatusSettings)statusSetting
      backlightSetting:(BacklightSettings)backlightSetting
            completion:(nullable MPIBlocksSolicited)completion;

/*!
 * @brief Enable the card status command for mag swipe and Chip inserts
 * @discussion Helper function is simpler than the cardStatus command.
 * This is used to enable or disable the PED cardstatus call back in the MiuraManagerDelegate.
 * This will enable mag track 1 and 2 only and the smart card reader inserts.
 * Track 3 is not required for most payment applications.
 *
 * @param enableStatus Set to true to enable messages false to disable messages
 * @param completion Completion block to be called when the command has completed
 */

- (void)magAndChipCardStatusEnable:(BOOL)enableStatus
                        completion:(void(^ _Nullable)(BOOL success))completion;

/*!
 * @brief Enable or disable the card event messages from the connected device.
 *
 * @discussion This can be used to start or stop receiveing information about mag swipe events from the PED or card inserts in the smartcard slot.
 *
 * @param enableUnsolicited Set to true to enable sending card status related events
 * @param enableAtr If a chip card is inserted, include the ATR in the response. This is not required in most implementations
 * @param enableTrack1 If track 1 is present on the mag swipe card, send the data in the event message
 * @param enableTrack2 If track 2 is present on the mag swipe card, send the data in the event message
 * @param enableTrack3 If track 3 is present on the mag swipe card, send the data in the event message
 * @param completion The block to execute
 */
- (void)cardStatus:(BOOL)enableUnsolicited
         enableAtr:(BOOL)enableAtr
      enableTrack1:(BOOL)enableTrack1
      enableTrack2:(BOOL)enableTrack2
      enableTrack3:(BOOL)enableTrack3
        completion:(void(^ _Nullable)(BOOL success))completion;

/*!
 * @brief Send the connected PED to sleep
 *
 * @discussion This will send the currently connected PED to sleep. The completion will give the current
 *             battery status, then the connection will drop.
 *             The response data provided in the completion block will give a battery percentage and a
 *             current charging status.
 *             See the relevant ENUM for details.
 *
 * @param completion The block to execute when the response is received.
*/

- (void) setPedSleep:(void(^_Nullable)(ChargingStatus chargingStatus, NSUInteger batteryPercentage))completion;

/*!
 * @brief Get the current status of the PED battery
 *
 * @discussion The response data provided in the completion block will give a battery percentage and a current charging status.
 * See the relevant ENUM for details.
 *
 * @param completion The block to execute when the response is received.
 */
- (void)getBatteryStatus:(void(^_Nullable)(ChargingStatus chargingStatus, NSUInteger batteryPercentage))completion;

/*!
 * @brief Enable or Disable battery status events from the connected device.
 *
 * @discussion The PED will optionally send event messages when the battery low threshold is reached
 *             or when the device is put on or removed from charging
 *
 * @param onChargingChange if true the started/stopped charging event will be sent.
 * @param onThresholdReached If set to true enable battery status message when low battry is detected.
 * @param completion The block to execute when the response is received. This will contain the current status.
 */
- (void) setBatteryStatusEvents:(BOOL) onChargingChange
             onThresholdReached:(BOOL)onThresholdReached
                     completion:(void(^_Nullable)(ChargingStatus chargingStatus, NSUInteger batteryPercentage))completion;

/*!
 * @brief Enables or disables the barcode scan events.
 *
 * @discussion This will enable the scan data to be sent from the connected device to the application.
 * The relevant MiuraManagerDelegate callback will be called when the data is available.
 *
 * @param enable true to start or false to stop receiving scan data from device.
 * @param completion The block to execute when the response messages is received. This will not contain any scan data.
 */
- (void)barcodeScanStatus:(BOOL)enable
               completion:(void(^ _Nullable)(BOOL success))completion;

/*!
 * @brief Query the state of the cash draw and optionally open the draw.
 *
 * @param openDraw Set to true to open the cash drawer when the command is sent to the device.
 * @param completion Completion block to execute when the response is returned from the device. The drawIsOpen parameter will contain the current state of the raw. True is open false is closed.
 */
- (void)queryCashDraw:(BOOL)openDraw
           completion:(void(^ _Nullable)(BOOL drawIsOpen))completion;

/*!
 * @brief Add some text to the print queue in the device.
 * @discussion Formatting codes are also supported as of RPI V1-3.
 * For more information see the developer guide
 *
 * @param text String to add to the print queue
 * @param completion block to execute when the command is complete. This will return the response code as described in the relevant enum.
 */
- (void)spoolTextWithString:(nonnull NSString *) text
                 completion:(void(^ _Nullable)(PrinterSpoolControlError result))completion;

/*!
 * @brief Add an image file to the print spool.
 * @discussion The image needs to be transferred to the device before hand using the uplaodBinary and applyUpdateWithCompletion commands.
 *
 * @param fileName filename of the image to be printed
 * @param completion completion block to be executed after the command is complete. This will return the response code as described in the relevant enum.
 */
- (void)spoolImageWithFileName:(nonnull NSString *)fileName
                    completion:(void(^ _Nullable)(PrinterSpoolControlError result))completion;

/*!
 * @brief Print the spool queue to the printer connected to the device.
 *
 * @discussion This assumes that some text and or images have been added to the spool queue.
 * These are sent using the spoolTextWithString and spoolImageWithFileName.
 * On a POS device with a fixed printer the print will occur immediately,
 * on an M012 printer dock the print may be deferred until the printer is connected and docked.
 *
 * @param completion Completion block to execute when the command has been sent. This will return the response code as described in the relevant enum.
 */
- (void)spoolPrintWithCompletion:(void(^ _Nullable)(PrinterSpoolControlError result))completion;

/*!
 *@brief Print ESC/POS data to the printer.
 *
 *This will allow printing immediately at every LF (line feed) character sent to printer.
 *For more information see the developer guide
 *
 * @param text String to add to the print
 */
- (void)printESCPOSWithString:(nonnull NSString *) text
                   completion:(void(^ _Nullable)(PrinterSpoolControlError result))completion;

/*!
 * @brief Printer Sled status enabled messages.
 *
 * @discussion This method enables or disables printer sled status messages from the PED.
 * If the current status is returned in the completion method. Further status changes are
 * notified via the callback in the MiuraManager Delegate.
 *
 * @param statusMessageEnabled Enable or disable the printer sled status messages.
 * @param completion Completion block to execute when the command has been sent. This will return the responses as described in the relevant enum.
 */
- (void)printerSledStatusEnable:(BOOL) statusMessageEnabled
                     completion:(void (^ _Nullable)(PrinterSledStatus result))completion;

/*!
 * @brief Returns a list of configuration files on the device, along with their versions.
 *
 * @discussion The completion block will return an array of string pairs which the application can parse.
 *
 * @param completion The block to execute.
 */

- (void)getConfigurationWithCompletion:(void(^ _Nullable)(NSDictionary<NSString *, NSString *> *_Nullable configVersions))completion;

/*!
 * @brief Returns a list of the hardware capabilities of the device.
 *
 * @discussion The completeion block will supply an array of string pairs which can be inspected by the application.
 * Possible values include: "Smartcard", "Contactless", "USB_Bluetooth", "Display", "Keyboard", "Mag".
 * For a full list, please refer to the documentation.
 *
 * @param completion The block to execute after the downloading finishes
 */
- (void)getDeviceCapabilitiesWithCompletion:(void(^ _Nullable)(NSDictionary<NSString *, NSString *> * _Nullable capabilities))completion;

/*!
 * @brief Starts EMV contact transaction.
 *
 * @discussion This function is specific to contact or chip based transaction rather than mag-swipe or contactless.
 * This will start the transaction processing with the card and may also involve a user PIN entry stage,
 * therefore there will be some time before the completion block is executed.
 *
 * @param transactionType The transaction type
 * @param amount The amount
 * @param currencyCode ISO 4217 code, see here for details: https://en.wikipedia.org/wiki/ISO_4217
 * @param completion The block to execute
 */
- (void)startTransactionWithType:(TransactionType)transactionType
                          amount:(NSUInteger)amount
                    currencyCode:(NSUInteger)currencyCode
                      completion:(nullable MPIBlocksSolicited)completion;

/*!
 * @brief Continues a transaction for contact or contactless.
 *
 * @discussion Typically used after the online Auth stage to complete the transaction.
 *
 * @param transactionInfo The transaction info
 * @param completion The block to execute when the transaction is complete or needs to exchange data to continue.
 */
- (void)continueTransaction:(nonnull MPITLVObject *)transactionInfo
                 completion:(nullable MPIBlocksSolicited)completion;

/*!
 * Starts Contactless transaction
 *
 * @param transactionType The {@link TransactionType}
 * @param amountInPennies Amount in pennies
 * @param currencyCode    ISO 4217 code, see here for details: https://en.wikipedia.org/wiki/ISO_4217
 * @param listener        {@link ApiStartTransactionListener} Event listener for result - contains result byte data
 */
- (void)startContactlessTransactionWithType:(TransactionType)transactionType
                                     amount:(NSUInteger)amount
                               currencyCode:(NSUInteger)currencyCode
                                 completion:(nullable MPIBlocksSolicited)completion;
/*!
 * @brief Starts a Contactless transaction.
 *
 * @param transactionType The transaction type
 * @param amount The amount
 * @param currencyCode ISO 4217 code, see here for details: https://en.wikipedia.org/wiki/ISO_4217
 * @param languagePreference 2 digit country code based on ISO 3166, but will match with the config file name installed on the device.
 * @param completion The block to execute when the transaction is complete or needs to exchange data to continue.
 */
- (void)startContactlessTransactionWithType:(TransactionType)transactionType
                                     amount:(NSUInteger)amount
                               currencyCode:(NSUInteger)currencyCode
                         languagePreference:(nonnull NSString *)languagePreference
                                 completion:(nullable MPIBlocksSolicited)completion;

/*!
 * @brief Cancel a contact or contactless transaction
 *
 * @discussion This can be used if the transaction is progressing on the PED but for some reason it needs to be stopped.
 *
 * @param completion The block to execute when the response to the command is received. True on success false on failure.
 */
- (void)abortTransactionWithCompletion:(void(^_Nullable)(BOOL result))completion;

/*!
 * @brief Initiates Online PIN process.
 *
 * @discussion If successful, response will contain at least these fields:
 * <ul>
 * <li>Online PIN block</li>
 * <li>Online PIN Key Serial Number</li>
 * </ul>
 *
 * @param amount The amount mantissa
 * @param currencyCode ISO 4217 code, see here for details: https://en.wikipedia.org/wiki/ISO_4217
 * @param track2Data The masked track 2 data
 * @param labelText The text to be displayed during PIN entry
 * @param completion The block to execute once the PIN entry is complete
 */
- (void)onlinePinWithAmount:(NSUInteger)amount
               currencyCode:(NSUInteger)currencyCode
                 track2Data:(nonnull NSString *)track2Data
                  labelText:(nonnull NSString *)labelText
                 completion:(void(^ _Nullable)(OnlinePinResponse * _Nullable response))completion;

/*!
 * @brief Delete file can be used to remove a file from PED.
 *
 * @discussion This can be used for a file deletion of a file
 *  from the temp folder.
 */
- (void)deleteFile:(nonnull NSString *)fileName completion:(nullable MPIBlocksSolicited)completion;

/*!
 * @brief List files is used to request a list of files.
 *
 * @discussion User can see a list of files in a folder on device
 *
 * @param completion The block will be excuted after list of file(s) / shown space available has been completed.
 * @param selectFolder set to false for storage and true for temp folder.
 */
- (void)listFilesWithCompletion:(BOOL)selectFolder completion:(void(^_Nullable)(NSMutableArray * _Nullable listOfFiles))completion;

/*!
 * @brief Downloads log from Miura device to iOS device.
 *
 * @discussion The transfer of the device will take some time, This will be dependant on the size of the log file in the device.
 * The completion block will be called when all the data has been transferred.
 * A NSData pointer is returned, this can then be used to write the data to a file for transfer to another system.
 * Note: All text data is sent using ASCII encoding.
 *
 * @param completion The block to execute after the downloading finishes
 */
- (void)downloadSystemLogWithCompletion:(void(^ _Nullable)(NSData * _Nullable fileData))completion;

/*!
 * @brief Download a file from the Miura device and store the file data in the supplied NSData object.
 *
 * @param fileName The name of the file to download from the device
 * @param completion The completion block which will be called when all the data is received.
 */
- (void)downloadBinaryWithFileName:(nonnull NSString *)fileName
                        completion:(void(^ _Nullable)(NSData * _Nullable fileData))completion;

/*!
 * @brief Delete the current log generated on the PED or POS device.
 *
 * @discussion This should be done at regular intervals. The recommendation is
 * before each transaction on a PED device and on each connection for POS devices.
 */
- (void)deleteLogWithCompletion:(void (^_Nullable)(BOOL success))completion;



- (void)resetDeviceWithResetType:(ResetDeviceType)resetType
                      completion:(nullable MPIBlocksSolicited)completion;

/*!
 * @brief Returns current date and time on connected Miura device.
 *
 * @discussion Note: Returned date uses iOS system Time Zone.
 *
 * @param completion This block will be called when the device responds. It will supply the current time on the device
 */
- (void)getSystemClockWithCompletion:(void(^ _Nullable)(NSDate * _Nullable date))completion;

/*!
 * @brief Updates device's date and time using the given date.
 *
 * @discussion Note: The date should be provided in iOS system Time Zone.
 *
 * @param date The date to be set on the Miura device
 * @param completion The block to execute
 */
- (void)setSystemClock:(nonnull NSDate *)date completion:(void(^ _Nullable)(BOOL success))completion;

/*!
 * @brief Uploads binary data and puts it into file on Miura device.
 *
 * @discussion This is used to send software updates and configuration data. It is also used during Key injection.
 *
 * @param binary The data to be sent to Miura device
 * @param fileName The name of the file to be created on the miura device
 * @param completion The block to execute after the streaming finishes
 */
- (void)uploadBinary:(nonnull NSData *)binary
             forName:(nonnull NSString *)fileName
          completion:(nullable MPIBlocksSolicited)completion;

/*!
 * @brief Returns the current status of the PED's encryption keys.
 *
 * @param completion The block to execute. It has only one parameter - the current P2PE status. See the relevant ENUM for details
 */
- (void)p2peStatusWithCompletion:(void(^ _Nullable)(P2PEStatus * _Nullable p2peStatus))completion;

/*!
 * @brief Instructs the PED to prepare the files required for a HSM to exchange keys.
 *
 * @discussion This process can take up to 2 minutes, but usually takes around 30 seconds.
 * Once the process is complete the files to be sent to the HSM can be retrieved from the device.
 *
 * @param completion The block to execute after the initialisation finishes
 */
- (void)p2peInitialiseWithCompletion:(BOOL)result
                          completion:(void(^_Nullable)(RkiInitStatus result))completion;

/*!
 * @brief Instruct the PED to inject the encryption keys.
 *
 * @param completion The block to execute after the import finishes
 */
- (void)p2peImportWithCompletion:(BOOL)sucess
                      completion:(void(^_Nullable)(RkiImportStatus result))completion;

/*!
 * @brief Returns information about software currently installed on Miura device.
 *
 * @param completion The block to execute. Its only parameter will contain the software info
 */
- (void)getSoftwareInfoWithCompletion:(void(^ _Nullable)(SoftwareInfo * _Nullable softwareInfo))completion;

/*!
 * @brief Call this to apply all pending software or configuration updates.
 *
 * @discussion This will cause the device to check any transferred files for updates.
 * If any are found they will be applied.
 * This may mean that the device will reboot and drop the connection
 *
 * @param completion The block to execute
 */
- (void)applyUpdateWithCompletion:(void(^ _Nullable)(BOOL success))completion;

/*!
 * @brief Use this to clear any partially transferred files from device memory before new files are uploaded.
 *
 * @discussion This will remove any previously transferred files from the device.
 * It should be used before starting a software or configuration update.
 *
 * @param completion the block to execute when the command is completed.
 */
- (void)clearDeviceMemory:(void(^_Nullable)(BOOL success))completion;

/*!
 * @brief Checks for presence of the supported peripherals.
 *
 * @discussion An entry in the response message will appear for
 * each supported peripheral which is currently connected/operational.
 *
 * @param completion The block after printing finished
 */
- (void)peripheralStatusCommand:(void(^_Nullable)(NSMutableArray * _Nullable peripheral))completion;

/*!
 * @brief Gets the name & address of device via USB/Bluetooth.
 *
 * @discussion This is used when USB lead is attacted to a POSzle device/over
 * bluetooth to get name & address(Mac) of the device, NSDictionary
 * values include: 'name' & address'.
 *
 * @param completion the block to execute after name&address is finished.
 */
- (void)getBluetoothInfo:(void(^ _Nonnull)(NSDictionary<NSString *, NSString *> * _Nullable blueInfo))completion;

/*!
 * @brief Allow entry of number from keypad
 *
 * @discussion This command allow the PED to return the entry of a number on its
 * keypad without compromising the security of the keypad
 *
 * @param autoEnt the bool is used to enable/disable maximum number of requested digits.
 * @param securePrompts this is used to display the secure content of 'acc-data-prompts.txt'
 * @param numericFormat used to display the number of pre decimal digits.
 * @param isBacklightOn set to true/false for keypad back light.
 * @param numericTimeout this is an optional timeout that can be used.
 */
- (void)getNumericData:(BOOL)autoEnt
         securePrompts:(NSData *_Nonnull)securePrompts
         numericFormat:(NSData *_Nonnull)numericFormat
        numericTimeout:(NSInteger)numericTimeout
         isBacklightOn:(BOOL) isBacklightOn
            completion:(void(^_Nonnull)(Numeric_Data_Result result, NSString *_Nullable selectedItem))completion;

/*!
 * @brief This allows numbers for tips to be shown on screen on PED
 *
 * @discussion In order to meet the security requirements for numeric entry on the PED a user can
 * only enter a non-PIN, numeric value if the contents of the display are under the
 * control of the MPI.
 *
 * @param amount the amount on screen is tip+total.
 * @param percentageValue list of percents to display. Percents are in range between 0 and 253.
 * @param templateTip line of tip-templates.cfg to use when displaying options this should be between 0 & 255.
 * @param currencyCode ISO 4217 currency code to be used when the amount is displayed.
 * @param currencyExponet ISO 4217 currency exponent used to format the amount.
 * @param authorisedNumeric The amount, in pennies, to dynamically generate tip from.
 * @param keyPadSetting used for LCD display or keypad backlight settings,
 * @param dynamicTimeout this is an optional timeout that can be used.
 * @param completion the block to execute when the users result is sent back.
 */
- (void)getDynamicTip:(BOOL)amount
      percentageValue:(NSData *_Nonnull)percentageValue
          templateTip:(NSData *_Nonnull)templateTip
         currencyCode:(NSData *_Nonnull)currencyCode
      currencyExponet:(NSData *_Nonnull)currencyExponet
    authorisedNumeric:(NSData *_Nonnull)authorisedNumeric
       dynamicTimeout:(NSInteger)dynamicTimeout
        keyPadSetting:(BacklightSettings)keyPadSetting
           completion:(void(^_Nonnull)(GetDynamicResult result, NSString *_Nullable selectedItem))completion;

/*!
 * @brief Allow secure capture of a Primary Account Number (PED) on the PED
 *
 * @discussion This command is used to allow a user to enter the PAN on the keypad of the PED.
 * The PAN is encrypted in the PED and the encrypted block and the key serial number are returned in the completion block.
 *
 * @param completion The block to complpete after checking of PAN.
 */
- (void)getSecurePan:(BOOL)isBacklightOn settings:(nonnull MPITLVObject *)settings completion:(nonnull MPIBlocksSolicited)completion;

/*!
 * @brief Allows the SRED encrpted entry of a PAN
 *
 * @discussion This is used to allow the PED to return the SRED encryption of a PAN, start date, expiry date
 * or/and CVV via its keypad without compromising the secure nature of the keypad when used as a PIN Entry Device.
 *
 * @param completion block to complete after checking of SRED encryption of a PAN.
 */

/*!
 * @brief Allows the clearing of secure data.
 *
 * @param completion block to execute when the command has been sent.
 */
- (void)clearSecureData:(MPIBlocksSolicited _Nonnull)completion;

/*!
 * @brief this allows the requesting of secure data.
 *
 * @param securePrompts this is used to display the secure content of 'acc-data-prompts.txt'
 * @param requestElement setting to true enables the requesting of secure data from storage.
 * @param keyPadSetting set to enable check for keyboard back light.
 * @param secureTimeout this is an optional timeout that can be used.
 */

- (void) requestSecureCardData:(NSData *_Nonnull)securePrompts
                requestElement:(NSData *_Nonnull)requestElement
                 secureTimeout:(NSInteger)secureTimeout
                 keyPadSetting:(BacklightSettings)keyPadSetting
                    completion:(void(^_Nonnull)(SecureDataResult result, NSString *_Nullable selectedItem))completion;

/*!
 * @brief this allows the retrieve of secure data.
 *
 * @param completion the block to execute when the command is completed.
 */
- (void)retrieveSecureData:(MPIBlocksSolicited _Nonnull)completion;

- (void)getEmvHashValuesWithCompletion:(nonnull MPIBlocksSolicited)completion;

/*!
 * @brief This gets the kernel & version for a given EMV Kernel name and hash value.
 *
 * @discussion This is used to retrieve the name of kernel and the version which then
 * compares to a NSMutableDictionary, which holdes the kernames and values for versioning.
 * values include: 'kernelName' & hashValues'.
 *
 * @param completion the block to execute after kernel&version have been retreived.
 */
- (void)getContactlessHashValuesWithCompletion:(void(^ _Nonnull )(NSDictionary <NSString*, NSString*> *_Nullable kernelVersions))completion;

/*!
 * @brief Print a UIImage object to the printer
 *
 * @discussion Takes a UIImage object and prints it to the connected printer.
 * The completion is called when the print is complete or if some error occurs.
 * For a list of errors see PrinterErrorCode enum.
 *
 * @param image The UIImage object to print
 * @param completion The completion block to execute when task is done.
 */
- (void)printUIImage:(UIImage * _Nonnull) image
          completion:(void(^ _Nullable)(PrinterSpoolControlError result))completion;

/*!
 *
 *
 */
- (void)getTouchScreenStatus:(nonnull MPIBlocksSolicited)completion;

/*!
 *
 *
 */

- (void)getTouchScreenEnd:(nonnull MPIBlocksSolicited)completion;

/*!
 *
 *
 */

- (void)getTouchScreenClear:(nonnull MPIBlocksSolicited)completion;

/*!
 *
 *
 */

- (void)getTouchScreenCalibrate:(nonnull MPIBlocksSolicited)completion;

/*!
 *
 *
 */

- (void)getTouchScreenBegin:(nonnull MPIBlocksSolicited)completion;

/*!
 * This can be used to save any of the current drawable areas to an
 * image for it to be then retrieved later.
 */
- (void)getTouchScreenExport:(nonnull NSString *)fileName completion:(nonnull MPIBlocksSolicited) completion;

/*!
 * @brief Show a scrollable menu of choices to user and return the chosen item.
 *
 * @discussion Takes an array of strings and some display options. Displays the
 * list on the screen of the Miura device. The user can scroll through the
 * options and select the desired choice. The selected option is then sent
 * returned in the completion block. The completion block also has a success
 * parameter, this is used to indicate an error, timeout or user cancelled.
 *
 * @param menuTitle The title string to display across the top of the Menu
 * @param showStatusBar Bool, set to true to see the battery and comms icons on
 * the top line of the display
 * @param enlargeHeader Set this to true if make the title bar bigger
 * @param enlargeFooter Set this to true to make the footer bar bigger
 * @param menuItems Array of strings containing the various menu items. Max is
 * 200.
 * @param completion The completion which is triggered when the user has
 * selected an option or the process has timed out.
 *
 */
- (void) getMenuOption: (nonnull NSString *) menuTitle
         showStatusBar: (BOOL) showStatusBar
         enlargeHeader: (BOOL) enlargeHeader
         enlargeFooter: (BOOL) enlargeFooter
             menuItems: (nonnull NSArray *) menuItems
            completion: (void(^_Nonnull)(GetMenuResult result, NSString * _Nullable selectedItem))completion;

/*!
 * @brief Displays combination of Text and Images in the Miura PED display.
 *
 * @param completion is excuted if text and images to display are successful.
 */
- (void) displayMediaCommand:(void(^_Nonnull)(BOOL success))completion;
/*!
 * @brief Buzzer on the connected device
 *
 * @discussion Takes the parameters for the sound and sends the command to the connected device to Buzz.
 * If the connected device doesn't have a Buzzer then completion parameter will be false.
 * If the parameters are out of range then this completion parameter will be false.
 * If buzz was successful the completion parameter will be true.
 *
 * @param synchronousSound The ped will only return when buzzer sound has finished if set to true,
 *        if set to false the ped will produce the sound and return immediatley.
 * @param duration The duration for the buzz in milliseconds. between 1 and 5000.
 * @param volume The volume to use for the buzz. Between 1 and 100.
 * @param frequency The frequency or tone of the buzz. Between 1 and 5000 in Hz.
 * @param completion The block to execute when method is complete.
 */
- (void)buzzerSound:(BOOL)synchronousSound
           duration:(NSUInteger)duration
            volData:(NSUInteger)volume
           freqData:(NSUInteger)frequency
         completion:(void(^_Nullable)(BOOL success))completion;

/*!
 * @brief Function used to enable the USB STATUS event message
 *
 * @discussion This is used to start and stop the USB STATUS event messages.
 * Set the param to true to start the event messages and false to stop them.
 * By default these are off and the PED will set the default after a disconnect or reboot.
 * No return value, use the completion block for success failure.
 *
 * @param enable Set to true to enable sending the even messages,
 * set to false to stop sending the messages.
 *
 * @param completion The block to be executed when the response is received.
 * This will recieve the current status of the USB 0 is unplugged 1 is plugged in.
 */
- (void)enableUsbStatus:(BOOL)enable
             completion:(void(^_Nullable)(BOOL usbStatus))completion;

/*!
 * To retrieve exported .png image from PED.
 * 
 */
- (void)retreiveSignCaptureExport:(void(^_Nonnull)(NSData * _Nonnull pngData))completion;

#pragma mark - Not available

- (nullable instancetype)init UNAVAILABLE_ATTRIBUTE;
- (nullable instancetype)new UNAVAILABLE_ATTRIBUTE;

@end
