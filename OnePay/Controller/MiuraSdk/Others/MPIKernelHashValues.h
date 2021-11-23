//
//  KernelHashValues.h
//  MiuraSdk
//
//  Created by John Barton on 31/08/2018.
//  Copyright © 2018 Miura Systems Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MPIKernelHashValues : NSObject

@property(strong, nonatomic) NSMutableSet *key_set;
@property(strong, nonatomic) NSMutableDictionary *kernel_Hash_Map;

- (NSString *)lookUp:(NSString *)kernel hashValue:(NSString *) hashValue;


@end
