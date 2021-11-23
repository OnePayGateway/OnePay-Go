#import <Foundation/Foundation.h>

typedef NS_ENUM (NSUInteger, TLVTag) {
    TLVTag_UNKNOWN = 0xFFFFFFFF,
    TLVTag_Pin_Digit_Status = 0xDFA101,
    TLVTag_Pin_ENtry_Status = 0xDFA102,
    TLVTag_Message_Authentication_Code = 0xDFAE06,
    TLVTag_MAC_Result = 0xDFAE07,
    TLVTag_Touch_Screen_Area = 0xDFAF01,
    TLVTag_ICC_Answer_To_Reset = 0x63,
    TLVTag_Date = 0x9A,
    TLVTag_Time = 0x9F21,
    TLVTag_File_Size = 0x80,
    TLVTag_Battery_Percentage = 0xDFA20A,
    TLVTag_Transaction_Sequence_Counter = 0x9F41,
    TLVTag_Issuer_Script_Template_1_71 = 0x71,
    TLVTag_Issuer_Script_Template_1_72 = 0x72,
    TLVTag_Issuer_Authentication_Data = 0x91,
    TLVTag_Card_Status = 0x48,
    TLVTag_AID = 0x4F,
    TLVTag_Application_Label = 0x50,
    TLVTag_Track_2_Equivalent_Data = 0x57,
    TLVTag_Application_Primary_Account_Number_PAN = 0x5A,
    TLVTag_Cardholder_Name = 0x5F20,
    TLVTag_Language_Preference = 0x5F2D,
    TLVTag_Application_Expiration_Date = 0x5F24,
    TLVTag_Application_Effective_Date = 0x5F25,
    TLVTag_Issuer_Country_Code = 0x5F28,
    TLVTag_Transaction_Currency_Code = 0x5F2A,
    TLVTag_Service_Code = 0x5F30,
    TLVTag_Application_Primary_Account_Number_PAN_Sequence_Number = 0x5F34,
    TLVTag_Transaction_Currency_Exponent = 0x5F36,
    TLVTag_Application_Template = 0x61,
    TLVTag_FCI_Template = 0x6F,
    TLVTag_Read_Record_response = 0x70,
    TLVTag_Response_Message_Template_Format_2 = 0x77,
//    TLVTag_Response_Message_Template_Format_1 = 0x80,
    TLVTag_Amount_Authorised_Binary = 0x81,
    TLVTag_Application_Interchange_Profile = 0x82,
    TLVTag_DF_Name = 0x84,
    TLVTag_Issuer_Script_Command = 0x86,
    TLVTag_Application_Priority_Indicator = 0x87,
    TLVTag_SFI = 0x88,
    TLVTag_Authorisation_Response_Code = 0x8A,
    TLVTag_Card_Risk_Management_Data_Object_List_1_CDOL1 = 0x8C,
    TLVTag_Card_Risk_Management_Data_Object_List_2_CDOL2 = 0x8D,
    TLVTag_Cardholder_Verification_Method_CVM_List = 0x8E,
    TLVTag_Certification_Authority_Public_Key_Index = 0x8F,
    TLVTag_Issuer_Public_Key_Certificate = 0x90,
    TLVTag_Issuer_Public_Key_Remainder = 0x92,
    TLVTag_Signed_Static_Application_Data = 0x93,
    TLVTag_Application_File_Locator_AFL = 0x94,
    TLVTag_Terminal_Verification_Results = 0x95,
    TLVTag_Transaction_Certificate_Data_Object_List_TDOL = 0x97,
    TLVTag_Transaction_Status_Information = 0x9B,
    TLVTag_Transaction_Type = 0x9C,
    TLVTag_Transaction_Information_Status_sale = 0x9C00,
    TLVTag_Transaction_Information_Status_cash = 0x9C01,
    TLVTag_Transaction_Information_Status_cashback = 0x9C09,
    TVLTag_EmvHashValues_File_Not_Found = 0x9FE0,
    TLVTag_Acquirer_Identifier = 0x9F01,
    TLVTag_Amount_Authorised_Numeric = 0x9F02,
    TLVTag_Amount_Other_Numeric = 0x9F03,
    TLVTag_Amount_Other_Binary = 0x9F04,
    TLVTag_Application_Discretionary_Data = 0x9F05,
    TLVTag_Application_Identifier_AID_terminal = 0x9F06,
    TLVTag_Application_Usage_Control = 0x9F07,
    TLVTag_ICC_Application_Version_Number = 0x9F08,
    TLVTag_Term_Application_Version_Number = 0x9F09,
    TLVTag_Cardholder_Name_Extended = 0x9F0B,
    TLVTag_Issuer_Action_Code_Default = 0x9F0D,
    TLVTag_Issuer_Action_Code_Denial = 0x9F0E,
    TLVTag_Issuer_Action_Code_Online = 0x9F0F,
    TLVTag_Issuer_Application_Data = 0x9F10,
    TLVTag_Issuer_Code_Table_Index = 0x9F11,
    TLVTag_Application_Preferred_Name = 0x9F12,
    TLVTag_Last_Online_Application_Transaction_Counter_ATC_Register = 0x9F13,
    TLVTag_Lower_Consecutive_Offline_Limit = 0x9F14,
    TLVTag_Personal_Identification_Number_PIN_Try_Counter = 0x9F17,
    TLVTag_Issuer_Script_Identifier = 0x9F18,
    TLVTag_Terminal_Country_Code = 0x9F1A,
    TLVTag_Terminal_Floor_Limit = 0x9F1B,
    TLVTag_Terminal_ID = 0x9F1C,
    TLVTag_Interface_Device_Serial_Number = 0x9F1E,
    TLVTag_Track_1_Discretionary_Data = 0x9F1F,
    TLVTag_Track_2_Discretionary_Data = 0x9F20,
    TLVTag_Upper_Consecutive_Offline_Limit = 0x9F23,
    TLVTag_Application_Cryptogram = 0x9F26,
    TLVTag_Cryptogram_Information_Data = 0x9F27,
    TLVTag_ICC_PIN_Encipherment_Public_Key_Certificate = 0x9F2D,
    TLVTag_ICC_PIN_Encipherment_Public_Key_Exponent = 0x9F2E,
    TLVTag_ICC_PIN_Encipherment_Public_Key_Remainder = 0x9F2F,
    TLVTag_Issuer_Public_Key_Exponent = 0x9F32,
    TLVTag_Terminal_Capabilities = 0x9F33,
    TLVTag_Cardholder_Verification_Method_CVM_Results = 0x9F34,
    TLVTag_Terminal_Type = 0x9F35,
    TLVTag_Application_Transaction_Counter_ATC = 0x9F36,
    TLVTag_Unpredictable_Number = 0x9F37,
    TLVTag_Processing_Options_Data_Object_List_PDOL = 0x9F38,
    TLVTag_Application_Reference_Currency = 0x9F3B,
    TLVTag_Terminal_Capabilities_Add = 0x9F40,
    TLVTag_Application_Currency_Code = 0x9F42,
    TLVTag_Application_Reference_Currency_Exponent = 0x9F43,
    TLVTag_Application_Currency_Exponent = 0x9F44,
    TLVTag_ICC_Public_Key_Certificate = 0x9F46,
    TLVTag_ICC_Public_Key_Exponent = 0x9F47,
    TLVTag_ICC_Public_Key_Remainder = 0x9F48,
    TLVTag_Dynamic_Data_Authentication_Data_Object_List_DDOL = 0x9F49,
    TLVTag_Static_Data_Authentication_Tag_List = 0x9F4A,
    TLVTag_Signed_Dynamic_Application_Data = 0x9F4B,
    TLVTag_ICC_Dynamic_Number = 0x9F4C,
    TLVTag_Issuer_Script_Results = 0x9F5B,
    TLVTag_FCI_Proprietary_Template = 0xA5,
    TLVTag_File_Control_Information_FCI_Issuer_Discretionary_Data = 0xBF0C,
    TLVTag_Decision = 0xC0,
    TLVTag_Acquirer_Index = 0xC2,
    TLVTag_Status_Code = 0xC3,
    TLVTag_Status_Text = 0xC4,
    TLVTag_PIN_Retry_Counter = 0xC5,
    TLVTag_Identifier = 0xDF0D,
    TLVTag_Cardholder_Verification_Status = 0xDF28,
    TLVTag_Version = 0xDF7F,
    TLVTag_Command_Data = 0xE0,
    TLVTag_Response_Data = 0xE1,
    TLVTag_Decision_Required = 0xE2,
    TLVTag_Transaction_Approved = 0xE3,
    TLVTag_Online_Authorisation_Required = 0xE4,
    TLVTag_Transaction_Declined = 0xE5,
    TLVTag_Terminal_Status_Changed = 0xE6,
    TLVTag_Configuration_Information = 0xED,
    TLVTag_Software_Information = 0xEF,
    TLVTag_Terminal_Action_Code_DEFAULT = 0xFF0D,
    TLVTag_Terminal_Action_Code_OFFLINE = 0xFF0E,
    TLVTag_Terminal_Action_Code_ONLINE = 0xFF0F,
    TLVTag_PIN_Digit_Status = 0xDFA201,
    TLVTag_PIN_Entry_Status = 0xDFA202,
    TLVTag_Configure_TRM_Stage = 0xDFA203,
    TLVTag_Configure_Application_Selection = 0xDFA204,
    TLVTag_Keyboard_Data = 0xDFA205,
    TLVTag_Secure_Prompt = 0xDFA206,
    TLVTag_Number_Format = 0xDFA207,
    TLVTag_Numeric_Data = 0xDFA208,
    TLVTag_Charging_Status = 0xDFA209,
    TLVTag_Secure_element = 0xDFA210,
    TLVTag_PAN = 0xDFA211,
    TLVTag_Start_date_as_YYMM = 0xDFA212,
    TLVTag_Start_date_as_MMYY = 0xDFA213,
    TLVTag_Expiry_date_as_YYMM = 0xDFA214,
    TLVTag_Expiry_date_as_MMYY = 0xDFA215,
    TLVTag_CVV = 0xDFA216,
    TLVTAG_Timeout = 0xDFFF01,
    TLVTag_Dynamic_tip_percentage = 0xDFA217,
    TLVTag_Dynamic_tip_template = 0xDFA218,
    TLVTag_Stream_Offset = 0xDFA301,
    TLVTag_Stream_Size = 0xDFA302,
    TLVTag_Stream_timeout = 0xDFA303,
    TLVTag_File_md5sum = 0xDFA304,
    TLVTag_File_Space = 0xDFA305,
    TLVTag_File_Used = 0xDFA306,
    TLVTag_Bar_Code_Data = 0xDFAB01,
    TLVTag_Usb_Status = 0xDFAB03,
    TLVTag_P2PE_Status = 0xDFAE01,
    TLVTag_SRED_Data = 0xDFAE02,
    TLVTag_SRED_KSN = 0xDFAE03,
    TLVTag_Online_PIN_Data = 0xDFAE04,
    TLVTag_Online_PIN_KSN = 0xDFAE05,
    TLVTag_Masked_Track_2 = 0xDFAE22,
    TLVTag_ICC_Masked_Track_2 = 0xDFAE57,
    TLVTag_Masked_PAN = 0xDFAE5A,
    TLVTag_Screen_Position = 0xDFAC01,
    TLVTag_Screen_Text_String = 0xDFAC02,
    TLVTag_Bitmap_Name = 0xDFAC03,
    TLVTag_Blink_Time_Normal= 0xDFAC04,
    TLVTag_Blink_Time_Inverted = 0xDFAC05,
    TLVTag_Blick_Time_Period = 0xDFAC06,
    TLVTag_Blink_Area = 0xDFAC07,
    TLVTag_Transaction_Info_Status_bits = 0xDFDF00,
    TLVTag_Revoked_certificates_list = 0xDFDF01,
    TLVTag_Online_DOL = 0xDFDF02,
    TLVTag_Referral_DOL = 0xDFDF03,
    TLVTag_ARPC_DOL = 0xDFDF04,
    TLVTag_Reversal_DOL = 0xDFDF05,
    TLVTag_AuthResponse_DO = 0xDFDF06,
    TLVTag_PSE_Directory = 0xDFDF09,
    TLVTag_Threshold_Value_for_Biased_Random_Selection = 0xDFDF10,
    TLVTag_Target_Percentage_for_Biased_Random_Selection = 0xDFDF11,
    TLVTag_Maximum_Target_Percentage_for_Biased_Random_Selection = 0xDFDF12,
    TLVTag_Default_CVM = 0xDFDF13,
    TLVTag_Issuer_script_size_limit = 0xDFDF16,
    TLVTag_Log_DOL = 0xDFDF17,
    TLVTag_Partial_AID_Selection_Allowed = 0xE001,
    TLVTag_Transaction_Category_Code = 0x9F53,
    TLVTag_Balance_Before_Generate_AC = 0xDF8104,
    TLVTag_Balance_After_Generate_AC = 0xDF8105,
    TLVTag_Encrypted_Data = 0xEE,
    TLVTag_Printer_Status = 0xDFA401,
    TLVTag_Contactless_Kernel_And_Mode = 0xDF30,
    TLVTag_Form_Factor_Indicator = 0x9F6E,
    TLVTag_Terminal_Transaction_Qualifier = 0x9F66,
    TLVTag_POS_Entry_Mode = 0x9F39,
    TLVTag_Mobile_Support_Indicator = 0x9F7E,
    TLVTag_Payment_Cancel_Or_PIN_Entry_Timeout = 0x08,
    TLVTag_Payment_Internal_1 = 0x09,
    TLVTag_Payment_Internal_2 = 0x0A,
    TLVTag_Payment_Internal_3 = 0x0B,
    TLVTag_Payment_User_Bypassed_PIN = 0x0C,
    TVLTag_Terminal_Language_Preference = 0xDFA20C,
    TLVTag_Menu_Title = 0xDFA501,
    TLVTag_Menu_Option = 0xDFA502,
    TLVTag_Menu_Timeout = 0xDFA503,
    TLVTag_Sound_Duration = 0xDFB001,
    TLVTag_Sound_Volume = 0xDFB002,
    TLVTag_Sound_Frequency = 0xDFB003,
    
};



typedef struct {
    TLVTag tag;
} MPIDescriptionItem;

static const MPIDescriptionItem MPIDescriptionList[] = {
    {TLVTag_UNKNOWN},
    {TLVTag_Pin_Digit_Status},
    {TLVTag_Pin_ENtry_Status},
    {TLVTag_Message_Authentication_Code},
    {TLVTag_MAC_Result},
    {TLVTag_Touch_Screen_Area},
    {TLVTag_ICC_Answer_To_Reset},
    {TLVTag_Date},
    {TLVTag_Time},
    {TLVTag_File_Size},
    {TLVTag_Battery_Percentage},
    {TLVTag_Transaction_Sequence_Counter},
    {TLVTag_Issuer_Script_Template_1_71},
    {TLVTag_Issuer_Script_Template_1_72},
    {TLVTag_Issuer_Authentication_Data},
    {TLVTag_Card_Status},
    {TLVTag_AID},
    {TLVTag_Application_Label},
    {TLVTag_Track_2_Equivalent_Data},
    {TLVTag_Application_Primary_Account_Number_PAN},
    {TLVTag_Cardholder_Name},
    {TLVTag_Language_Preference},
    {TLVTag_Application_Expiration_Date},
    {TLVTag_Application_Effective_Date},
    {TLVTag_Issuer_Country_Code},
    {TLVTag_Transaction_Currency_Code},
    {TLVTag_Service_Code},
    {TLVTag_Application_Primary_Account_Number_PAN_Sequence_Number},
    {TLVTag_Transaction_Currency_Exponent},
    {TLVTag_Application_Template},
    {TLVTag_FCI_Template},
    {TLVTag_Read_Record_response},
    {TLVTag_Response_Message_Template_Format_2},
    //    {TLVTag_Response_Message_Template_Format_1},
    {TLVTag_Amount_Authorised_Binary},
    {TLVTag_Application_Interchange_Profile},
    {TLVTag_DF_Name},
    {TLVTag_Issuer_Script_Command},
    {TLVTag_Application_Priority_Indicator},
    {TLVTag_SFI},
    {TLVTag_Authorisation_Response_Code},
    {TLVTag_Card_Risk_Management_Data_Object_List_1_CDOL1},
    {TLVTag_Card_Risk_Management_Data_Object_List_2_CDOL2},
    {TLVTag_Cardholder_Verification_Method_CVM_List},
    {TLVTag_Certification_Authority_Public_Key_Index},
    {TLVTag_Issuer_Public_Key_Certificate},
    {TLVTag_Issuer_Public_Key_Remainder},
    {TLVTag_Signed_Static_Application_Data},
    {TLVTag_Application_File_Locator_AFL},
    {TLVTag_Terminal_Verification_Results},
    {TLVTag_Transaction_Certificate_Data_Object_List_TDOL},
    {TLVTag_Transaction_Status_Information},
    {TLVTag_Transaction_Type},
    {TLVTag_Transaction_Information_Status_sale},
    {TLVTag_Transaction_Information_Status_cash},
    {TLVTag_Transaction_Information_Status_cashback},
    {TVLTag_EmvHashValues_File_Not_Found},
    {TLVTag_Acquirer_Identifier},
    {TLVTag_Amount_Authorised_Numeric},
    {TLVTag_Amount_Other_Numeric},
    {TLVTag_Amount_Other_Binary},
    {TLVTag_Application_Discretionary_Data},
    {TLVTag_Application_Identifier_AID_terminal},
    {TLVTag_Application_Usage_Control},
    {TLVTag_ICC_Application_Version_Number},
    {TLVTag_Term_Application_Version_Number},
    {TLVTag_Cardholder_Name_Extended},
    {TLVTag_Issuer_Action_Code_Default},
    {TLVTag_Issuer_Action_Code_Denial},
    {TLVTag_Issuer_Action_Code_Online},
    {TLVTag_Issuer_Application_Data},
    {TLVTag_Issuer_Code_Table_Index},
    {TLVTag_Application_Preferred_Name},
    {TLVTag_Last_Online_Application_Transaction_Counter_ATC_Register},
    {TLVTag_Lower_Consecutive_Offline_Limit},
    {TLVTag_Personal_Identification_Number_PIN_Try_Counter},
    {TLVTag_Issuer_Script_Identifier},
    {TLVTag_Terminal_Country_Code},
    {TLVTag_Terminal_Floor_Limit},
    {TLVTag_Terminal_ID},
    {TLVTag_Interface_Device_Serial_Number},
    {TLVTag_Track_1_Discretionary_Data},
    {TLVTag_Track_2_Discretionary_Data},
    {TLVTag_Upper_Consecutive_Offline_Limit},
    {TLVTag_Application_Cryptogram},
    {TLVTag_Cryptogram_Information_Data},
    {TLVTag_ICC_PIN_Encipherment_Public_Key_Certificate},
    {TLVTag_ICC_PIN_Encipherment_Public_Key_Exponent},
    {TLVTag_ICC_PIN_Encipherment_Public_Key_Remainder},
    {TLVTag_Issuer_Public_Key_Exponent},
    {TLVTag_Terminal_Capabilities},
    {TLVTag_Cardholder_Verification_Method_CVM_Results},
    {TLVTag_Terminal_Type},
    {TLVTag_Application_Transaction_Counter_ATC},
    {TLVTag_Unpredictable_Number},
    {TLVTag_Processing_Options_Data_Object_List_PDOL},
    {TLVTag_Application_Reference_Currency},
    {TLVTag_Terminal_Capabilities_Add},
    {TLVTag_Application_Currency_Code},
    {TLVTag_Application_Reference_Currency_Exponent},
    {TLVTag_Application_Currency_Exponent},
    {TLVTag_ICC_Public_Key_Certificate},
    {TLVTag_ICC_Public_Key_Exponent},
    {TLVTag_ICC_Public_Key_Remainder},
    {TLVTag_Dynamic_Data_Authentication_Data_Object_List_DDOL},
    {TLVTag_Static_Data_Authentication_Tag_List},
    {TLVTag_Signed_Dynamic_Application_Data},
    {TLVTag_ICC_Dynamic_Number},
    {TLVTag_Issuer_Script_Results},
    {TLVTag_FCI_Proprietary_Template},
    {TLVTag_File_Control_Information_FCI_Issuer_Discretionary_Data},
    {TLVTag_Decision},
    {TLVTag_Acquirer_Index},
    {TLVTag_Status_Code},
    {TLVTag_Status_Text},
    {TLVTag_PIN_Retry_Counter},
    {TLVTag_Identifier},
    {TLVTag_Cardholder_Verification_Status},
    {TLVTag_Version},
    {TLVTag_Command_Data},
    {TLVTag_Response_Data},
    {TLVTag_Decision_Required},
    {TLVTag_Transaction_Approved},
    {TLVTag_Online_Authorisation_Required},
    {TLVTag_Transaction_Declined},
    {TLVTag_Terminal_Status_Changed},
    {TLVTag_Configuration_Information},
    {TLVTag_Software_Information},
    {TLVTag_Terminal_Action_Code_DEFAULT},
    {TLVTag_Terminal_Action_Code_OFFLINE},
    {TLVTag_Terminal_Action_Code_ONLINE},
    {TLVTag_PIN_Digit_Status},
    {TLVTag_PIN_Entry_Status},
    {TLVTag_Configure_TRM_Stage},
    {TLVTag_Configure_Application_Selection},
    {TLVTag_Keyboard_Data},
    {TLVTag_Secure_Prompt},
    {TLVTag_Number_Format},
    {TLVTag_Numeric_Data},
    {TLVTag_Charging_Status},
    {TLVTag_Secure_element},
    {TLVTag_PAN},
    {TLVTag_Start_date_as_YYMM},
    {TLVTag_Start_date_as_MMYY},
    {TLVTag_Expiry_date_as_YYMM},
    {TLVTag_Expiry_date_as_MMYY},
    {TLVTag_CVV},
    {TLVTAG_Timeout},
    {TLVTag_Dynamic_tip_percentage},
    {TLVTag_Dynamic_tip_template},
    {TLVTag_Stream_Offset},
    {TLVTag_Stream_Size},
    {TLVTag_Stream_timeout},
    {TLVTag_File_md5sum},
    {TLVTag_File_Space},
    {TLVTag_File_Used},
    {TLVTag_Bar_Code_Data},
    {TLVTag_Usb_Status},
    {TLVTag_P2PE_Status},
    {TLVTag_SRED_Data},
    {TLVTag_SRED_KSN},
    {TLVTag_Online_PIN_Data},
    {TLVTag_Online_PIN_KSN},
    {TLVTag_Masked_Track_2},
    {TLVTag_ICC_Masked_Track_2},
    {TLVTag_Masked_PAN},
    {TLVTag_Screen_Position},
    {TLVTag_Screen_Text_String},
    {TLVTag_Bitmap_Name},
    {TLVTag_Blink_Time_Normal},
    {TLVTag_Blink_Time_Inverted},
    {TLVTag_Blick_Time_Period},
    {TLVTag_Blink_Area},
    {TLVTag_Transaction_Info_Status_bits},
    {TLVTag_Revoked_certificates_list},
    {TLVTag_Online_DOL},
    {TLVTag_Referral_DOL},
    {TLVTag_ARPC_DOL},
    {TLVTag_Reversal_DOL},
    {TLVTag_AuthResponse_DO},
    {TLVTag_PSE_Directory},
    {TLVTag_Threshold_Value_for_Biased_Random_Selection},
    {TLVTag_Target_Percentage_for_Biased_Random_Selection},
    {TLVTag_Maximum_Target_Percentage_for_Biased_Random_Selection},
    {TLVTag_Default_CVM},
    {TLVTag_Issuer_script_size_limit},
    {TLVTag_Log_DOL},
    {TLVTag_Partial_AID_Selection_Allowed},
    {TLVTag_Transaction_Category_Code},
    {TLVTag_Balance_Before_Generate_AC},
    {TLVTag_Balance_After_Generate_AC},
    {TLVTag_Encrypted_Data},
    {TLVTag_Printer_Status},
    {TLVTag_Contactless_Kernel_And_Mode},
    {TLVTag_Form_Factor_Indicator},
    {TLVTag_Terminal_Transaction_Qualifier},
    {TLVTag_POS_Entry_Mode},
    {TLVTag_Mobile_Support_Indicator},
    {TVLTag_Terminal_Language_Preference},
    {TLVTag_Payment_Cancel_Or_PIN_Entry_Timeout},
    {TLVTag_Payment_Internal_1},
    {TLVTag_Payment_Internal_2},
    {TLVTag_Payment_Internal_3},
    {TLVTag_Payment_User_Bypassed_PIN},
    {TLVTag_Menu_Title},
    {TLVTag_Menu_Option},
    {TLVTag_Menu_Timeout},
    {TLVTag_Sound_Duration},
    {TLVTag_Sound_Volume},
    {TLVTag_Sound_Frequency},
};

static NSUInteger MPIDescriptionListLength = sizeof(MPIDescriptionList) / sizeof(MPIDescriptionItem);

@interface MPIDescription: NSObject


#pragma mark - Property

/// TLV Tag
@property(nonatomic, assign, readonly, getter = getTag) TLVTag tag;
/// Property for unknown tag judgement
@property(nonatomic, assign, readonly, getter = isUnknown) BOOL unknown;

+ (instancetype)descriptionWithTag:(TLVTag)tag;
- (instancetype)initWithTag:(TLVTag)tag;
- (TLVTag)tagID;
- (NSString *)outline;

@end
