//
//  BatteryStatus_Test.m
//  MiuraSdk_Tests
//
//  Created by Martyn Casey on 06/03/2020.
//  Copyright © 2020 Miura Systems Ltd. All rights reserved.
//

#import "MPICommandExecutor.h"
#import <XCTest/XCTest.h>

@interface BatteryStatus_Test : XCTestCase

@end

@implementation BatteryStatus_Test

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testGetStatus {
    NSData * command = [MPICommandExecutor batteryStatus:FALSE setEvents:FALSE onChargingChange:FALSE onThresholdReached:FALSE completion:^(ChargingStatus chargingStatus, NSUInteger batteryPercentage) {
        return;
    }];
    
    const UInt8 * p_command = (const UInt8*)[command bytes];
    UInt8 class = p_command[3];
    UInt8 ins= p_command[4];
    UInt8 p1 = p_command[5];
    UInt8 p2 = p_command[6];

    XCTAssert((p1 == 0x00), "Failed P1 not expected. P1 = %02x", p1);
    XCTAssert((p2 == 0x00), "Failed P2 not expected. P2 = %02x", p2);
    XCTAssert((class == 0xD0), "Failed Class not expected. Class = %02x", class);
    XCTAssert((ins == 0x62), "Failed Ins not expected. Ins = %02x", ins);

}

- (void)testSleep {
    NSData * command = [MPICommandExecutor batteryStatus:TRUE setEvents:FALSE onChargingChange:FALSE onThresholdReached:FALSE completion:^(ChargingStatus chargingStatus, NSUInteger batteryPercentage) {
        return;
    }];
    
    const UInt8 * p_command = (const UInt8*)[command bytes];
    UInt8 p1 = p_command[5];
    UInt8 p2 = p_command[6];

    XCTAssert((p1 == 0x01), "Failed P1 not expected. P1 = %02x", p1);
    XCTAssert((p2 == 0x00), "Failed P2 not expected. P2 = %02x", p2);
}

- (void) testSetEvents {
    NSData * command = [MPICommandExecutor batteryStatus:FALSE setEvents:TRUE onChargingChange:TRUE onThresholdReached:TRUE completion:^(ChargingStatus chargingStatus, NSUInteger batteryPercentage) {
        return;
    }];
    
    const UInt8 * p_command = (const UInt8*)[command bytes];
    UInt8 p1 = p_command[5];
    UInt8 p2 = p_command[6];

    XCTAssert((p1 == 0x03), "Failed P1 not expected. P1 = %02x", p1);
    XCTAssert((p2 == 0x03), "Failed P2 not expected. P2 = %02x", p2);
}
- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
