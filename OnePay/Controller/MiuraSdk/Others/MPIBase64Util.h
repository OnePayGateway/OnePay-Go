#import <Foundation/Foundation.h>


@interface MPIBase64Util : NSObject

//base64 encode/decode functions
+ (NSData *)encodedBase64DataWithData:(NSData *)data;
+ (NSString *)encodedBase64StringWithData:(NSData *)data;

//init NSData with base64 encoded data as decoded data

//return base64 decoded data
+ (NSData *)decodeBase64DataWithString:(NSString *)base64;

//url encode/decode functions
+ (NSString *)urlEncodedStringWithData:(NSData *)data;

//AES encrypt/decrypt functions

//bytes expression in string

//return null terminated string

@end
