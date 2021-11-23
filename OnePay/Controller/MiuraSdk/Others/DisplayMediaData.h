//
//  DisplayMediaData.h
//  MiuraSdk
//
//  Created by John Barton on 06/12/2019.
//  Copyright © 2019 Miura Systems Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface DisplayMediaData : NSObject

@property(nonatomic, readonly, copy) NSArray *tlvList;
@property(nonatomic, assign) BOOL turnBacklightOn;
@property(nonatomic, assign) BOOL useUTF8Encoding;

- (void)addText:(NSString *)text;
- (void)addScreenPosition:(int)x atY:(int)y;
- (void)addImage:(NSString *)filename;
- (void)addBlinkTimeNormal:(int)blinkTime;
- (void)addBlinkTimeInverted:(NSUInteger *)blinkTime;
- (void)addBlinkTimePeriod:(NSUInteger *)blinkTime;
- (void)addBlinkArea:(int)startX startY:(int)startY endX:(int)endX endY:(int)endY;


@end


