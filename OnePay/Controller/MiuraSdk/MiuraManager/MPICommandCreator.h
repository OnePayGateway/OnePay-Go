#import <Foundation/Foundation.h>


#pragma mark - Const/Enum/Struct

/// MPI command type.
typedef NS_ENUM (NSUInteger, MPICommandType) {
    MPICommandType_Reset_Device = 0xD0000000,
    MPICommandType_Get_Configuration = 0xD0010000,
    MPICommandType_Get_Device_Info = 0xD0020000,
    MPICommandType_Select_File = 0x00A40000,
    MPICommandType_Delete_File = 0x00A50000,
    MPICommandType_List_Files = 0x00A60000,
    MPICommandType_Read_Binary = 0x00B00000,
    MPICommandType_Update_Binary = 0x00D60000,
    MPICommandType_Stream_Binary = 0x00D70000,
    MPICommandType_Card_Status = 0xD0600000,
    MPICommandType_Keyboard_Status = 0xD0610000,
    MPICommandType_Battery_Status = 0xD0620000,
    MPICommandType_Bluetooth_Control = 0xD0BC0000,
    
    MPICommandType_BarcodeScan_Status = 0xD0D10000,
    MPICommandType_CashDrawerOpen = 0xD0D00000,
    MPICommandType_Printer_Spool = 0xD2A30000,
    MPICommandType_ESC_POS = 0xD2A40000,
    
    MPICommandType_Print_status = 0xD0630000,
    MPICommandType_Usb_Status = 0xD0650000,
    MPICommandType_Peripheral_Status = 0xD0A00000,
    MPICommandType_Get_Dynamic_Tip = 0xD2050000,
    MPICommandType_Get_Menu_Option = 0xD2060000,
    
    MPICommandType_Touch_Capture_Status = 0xDB000000,
    MPICommandType_Touch_Capture_Begin = 0xDB010000,
    MPICommandType_Touch_Capture_End = 0xDB020000,
    MPICommandType_Touch_Capture_Clear = 0xDB030000,
    MPICommandType_Touch_Capture_Export = 0xDB040000,
    MPICommandType_Touch_Capture_Calibrate = 0xDBF00000,
    
    MPICommandType_Display_Text = 0xD2010000,
    MPICommandType_Display_Image = 0xD2D20000,
    MPICommandType_Display_Media = 0xD2200000,
    MPICommandType_Configure_Image = 0xD2B00000,
    MPICommandType_Get_Numeric_Data = 0xD2040000,
    MPICommandType_Get_Secure_PAN = 0xD25A0000,
    MPICommandType_Get_Secure_DATA = 0xD2E00000,
    MPICommandType_Get_Next_Transaction_Sequence_Counter = 0xDE020000,
    MPICommandType_Get_EMV_Hash_Values = 0xDE010000,
    MPICommandType_Get_Contactless_Hash_Values = 0xDEC20000,
    MPICommandType_Start_Transaction = 0xDED10000,
    MPICommandType_Continue_Transaction = 0xDED20000,
    MPICommandType_Start_Contactless_Transaction = 0xDEC10000,
    MPICommandType_Abort = 0xD0FF0000,
    MPICommandType_Online_PIN = 0xDED60100,
    MPICommandType_System_Clock = 0xD0100000,
    MPICommandType_USB_Serial_Disconnect = 0xD0C00000,
    
    MPICommandType_P2PE_Status = 0xEEE00000,
    MPICommandType_P2PE_Initialise = 0xEEE10000,
    MPICommandType_P2PE_Import = 0xEEE20000,
    MPICommandType_P2PE_Get_Encrypted_Data = 0xEEE30000,
    MPICommandType_P2PE_Get_KSN_For_MAC = 0xEEE50000,
    MPICommandType_P2PE_Verify_MAC = 0xEEE40000,
    MPICommandType_P2PE_Get_MAC_Configuration_File = 0xEEE60000,
    
    MPICommandType_System_Log = 0xD0E10000,
    MPICommandType_Buzzer = 0xD2300000,
};


@interface MPICommandCreator: NSObject


#pragma mark - Shared

/// Create MPI command.
+ (NSData *)commandWithType:(MPICommandType)type;

/// Create MPI command.
+ (NSData *)commandWithType:(MPICommandType)type
                         p1:(Byte *)p1;

/// Create MPI command.
+ (NSData *)commandWithType:(MPICommandType)type
                         p1:(Byte *)p1 p2:(Byte *)p2;

/// Create MPI command.
+ (NSData *)commandWithType:(MPICommandType)type
                         p1:(Byte *)p1 p2:(Byte *)p2
                  dataField:(NSData *)dataField;

/// Create MPI command.
+ (NSData *)commandWithType:(MPICommandType)type
                         p1:(Byte *)p1 p2:(Byte *)p2
                  dataField:(NSData *)dataField
                         le:(Byte *)le;

/// Create MPI command.
+ (NSData *)commandWithCla:(Byte *)cla
                       ins:(Byte *)ins
                        p1:(Byte *)p1 p2:(Byte *)p2
                 dataField:(NSData *)dataField
                        le:(Byte *)le;


#pragma mark - Not available

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
- (instancetype)new UNAVAILABLE_ATTRIBUTE;

@end
