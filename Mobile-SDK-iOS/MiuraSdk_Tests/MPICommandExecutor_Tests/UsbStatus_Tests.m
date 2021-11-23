//
//  UsbStatus_Tests.m
//  MiuraSdk_Tests
//
//  Created by John Barton on 28/11/2019.
//  Copyright © 2019 Miura Systems Ltd. All rights reserved.
//
#import "MPICommandExecutor.h"
#import <XCTest/XCTest.h>

@interface UsbStatus_Tests : XCTestCase

@end

@implementation UsbStatus_Tests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testUsbStatusChange {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    NSData *command = [MPICommandExecutor enableUsbStatus:true completion:^(BOOL usbCommandStatus) {
         NSLog(@"Complete");
     }];
     
     const UInt8 * p_command = (const UInt8*)[command bytes];
     UInt8 class = p_command[3];
     UInt8 ins= p_command[4];
     UInt8 p1 = p_command[5];
     UInt8 p2 = p_command[6];
         
     XCTAssert((p1 == 0x01), "Failed P1 not expected. P1 = %02x", p1);
     XCTAssert((p2 == 0x00), "Failed P2 not expected. P2 = %02x", p2);
     XCTAssert((class == 0xD0), "Failed Class not expected. Class = %02x", class);
     XCTAssert((ins == 0x65), "Failed Ins not expected. Ins = %02x", ins);
}

- (void)testUsbStatusChangeP1 {
    /*All True*/
    NSData * command;
    UInt8 * p_command;
    UInt8 p1;
    
    command = [MPICommandExecutor enableUsbStatus:true completion:^(BOOL usbCommandStatus) {
        NSLog(@"Complete");
    }];
    
    p_command = (UInt8*)[command bytes];
    p1 = p_command[5];
    
    XCTAssert((p1 == 0x01), "Failed P1 not expected. P1 = %02x", p1);
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
