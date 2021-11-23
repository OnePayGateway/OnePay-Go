//
//  DisplayMediaData.m
//  MiuraSdk
//
//  Created by John Barton on 06/12/2019.
//  Copyright © 2019 Miura Systems Ltd. All rights reserved.
//

#import "DisplayMediaData.h"
#import "MPIBinaryUtil.h"
#import "MPITLVObject.h"

@implementation DisplayMediaData

@synthesize turnBacklightOn, useUTF8Encoding, tlvList;

- (void)DisplayMediaData:(BOOL)isTurnBacklightOn
       isUseUTF8Encoding:(BOOL)isUseUTF8Encoding
                 getList:(NSArray*)getList {
    
    isTurnBacklightOn = turnBacklightOn;
    isUseUTF8Encoding = useUTF8Encoding;
    getList = tlvList;
    return;
}

/**
 * Set the Screen position for subsequent text or images
 *
 * @param x x-coordinate.
 * @param y y-coordinate.
*/
- (void)addScreenPosition:(int)x atY:(int)y {
  
    Byte bytes[] = { 0x04 };
    NSData *dataField = [NSData dataWithBytes:bytes length:1];
    
    [MPIBinaryUtil convertIntToHexByteArray:bytes value:(unsigned char)x byteCount:(unsigned long)2 index:(unsigned long)0];
    [MPIBinaryUtil convertIntToHexByteArray:bytes value:(unsigned char)y byteCount:(unsigned int)2 index:(unsigned long)2];
    
    MPITLVObject *screenObj = [[MPITLVObject alloc]initWithTag:TLVTag_Screen_Position value:dataField];
    [tlvList arrayByAddingObject:screenObj];

    return;
}

/**
 * Sets the text to display at the most recent position.
 *
 * @param text Text to display.
 */
- (void)addText:(NSString *)text {
    
    NSCharacterSet *setText = [NSCharacterSet characterSetWithCharactersInString:
                               [NSString stringWithCString:[text cStringUsingEncoding:NSASCIIStringEncoding]encoding:NSUTF8StringEncoding]];
    
    NSData *dataField = [NSData dataWithBytes:(__bridge const void * _Nullable)(setText) length:1];
    
    MPITLVObject *screenObj = [[MPITLVObject alloc]initWithTag:TLVTag_Screen_Text_String value:dataField];
    [tlvList arrayByAddingObject:screenObj];
    
    return;
    
}

/**
 * Sets the image to display at the most recent position.
 *
 * @param filename  Bitmap filename.
*/
- (void)addImage:(NSString *)filename {
    
    const char *addFile = [filename cStringUsingEncoding:NSASCIIStringEncoding];
    NSData *dataField = [NSData dataWithBytes:addFile length:1];
    
    MPITLVObject *screenObj = [[MPITLVObject alloc]initWithTag:TLVTag_Bitmap_Name value:dataField];
    [tlvList arrayByAddingObject:screenObj];
    
    return;
 
}

/**
 * Sets the time in milliseconds to hold the screen or defined area
 * in normal mode.
 *
 * @param blinkTime     Time in milliseconds.
*/
- (void)addBlinkTimeNormal:(int)blinkTime {
    
    Byte dataField = [MPIBinaryUtil convertIntToHexByteArray:nil value:(unsigned char)blinkTime
                                                          byteCount:(unsigned long)2 index:0];
    
    NSData *data = [NSData dataWithBytes: dataField length:sizeof(dataField)];
    
    MPITLVObject *screenObj = [[MPITLVObject alloc]initWithTag:TLVTag_Blink_Time_Normal value:data];
    [tlvList arrayByAddingObject:screenObj];
    
    return;
}

/**
 * Sets the time in milliseconds to hold the screen or defined area
 * in inverted mode.
 *
 * @param blinkTime     Time in milliseconds.
*/
- (void)addBlinkTimeInverted:(NSUInteger *)blinkTime {
    
    Byte *dataField = [MPIBinaryUtil convertIntToHexByteArray:nil
                                                        value:(unsigned char)blinkTime
                                                    byteCount:2 index:0];
    
    NSData *data = [NSData dataWithBytes:dataField length:sizeof(dataField)];
    
    MPITLVObject *screenObj = [[MPITLVObject alloc]initWithTag:TLVTag_Blink_Time_Inverted value:data];
    [tlvList arrayByAddingObject:screenObj];
    
    return;
    
}

/**
 * Sets the total time in milliseconds the screen or defined area
 * will alternate between normal and inverted modes.
 *
 * @param blinkTime     Time in milliseconds.
*/
- (void)addBlinkTimePeriod:(NSUInteger *)blinkTime {
    
    Byte *dataField = [MPIBinaryUtil convertIntToHexByteArray:nil
                                                        value:(unsigned char)blinkTime
                                                    byteCount:2
                                                        index:0];
    
    NSData *data = [NSData dataWithBytes:dataField length:sizeof(dataField)];
    
    MPITLVObject *screenObj = [[MPITLVObject alloc]initWithTag:TLVTag_Blick_Time_Period value:data];
    [tlvList arrayByAddingObject:screenObj];
    
    return;
    
}

/**
 * Defines an area to flash if blinking has been enabled.
 *
 * @param startX    Top left x-coordinate.
 * @param startY    Top left y-coordinate.
 * @param endX      Bottom-right x-coordinate.
 * @param endY      Bottom-right y-coordinate.
*/
- (void)addBlinkArea:(int)startX
              startY:(int)startY
                endX:(int)endX
                endY:(int)endY {
    
    Byte bytes[] = { 0x08 };

    [MPIBinaryUtil convertIntToHexByteArray:bytes value:startX byteCount:2 index:0];
    [MPIBinaryUtil convertIntToHexByteArray:bytes value:startY byteCount:2 index:2];
    [MPIBinaryUtil convertIntToHexByteArray:bytes value:endX byteCount:2 index:4];
    [MPIBinaryUtil convertIntToHexByteArray:bytes value:endY byteCount:2 index:6];
    
    NSData *data = [NSData dataWithBytes:bytes length:sizeof(bytes)];
    
    MPITLVObject *screenObj = [[MPITLVObject alloc]initWithTag:TLVTag_Blink_Area value:data];
    [tlvList arrayByAddingObject:screenObj];
    
    return;

}

@end
