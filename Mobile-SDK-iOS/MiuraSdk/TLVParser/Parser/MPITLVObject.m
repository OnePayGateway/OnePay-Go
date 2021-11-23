#import "MPITLVObject.h"
#import "MPIBinaryUtil.h"
#import "MPITLVParser.h"
#import "DebugDefine.h"


@interface MPITLVObject () {
    NSString *_valueData;
    NSData *_valueRawData;
    BOOL _isRawData;
}
@property(nonatomic, strong, readwrite) MPITag *tag;
@property(nonatomic, assign, readwrite) NSUInteger tLength;
@property(nonatomic, assign, readwrite) NSUInteger lLength;
@property(nonatomic, assign, readwrite) NSUInteger vLength;
@end

@implementation MPITLVObject


#pragma mark - Property

- (NSUInteger)fullLength {
    
    return self.tLength + self.lLength + self.vLength;
}

- (NSString *)data {
    
    if ([self isRawData]) {
        return [MPIBinaryUtil hexStringWithBytes:self.rawData];
    } else {
        return [MPIBinaryUtil stringWithBytes:self.rawData];
    }
}

- (void)setRawData:(NSData *)rawData {
    
    _valueRawData = rawData;
    _isRawData = ([self isAvailableStringWithBytes:_valueRawData] == NO);
}

- (NSData *)rawData {
    return _valueRawData;
}


#pragma mark - Init

+ (instancetype)tlvObjectWithTag:(MPITag *)tag
                         tLength:(NSUInteger)tLength
                         lLength:(NSUInteger)lLength
                         vLength:(NSUInteger)vLength {
    
    return [[MPITLVObject alloc] initWithTag:tag
                                     tLength:tLength
                                     lLength:lLength
                                     vLength:vLength];
}

- (instancetype)initWithTag:(MPITag *)tag
                    tLength:(NSUInteger)tLength
                    lLength:(NSUInteger)lLength
                    vLength:(NSUInteger)vLength {
    
    self = [super init];
    if (self) {
        _tag = tag;
        _tLength = tLength;
        _lLength = lLength;
        _vLength = vLength;
    }
    return self;
}

- (instancetype)initWithTag:(TLVTag)tag
                      value:(NSData *)value {
    
    self = [super init];
    if (self) {
        _tag = [MPITag tagWithTag:tag];
        self.rawData = value;
        if ([self isConstructed]) {
            self.constructedTLVObject = [MPITLVParser decodeWithBytes:self.rawData];
            [self initTLVLengthWithTag:tag vLength:[self constructedTLVLength]];
        }
        else {
            [self initTLVLengthWithTag:tag vLength:value.length];
        }
    }
    return self;
}

- (instancetype)initWithTag:(TLVTag)tag
                  byteValue:(Byte)byteValue {
    
    self = [super init];
    if (self) {
        _tag = [MPITag tagWithTag:tag];
        self.rawData = [NSData dataWithBytes:&byteValue length:1];
        [self initTLVLengthWithTag:tag vLength:1];
    }
    return self;
}

- (instancetype)initWithTag:(TLVTag)tag
                  construct:(NSArray *)construct {
    
    self = [super init];
    if (self) {
        _tag = [MPITag tagWithTag:tag];
        self.constructedTLVObject = construct;
        NSMutableData *rawData = [NSMutableData data];
        [self.constructedTLVObject enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            if ([obj isKindOfClass:[MPITLVObject class]] == NO) {
                return;
            }
            [rawData appendData:((MPITLVObject *)obj).rawData];
        }];
        self.rawData = rawData;
        [self initTLVLengthWithTag:tag vLength:[self constructedTLVLength]];
    }
    return self;
}

- (void)initTLVLengthWithTag:(TLVTag)tlvTag
                     vLength:(NSUInteger)vLength {
    
    NSUInteger tag = tlvTag;
    NSUInteger tLength = 0;
    //    NSUInteger lLength = 0;
    
    do {
        tLength ++;
        tag = (tag >> 8);
    } while (tag != 0);
    
    //    Byte lenByte = 0x00;
    //    NSUInteger lenBytes = floor(vLength / 128);
    //    if (lenBytes > 0) {
    //        lenByte = 0x80 + lenBytes;
    //        lLength ++;
    //        for (NSInteger i = lenBytes; i > 0; i--) {
    //            lenByte = vLength >> (8 * (i - 1)) & 0xFF;
    //            lLength ++;
    //        }
    //    } else {
    //        lLength ++;
    //    }
    
    _tLength = tLength;
    _lLength = MAX(1, (NSUInteger)floor(vLength / 128));
    _vLength = vLength;
}


#pragma mark - Event

- (void)dealloc {
    _tag = nil;
    _constructedTLVObject = nil;
    _valueData = nil;
    _valueRawData = nil;
}


#pragma mark - Public

- (NSString *)description {
    return [self descriptionWithLevel:0];
}

- (NSString *)descriptionWithLevel:(NSUInteger)level {
    NSMutableString *result = [NSMutableString string];
    
    for (NSUInteger i = 0; i < level; i++) {
        [result appendString:@"  "];
    }
    
    [result appendString:[MPIBinaryUtil hexStringWithInt:[self.tag.tagDescription tagID]]];
    [result appendFormat:@" (%@)", [self tagNameWithTag:self.tag.tagDescription.tag]];
    
    if ([self isConstructed]) {
        [result appendString:@":\n"];
        
        [self.constructedTLVObject enumerateObjectsUsingBlock:^(MPITLVObject *tlv, NSUInteger idx, BOOL *stop) {
            [result appendString:[tlv descriptionWithLevel:level+1]];
        }];
        
    } else {
        [result appendString:@" = "];
        [result appendString:[MPIBinaryUtil hexStringWithBytes:self.rawData]];
        if ([self isAvailableStringWithBytes:self.rawData]) {
            [result appendFormat:@" (%@)", self.data];
        }
        [result appendString:@"\n"];
    }

    return [result copy];
}

- (BOOL)isConstructed {
    TLVTag tagTop = [self.tag.tagDescription tagID];
    while (tagTop > 255) {
        tagTop = (tagTop >> 8);
    }
    switch (tagTop) {
        case 0x63: {
            return NO;
            break;
        }
        case 0xFF: {
            return NO;
            break;
        }
        default: {
            return ((tagTop & 0x20) == 0x20);
            break;
        }
    }
}

- (NSUInteger)constructedTLVLength {
    __block NSUInteger len = 0;
    
    [self.constructedTLVObject enumerateObjectsUsingBlock:^(MPITLVObject *tlv, NSUInteger idx, BOOL *stop) {
        if ([tlv isConstructed]) {
            len += self.tLength + self.lLength + [tlv constructedTLVLength];
        }
        else {
            len += tlv.fullLength;
        }
    }];
    return len;
}

- (BOOL)isRawData {
    return _isRawData;
}

- (NSString *)outline {
    return [self outlineWithLevel:0];
}

- (NSString *)outlineWithLevel:(NSUInteger)level {
    NSMutableString *ms = [[NSMutableString alloc] init];
    
    if ([self isConstructed]) {
        for (NSInteger i = 0; i < level; i++) {
            [ms appendString:@"  "];
        }
        [ms appendFormat:@" [%@] ", [self tagNameWithTag:self.tag.tagDescription.tag]];
        [ms appendFormat:@"tLength(%tu),", self.tLength];
        [ms appendFormat:@"tagID(%@),", [MPIBinaryUtil hexStringWithInt:[self.tag.tagDescription tagID]]];
        [ms appendFormat:@"vLength(%tu):\n", self.vLength];
        
        [self.constructedTLVObject enumerateObjectsUsingBlock:^(MPITLVObject *tlv, NSUInteger idx, BOOL *stop) {
            if ([tlv isConstructed]) {
                [ms appendFormat:@"%@", [tlv outlineWithLevel:level + 1]];
            } else {
                for (NSInteger i = 0; i <= level; i++) {
                    [ms appendString:@"  "];
                }
                [ms appendFormat:@" [%@] ", [self tagNameWithTag:tlv.tag.tagDescription.tag]];
                [ms appendFormat:@"tLength(%tu),", tlv.tLength];
                [ms appendFormat:@"tagID(%@),", [MPIBinaryUtil hexStringWithInt:[tlv.tag.tagDescription tagID]]];
                [ms appendFormat:@"vLength(%tu),", tlv.vLength];
                [ms appendFormat:@"data[%@]", [MPIBinaryUtil hexStringWithBytes:tlv.rawData]];
                if ([self isAvailableStringWithBytes:tlv.rawData]) {
                    [ms appendFormat:@",text[%@]", tlv.data];
                }
                [ms appendString:@"\n"];
            }
        }];
    } else {
        [ms appendFormat:@" [%@] ", [self tagNameWithTag:self.tag.tagDescription.tag]];
        [ms appendFormat:@"tLength(%tu),", self.tLength];
        [ms appendFormat:@"tagID(%@),", [MPIBinaryUtil hexStringWithInt:[self.tag.tagDescription tagID]]];
        [ms appendFormat:@"vLength(%tu),", self.vLength];
        [ms appendFormat:@"data[%@]", [MPIBinaryUtil hexStringWithBytes:self.rawData]];
        if ([self isAvailableStringWithBytes:self.rawData]) {
            [ms appendFormat:@",text[%@]", self.data];
        }
        [ms appendString:@"\n"];
    }
    
    return [ms copy];
}

- (BOOL)isAvailableStringWithBytes:(NSData *)bytes {
    return [self isAvailableStringWithString:[MPIBinaryUtil stringWithBytes:bytes]];
}

- (BOOL)isAvailableStringWithString:(NSString *)string {
    if (string == nil) return NO;
    if (string.length == 0) return YES;
    return [MPIBinaryUtil matchInString:string
                                  regex:@"^[a-zA-Z0-9\\s!\"#\\$%&'\\(\\)\\*+,-\\.\\/:;<=>\\?@\\[\\\\\\]\\^_`\\{｜\\}~]*$"];
}

- (NSString *)tagNameWithTag:(TLVTag)tag {
    switch (tag) {
        case TLVTag_Pin_Digit_Status: return @"Pin_Digit_Status";
        case TLVTag_Pin_ENtry_Status: return @"Pin_ENtry_Status";
        case TLVTag_Message_Authentication_Code: return @"Message_Authentication_Code";
        case TLVTag_MAC_Result: return @"MAC_Result";
        case TLVTag_ICC_Answer_To_Reset: return @"ICC_Answer_To_Reset";
        case TLVTag_Date: return @"Date";
        case TLVTag_Time: return @"Time";
        case TLVTag_File_Size: return @"File_Size";
        case TLVTag_Battery_Percentage: return @"Battery_Percentage";
        case TLVTag_Transaction_Sequence_Counter: return @"Transaction_Sequence_Counter";
        case TLVTag_Issuer_Script_Template_1_71: return @"Issuer_Script_Template_1_71";
        case TLVTag_Issuer_Script_Template_1_72: return @"Issuer_Script_Template_1_72";
        case TLVTag_Issuer_Authentication_Data: return @"Issuer_Authentication_Data";
        case TLVTag_Card_Status: return @"Card_Status";
        case TLVTag_AID: return @"AID";
        case TLVTag_Application_Label: return @"Application_Label";
        case TLVTag_Track_2_Equivalent_Data: return @"Track_2_Equivalent_Data";
        case TLVTag_Application_Primary_Account_Number_PAN: return @"Application_Primary_Account_Number_PAN";
        case TLVTag_Cardholder_Name: return @"Cardholder_Name";
        case TLVTag_Language_Preference: return @"Language_Preference";
        case TLVTag_Application_Expiration_Date: return @"Application_Expiration_Date";
        case TLVTag_Application_Effective_Date: return @"Application_Effective_Date";
        case TLVTag_Issuer_Country_Code: return @"Issuer_Country_Code";
        case TLVTag_Transaction_Currency_Code: return @"Transaction_Currency_Code";
        case TLVTag_Service_Code: return @"Service_Code";
        case TLVTag_Application_Primary_Account_Number_PAN_Sequence_Number: return @"Application_Primary_Account_Number_PAN_Sequence_Number";
        case TLVTag_Transaction_Currency_Exponent: return @"Transaction_Currency_Exponent";
        case TLVTag_Application_Template: return @"Application_Template";
        case TLVTag_FCI_Template: return @"FCI_Template";
        case TLVTag_Read_Record_response: return @"Read_Record_response";
        case TLVTag_Response_Message_Template_Format_2: return @"Response_Message_Template_Format_2";
        case TLVTag_Amount_Authorised_Binary: return @"Amount_Authorised_Binary";
        case TLVTag_Application_Interchange_Profile: return @"Application_Interchange_Profile";
        case TLVTag_DF_Name: return @"DF_Name";
        case TLVTag_Issuer_Script_Command: return @"Issuer_Script_Command";
        case TLVTag_Application_Priority_Indicator: return @"Application_Priority_Indicator";
        case TLVTag_SFI: return @"SFI";
        case TLVTag_Authorisation_Response_Code: return @"Authorisation_Response_Code";
        case TLVTag_Card_Risk_Management_Data_Object_List_1_CDOL1: return @"Card_Risk_Management_Data_Object_List_1_CDOL1";
        case TLVTag_Card_Risk_Management_Data_Object_List_2_CDOL2: return @"Card_Risk_Management_Data_Object_List_2_CDOL2";
        case TLVTag_Cardholder_Verification_Method_CVM_List: return @"Cardholder_Verification_Method_CVM_List";
        case TLVTag_Certification_Authority_Public_Key_Index: return @"Certification_Authority_Public_Key_Index";
        case TLVTag_Issuer_Public_Key_Certificate: return @"Issuer_Public_Key_Certificate";
        case TLVTag_Issuer_Public_Key_Remainder: return @"Issuer_Public_Key_Remainder";
        case TLVTag_Signed_Static_Application_Data: return @"Signed_Static_Application_Data";
        case TLVTag_Application_File_Locator_AFL: return @"Application_File_Locator_AFL";
        case TLVTag_Terminal_Verification_Results: return @"Terminal_Verification_Results";
        case TLVTag_Transaction_Certificate_Data_Object_List_TDOL: return @"Transaction_Certificate_Data_Object_List_TDOL";
        case TLVTag_Transaction_Status_Information: return @"Transaction_Status_Information";
        case TLVTag_Transaction_Type: return @"Transaction_Type";
        case TLVTag_Transaction_Information_Status_sale: return @"Transaction_Information_Status_sale";
        case TLVTag_Transaction_Information_Status_cash: return @"Transaction_Information_Status_cash";
        case TLVTag_Transaction_Information_Status_cashback: return @"Transaction_Information_Status_cashback";
        case TVLTag_EmvHashValues_File_Not_Found: return @"EmvHashValues_File_Not_Found";
        case TLVTag_Acquirer_Identifier: return @"Acquirer_Identifier";
        case TLVTag_Amount_Authorised_Numeric: return @"Amount_Authorised_Numeric";
        case TLVTag_Amount_Other_Numeric: return @"Amount_Other_Numeric";
        case TLVTag_Amount_Other_Binary: return @"Amount_Other_Binary";
        case TLVTag_Application_Discretionary_Data: return @"Application_Discretionary_Data";
        case TLVTag_Application_Identifier_AID_terminal: return @"Application_Identifier_AID_terminal";
        case TLVTag_Application_Usage_Control: return @"Application_Usage_Control";
        case TLVTag_ICC_Application_Version_Number: return @"ICC_Application_Version_Number";
        case TLVTag_Term_Application_Version_Number: return @"Term_Application_Version_Number";
        case TLVTag_Cardholder_Name_Extended: return @"Cardholder_Name_Extended";
        case TLVTag_Issuer_Action_Code_Default: return @"Issuer_Action_Code_Default";
        case TLVTag_Issuer_Action_Code_Denial: return @"Issuer_Action_Code_Denial";
        case TLVTag_Issuer_Action_Code_Online: return @"Issuer_Action_Code_Online";
        case TLVTag_Issuer_Application_Data: return @"Issuer_Application_Data";
        case TLVTag_Issuer_Code_Table_Index: return @"Issuer_Code_Table_Index";
        case TLVTag_Application_Preferred_Name: return @"Application_Preferred_Name";
        case TLVTag_Last_Online_Application_Transaction_Counter_ATC_Register: return @"Last_Online_Application_Transaction_Counter_ATC_Register";
        case TLVTag_Lower_Consecutive_Offline_Limit: return @"Lower_Consecutive_Offline_Limit";
        case TLVTag_Personal_Identification_Number_PIN_Try_Counter: return @"Personal_Identification_Number_PIN_Try_Counter";
        case TLVTag_Terminal_Country_Code: return @"Terminal_Country_Code";
        case TLVTag_Terminal_Floor_Limit: return @"Terminal_Floor_Limit";
        case TLVTag_Terminal_ID: return @"Terminal_ID";
        case TLVTag_Interface_Device_Serial_Number: return @"Interface_Device_Serial_Number";
        case TLVTag_Track_1_Discretionary_Data: return @"Track_1_Discretionary_Data";
        case TLVTag_Track_2_Discretionary_Data: return @"Track_2_Discretionary_Data";
        case TLVTag_Upper_Consecutive_Offline_Limit: return @"Upper_Consecutive_Offline_Limit";
        case TLVTag_Application_Cryptogram: return @"Application_Cryptogram";
        case TLVTag_Cryptogram_Information_Data: return @"Cryptogram_Information_Data";
        case TLVTag_ICC_PIN_Encipherment_Public_Key_Certificate: return @"ICC_PIN_Encipherment_Public_Key_Certificate";
        case TLVTag_ICC_PIN_Encipherment_Public_Key_Exponent: return @"ICC_PIN_Encipherment_Public_Key_Exponent";
        case TLVTag_ICC_PIN_Encipherment_Public_Key_Remainder: return @"ICC_PIN_Encipherment_Public_Key_Remainder";
        case TLVTag_Issuer_Public_Key_Exponent: return @"Issuer_Public_Key_Exponent";
        case TLVTag_Terminal_Capabilities: return @"Terminal_Capabilities";
        case TLVTag_Cardholder_Verification_Method_CVM_Results: return @"Cardholder_Verification_Method_CVM_Results";
        case TLVTag_Terminal_Type: return @"Terminal_Type";
        case TLVTag_Application_Transaction_Counter_ATC: return @"Application_Transaction_Counter_ATC";
        case TLVTag_Unpredictable_Number: return @"Unpredictable_Number";
        case TLVTag_Processing_Options_Data_Object_List_PDOL: return @"Processing_Options_Data_Object_List_PDOL";
        case TLVTag_Application_Reference_Currency: return @"Application_Reference_Currency";
        case TLVTag_Terminal_Capabilities_Add: return @"Terminal_Capabilities_Add";
        case TLVTag_Application_Currency_Code: return @"Application_Currency_Code";
        case TLVTag_Application_Reference_Currency_Exponent: return @"Application_Reference_Currency_Exponent";
        case TLVTag_Application_Currency_Exponent: return @"Application_Currency_Exponent";
        case TLVTag_ICC_Public_Key_Certificate: return @"ICC_Public_Key_Certificate";
        case TLVTag_ICC_Public_Key_Exponent: return @"ICC_Public_Key_Exponent";
        case TLVTag_ICC_Public_Key_Remainder: return @"ICC_Public_Key_Remainder";
        case TLVTag_Dynamic_Data_Authentication_Data_Object_List_DDOL: return @"Dynamic_Data_Authentication_Data_Object_List_DDOL";
        case TLVTag_Static_Data_Authentication_Tag_List: return @"Static_Data_Authentication_Tag_List";
        case TLVTag_Signed_Dynamic_Application_Data: return @"Signed_Dynamic_Application_Data";
        case TLVTag_ICC_Dynamic_Number: return @"ICC_Dynamic_Number";
        case TLVTag_Issuer_Script_Results: return @"Issuer_Script_Results";
        case TLVTag_FCI_Proprietary_Template: return @"FCI_Proprietary_Template";
        case TLVTag_File_Control_Information_FCI_Issuer_Discretionary_Data: return @"File_Control_Information_FCI_Issuer_Discretionary_Data";
        case TLVTag_Decision: return @"Decision";
        case TLVTag_Acquirer_Index: return @"Acquirer_Index";
        case TLVTag_Status_Code: return @"Status_Code";
        case TLVTag_Status_Text: return @"Status_Text";
        case TLVTag_PIN_Retry_Counter: return @"PIN_Retry_Counter";
        case TLVTag_Identifier: return @"Identifier";
        case TLVTag_Cardholder_Verification_Status: return @"Cardholder_Verification_Status";
        case TLVTag_Version: return @"Version";
        case TLVTag_Command_Data: return @"Command_Data";
        case TLVTag_Response_Data: return @"Response_Data";
        case TLVTag_Decision_Required: return @"Decision_Required";
        case TLVTag_Transaction_Approved: return @"Transaction_Approved";
        case TLVTag_Online_Authorisation_Required: return @"Online_Authorisation_Required";
        case TLVTag_Transaction_Declined: return @"Transaction_Declined";
        case TLVTag_Terminal_Status_Changed: return @"Terminal_Status_Changed";
        case TLVTag_Configuration_Information: return @"Configuration_Information";
        case TLVTag_Software_Information: return @"Software_Information";
        case TLVTag_Terminal_Action_Code_DEFAULT: return @"Terminal_Action_Code_DEFAULT";
        case TLVTag_Terminal_Action_Code_OFFLINE: return @"Terminal_Action_Code_OFFLINE";
        case TLVTag_Terminal_Action_Code_ONLINE: return @"Terminal_Action_Code_ONLINE";
        case TLVTag_PIN_Digit_Status: return @"PIN_Digit_Status";
        case TLVTag_PIN_Entry_Status: return @"PIN_Entry_Status";
        case TLVTag_Configure_TRM_Stage: return @"Configure_TRM_Stage";
        case TLVTag_Configure_Application_Selection: return @"Configure_Application_Selection";
        case TLVTag_Keyboard_Data: return @"Keyboard_Data";
        case TLVTag_Secure_Prompt: return @"Secure_Prompt";
        case TLVTag_Number_Format: return @"Number_Format";
        case TLVTag_Numeric_Data: return @"Numeric_Data";
        case TLVTag_Charging_Status: return @"Charging_Status";
        case TLVTag_Stream_Offset: return @"Stream_Offset";
        case TLVTag_Stream_Size: return @"Stream_Size";
        case TLVTag_Stream_timeout: return @"Stream_timeout";
        case TLVTag_File_md5sum: return @"File_md5sum";
        case TLVTag_File_Space : return @"File_space";
        case TLVTag_File_Used : return @"File_used";
        case TLVTag_Bar_Code_Data: return @"Barcode_scan";
        case TLVTag_Usb_Status: return @"USB_Status";
        case TLVTag_P2PE_Status: return @"P2PE_Status";
        case TLVTag_SRED_Data: return @"SRED_Data";
        case TLVTag_SRED_KSN: return @"SRED_KSN";
        case TLVTag_Online_PIN_Data: return @"Online_PIN_Data";
        case TLVTag_Online_PIN_KSN: return @"Online_PIN_KSN";
        case TLVTag_Masked_Track_2: return @"Masked_Track_2";
        case TLVTag_ICC_Masked_Track_2: return @"ICC_Masked_Track_2";
        case TLVTag_Masked_PAN: return @"Masked_PAN";
        case TLVTag_Screen_Position: return @"Screen_Position";
        case TLVTag_Screen_Text_String: return @"Screen_Text_String";
        case TLVTag_Bitmap_Name: return @"Bitmap_Name";
        case TLVTag_Blink_Time_Normal: return @"Blink_Time_Normal";
        case TLVTag_Blink_Time_Inverted: return @"Blink_Time_Inverted";
        case TLVTag_Blick_Time_Period: return @"Blick_Time_Period";
        case TLVTag_Blink_Area: return @"Blink_Area";
        case TLVTag_Transaction_Info_Status_bits: return @"Transaction_Info_Status_bits";
        case TLVTag_Revoked_certificates_list: return @"Revoked_certificates_list";
        case TLVTag_Online_DOL: return @"Online_DOL";
        case TLVTag_Referral_DOL: return @"Referral_DOL";
        case TLVTag_ARPC_DOL: return @"ARPC_DOL";
        case TLVTag_Reversal_DOL: return @"Reversal_DOL";
        case TLVTag_AuthResponse_DO: return @"AuthResponse_DO";
        case TLVTag_PSE_Directory: return @"PSE_Directory";
        case TLVTag_Threshold_Value_for_Biased_Random_Selection: return @"Threshold_Value_for_Biased_Random_Selection";
        case TLVTag_Target_Percentage_for_Biased_Random_Selection: return @"Target_Percentage_for_Biased_Random_Selection";
        case TLVTag_Maximum_Target_Percentage_for_Biased_Random_Selection: return @"Maximum_Target_Percentage_for_Biased_Random_Selection";
        case TLVTag_Default_CVM: return @"Default_CVM";
        case TLVTag_Dynamic_tip_percentage : return @"Dynamic_tip_percentage";
        case TLVTag_Dynamic_tip_template : return @"Dynamic_tip_templeate";
        case TLVTag_Issuer_script_size_limit: return @"Issuer_script_size_limit";
        case TLVTag_Log_DOL: return @"Log_DOL";
        case TLVTag_Partial_AID_Selection_Allowed: return @"Partial_AID_Selection_Allowed";
        case TLVTag_Transaction_Category_Code: return @"Transaction_Category_Code";
        case TLVTag_Balance_Before_Generate_AC: return @"Balance_Before_Generate_AC";
        case TLVTag_Balance_After_Generate_AC: return @"Balance_After_Generate_AC";
        case TLVTag_Encrypted_Data: return @"Encrypted_Data";
        case TLVTag_Printer_Status : return @"Printer_Status";
        case TLVTag_Contactless_Kernel_And_Mode : return @"Contactless_Kernel_And_Mode";
        case TLVTag_Form_Factor_Indicator : return @"Form_Factor_Indicator";
        case TLVTag_Terminal_Transaction_Qualifier : return @"Terminal_Transaction_Qualifier";
        case TLVTag_POS_Entry_Mode : return @"POS_Entry_Mode";
        case TLVTag_Mobile_Support_Indicator : return @"Mobile_Support_Indicator";
        case TVLTag_Terminal_Language_Preference : return @"Terminal_Language_Preference";
        case TLVTag_Payment_Cancel_Or_PIN_Entry_Timeout : return @"User pressed cancel or Pin entry timed out";
        case TLVTag_Payment_Internal_1 : return @"Internal Error Codes, contact MPI support with an MPI log file.";
        case TLVTag_Payment_Internal_2 : return @"Internal Error Codes, contact MPI support with an MPI log file.";
        case TLVTag_Payment_Internal_3 : return @"Internal Error Codes, contact MPI support with an MPI log file.";
        case TLVTag_Payment_User_Bypassed_PIN : return @"User bypassed PIN Entry";
        case TLVTag_Menu_Title : return @"Menu_Title";
        case TLVTag_Menu_Option : return @"Menu_Option";
        case TLVTag_Menu_Timeout : return @"Menu_Timeout";
        case TLVTag_Sound_Duration: return @"Sound_Duration";
        case TLVTag_Sound_Volume : return @"Sound_Volume";
        case TLVTag_Sound_Frequency : return @"Sound_Frequency";
        default: return @"UNKNOWN";
    }
}

@end
