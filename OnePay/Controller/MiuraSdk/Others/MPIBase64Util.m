#import "MPIBase64Util.h"
#import <CommonCrypto/CommonCryptor.h>


@implementation MPIBase64Util

#define XX 127
const unsigned char MiuraSDK_Base64Pad = '=';
const unsigned char MiuraSDK_Base64Encode[] =
"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

+ (NSData *)encodedBase64DataWithData:(NSData *)data {
    NSUInteger inputTriplets  = [data length] / 3;
    NSUInteger inputRemainder = [data length] % 3;
    NSUInteger outputLength = inputTriplets * 4;
    NSUInteger index;
    unsigned char *outputBuffer, *inputBuffer;
    unsigned char t1, t2, t3;
    NSMutableData *outputData;
    
    if (0 != inputRemainder) outputLength += 4;
    
    outputData = [NSMutableData dataWithLength:outputLength];
    outputBuffer = [outputData mutableBytes];
    inputBuffer = (unsigned char *)[data bytes];
    
    for (index = 0; index < inputTriplets; index++) {
        t1 = *inputBuffer++;
        t2 = *inputBuffer++;
        t3 = *inputBuffer++;
        *outputBuffer++ = MiuraSDK_Base64Encode[t1 >> 2];
        *outputBuffer++ = MiuraSDK_Base64Encode[(t1 & 0x3) << 4 | t2 >> 4];
        *outputBuffer++ = MiuraSDK_Base64Encode[(t2 & 0xF) << 2 | t3 >> 6];
        *outputBuffer++ = MiuraSDK_Base64Encode[t3 & 0x3F];
    }
    
    if (2 == inputRemainder) {
        t1 = *inputBuffer++;
        t2 = *inputBuffer++;
        *outputBuffer++ = MiuraSDK_Base64Encode[t1 >> 2];
        *outputBuffer++ = MiuraSDK_Base64Encode[(t1 & 0x3) << 4 | t2 >> 4];
        *outputBuffer++ = MiuraSDK_Base64Encode[(t2 & 0xF) << 2];
        *outputBuffer++ = MiuraSDK_Base64Pad;
        
    } else if (1 == inputRemainder) {
        t1 = *inputBuffer++;
        *outputBuffer++ = MiuraSDK_Base64Encode[t1 >> 2];
        *outputBuffer++ = MiuraSDK_Base64Encode[(t1 & 0x3) << 4];
        *outputBuffer++ = MiuraSDK_Base64Pad;
        *outputBuffer++ = MiuraSDK_Base64Pad;
    }
    
    return outputData;
}

+ (NSString *)encodedBase64StringWithData:(NSData *)data {
    return [NSString stringWithString:[self urlEncodedStringWithData:[self encodedBase64DataWithData:data]]];
}

+ (NSString *)urlEncodedStringWithData:(NSData *)data {
    
    NSString *originString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    NSString *encodedString = [originString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLPathAllowedCharacterSet]];

    return encodedString;
}

static const short MiuraSDK_base64DecodingTable[256] = {
    -2, -2, -2, -2, -2, -2, -2, -2, -2, -1, -1, -2, -1, -1, -2, -2,
    -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
    -1, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, 62, -2, -2, -2, 63,
    52, 53, 54, 55, 56, 57, 58, 59, 60, 61, -2, -2, -2, -2, -2, -2,
    -2,  0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14,
    15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, -2, -2, -2, -2, -2,
    -2, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40,
    41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, -2, -2, -2, -2, -2,
    -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
    -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
    -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
    -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
    -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
    -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
    -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
    -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2
};

+ (NSData *)decodeBase64DataWithString:(NSString *)base64 {
    if (base64 == nil) {
        return nil;
    }
    const char * objPointer = [base64 cStringUsingEncoding:NSASCIIStringEncoding];
    NSInteger intLength = strlen(objPointer);
    NSInteger intCurrent;
    NSInteger i = 0, j = 0, k;
    
    unsigned char * objResult;
    objResult = calloc(intLength, sizeof(unsigned char));
    
    // Run through the whole string, converting as we go
    while ( ((intCurrent = *objPointer++) != '\0') && (intLength-- > 0) ) {
        if (intCurrent == '=') {
            if (*objPointer != '=' && ((i % 4) == 1)) {// || (intLength > 0)) {
                // the padding character is invalid at this point -- so this entire string is invalid
                free(objResult);
                return nil;
            }
            continue;
        }
        
        intCurrent = MiuraSDK_base64DecodingTable[intCurrent];
        if (intCurrent == -1) {
            // we're at a whitespace -- simply skip over
            continue;
        } else if (intCurrent == -2) {
            // we're at an invalid character
            free(objResult);
            return nil;
        }
        
        switch (i % 4) {
            case 0:
                objResult[j] = intCurrent << 2;
                break;
                
            case 1:
                objResult[j++] |= intCurrent >> 4;
                objResult[j] = (intCurrent & 0x0f) << 4;
                break;
                
            case 2:
                objResult[j++] |= intCurrent >>2;
                objResult[j] = (intCurrent & 0x03) << 6;
                break;
                
            case 3:
                objResult[j++] |= intCurrent;
                break;
        }
        i++;
    }
    
    // mop things up if we ended on a boundary
    k = j;
    if (intCurrent == '=') {
        switch (i % 4) {
            case 1:
                // Invalid state
                free(objResult);
                return nil;
                
            case 2:
                k++;
                // flow through
            case 3:
                objResult[k] = 0;
        }
    }
    
    // Cleanup and setup the return NSData
    NSData * objData = [[NSData alloc] initWithBytes:objResult length:j];
    free(objResult);
    return objData;
}

@end
