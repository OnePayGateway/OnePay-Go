//
//  KernelHashValues.m
//  MiuraSdk
//
//  Created by John Barton on 31/08/2018.
//  Copyright © 2018 Miura Systems Ltd. All rights reserved.
//

#import "MPIKernelHashValues.h"

@implementation MPIKernelHashValues

@synthesize key_set,kernel_Hash_Map;

/**
 * Lookup the filename + version for a given EMV Kernel name and hash value
 *
 * @param kernel The name of the kernel to lookup
 * @param hashValue The hash value to lookup
 * @return Returns the version if found, or null if not found
 */

- (NSString *)lookUp:(NSString *)kernel hashValue:(NSString *) hashValue {
    
    NSDictionary *emvl2Ep = @{@"72460C9D081A25253B1F1D5BCDDA7D65" : @"M000-EMVL2EP-V1-0",
                              @"F8C97853A906A62932896D5B18CE2D03" : @"M000-EMVL2EP-V1-1",
                              @"6572917BF5E7A31AC9DAFCBE369D87A7" : @"M000-EMVL2EP-V1-2",
                              @"2234B980B07CC9E7FFD58E9CC5A0F9A7" : @"M000-EMVL2EP-V1-3",
                              @"E1BEA45A0741458DBF7E0730B18EAA27" : @"M000-EMVL2EP-V1-4",
                              @"19672144287C17033EB1468A8D29CF3F" : @"M000-EMVL2EP-V1-5",
                              @"EF824121C67A0C54E7967CFA0E8D0EFF" : @"M000-EMVL2EP-V1-6",
                              @"DE98BC33F3C23C14C2B628FBC2F97905" : @"M000-EMVL2EP-V1-7",
                              @"580CEEF8AF7B325EA59FE19B42C95661" : @"M000-EMVL2EP-V1-8",
                              @"A379B10E1A20881CB93C8F13F187360E" : @"M000-EMVL2EP-V1-9",
                              @"40DE37DDC64A8C16401E76640C1063BA" : @"M000-EMVL2EP-V1-10",
                              @"586A6356D776718677E388FD2C214843" : @"M000-EMVL2EP-V1-11",
                              @"61D0115F2635480644E8D6876698A64B" : @"M000-EMVL2EP-V1-12",
                              @"0018768E0B87AF93B8DEBCAE7F5753F4" : @"M000-EMVL2EP-V1-13",
                              @"451FE64628FF09D31DE6C288CF1C144C" : @"M000-EMVL2EP-V1-14",
                              @"919E5DA143690DA024192BB50E0ED983" : @"M000-EMVL2EP-V1-15",
                              @"07884BDEB423EEDAABF81911B85952E0" : @"M000-EMVL2EP-V1-16",
                              };
    
    NSDictionary *emvl2cl = @{@"F46D202E5A326152DD44F472A23E3330" : @"M000-EMVL2CL-V1-0",
                              @"615ED3A69C3A7662613D0144A3A7AFE3" : @"M000-EMVL2CL-V1-1",
                              @"8ADB3BFDD67E71A74E90CBE6C2FB21FD" : @"M000-EMVL2CL-V1-2",
                              @"3FC386A44F70699F0A685DC5EB97D354" : @"M000-EMVL2CL-V1-3",
                              @"391C00AA67374089EE85180049572250" : @"M000-EMVL2CL-V1-4",
                              @"9AB538DD4FBC29C2F5158A7CD8C074AF" : @"M000-EMVL2CL-V1-5",
                              @"7CAC28D22581457F73D68B9A90E3BE43" : @"M000-EMVL2CL-V1-6",
                              @"B6F11D202B28BE78B947BF1CC928581D" : @"M000-EMVL2CL-V1-7",
                              @"E9482D467086C5A5EF6AC2F6D3342493" : @"M000-EMVL2CL-V1-8",
                              @"C2AB4FA5013CCADE0FE0DA26B1C3C01D" : @"M000-EMVL2CL-V1-9",
                              @"E5570F3A9AEE6B5ADF304D92A703E8C3" : @"M000-EMVL2CL-V1-10",
                              @"25491C8FD4213AAA90DB790468AAE640" : @"M000-EMVL2CL-V1-11",
                              @"337D990F76E3F4D90AD59399C86E4119" : @"M000-EMVL2CL-V1-12",
                              @"A7277EA1EECD74D521E0EA975E5F3E7C" : @"M000-EMVL2CL-V1-13",
                              @"A17C8E6DAD0758E41D26959B46F6396E" : @"M000-EMVL2CL-V1-14",
                              @"648A032428BD85E8C7C71EB3EAA9AFCE" : @"M000-EMVL2CL-V1-15",
                              @"1B661EDFD7BDED001010693697C27B0E" : @"M000-EMVL2CL-V1-16",
                              @"85A1A46C16AA848FF72937C8501A2337" : @"M000-EMVL2CL-V1-17",
                              @"1B471380777317AD6290534D040B8DDC" : @"M000-EMVL2CL-V1-18",
                              @"FDD14A278145826C9BAC513DD894187F" : @"M000-EMVL2CL-V1-19",

                              };
    
    NSDictionary *emvl2K = @{@"10931576084043FB8CE4B6A64EF3ECAA" : @"M000-EMVL2K-V2-5",
                             @"1A72BAFDCFB9F5677753F53661B9948D" : @"M000-EMVL2K-V3-0",
                             @"3FF9750489DEB4027E6E0E67A43B172D" : @"M000-EMVL2K-V3-2",
                             @"B9D8EE5CF8CA758DC7251DE409465E3B" : @"M000-EMVL2K-V3-4",
                             };
    
    NSDictionary *emvl2K1 = @{@"44FE1870EA85445126606E4A23AF3C93" : @"M000-EMVL2K1-V1-0",
                              @"BC3A718967CCEBFA74215D462D279629" : @"M000-EMVL2K1-V1-1",
                              };
    
    NSDictionary *emvl2K2 = @{@"FC8EE778EB8CD41CC6E505F1EFA0A2E1" : @"M000-EMVL2K2-V1-0",
                              @"6F5733530A8562422984FC7137784B46" : @"M000-EMVL2K2-V1-1",
                              @"545457E9D9FBEB9FB53A2C1F4E5FC171" : @"M000-EMVL2K2-V1-2",
                              };
    
    NSDictionary *emvl2k3 = @{@"918C3AFC9F10A0488231FE11F7D6EBF1" : @"M000-EMVL2K3-V1-0",
                              @"21AE490B6BEC9F6ABB00056575619159" : @"M000-EMVL2K3-V1-1",
                              @"9BB70C6D1D9EDDBD601FB00C83A6234D" : @"M000-EMVL2K3-V1-2",
                              @"828E7D5CB83ED89C809C7AE12F85CC2E" : @"M000-EMVL2K3-V1-3",
                              };
    
    NSDictionary *emvl2k4 = @{@"2147080DEDF14667356B1CB13CD9181D" : @"M000-EMVL2K4-V1-0",
                              @"30176987732116381737920CB9EE3321" : @"M000-EMVL2K4-V1-1",
                              @"9CFFECFC129BD362D7AD7336C7C4BF02" : @"M000-EMVL2K4-V1-2",
                              @"95A87ACB9CFE0CCAD6CAF91323D1A5D6" : @"M000-EMVL2K4-V1-3",
                              @"AF65BC81B6F4F002AA52CEE800A5889D" : @"M000-EMVL2K4-V1-4",
                              @"1173C853C6E48A2FE5E6FBF5D5E0926E" : @"M000-EMVL2K4-V1-5",
                              @"C501FBC820E6D50152133E1A38DD9FCA" : @"M000-EMVL2K4-V1-6",
                              };
    
    NSDictionary *emvl2k5 = @{@"CDE7BECD8D27941674539BBEFC5795D1" : @"M000-EMVL2K5-V1-0",
                              };
    
    NSDictionary *emvl2k6 = @{@"DBE74A779A7A09D9802A8B1870BEFD78" : @"M000-EMVL2K6-V1-0",
                              @"AEF1DB7CCCB35AD61547C41A6CA7AE77" : @"M000-EMVL2K6-V1-1",
                              @"DA6D1AB8EC9A04532F54661521AE6750" : @"M000-EMVL2K6-V1-2",
                              };
    
    NSDictionary *emvl2ka = @{@"E51117484D216599BD8D8207594830CA" : @"M000-EMVL2KA-V1-0",
                              @"6D1BB37445CAAD0A92B9C65709D55B4A" : @"M000-EMVL2KA-V1-1",
                              };
    
    NSDictionary *emvl2kb = @{@"05603725E6D195E60F74E2D02D907045" : @"M000-EMVL2KB-V1-0",
                              @"7A37D1A8B634B739A42F4D625BF9B747" : @"M000-EMVL2KB-V1-1",
                              };

    NSDictionary *emvl2kc = @{@"8B30898EF14135DF16D22030623E7CA3" : @"M000-EMVL2KC-V1-0",
                              };
    
    
    kernel_Hash_Map = [NSMutableDictionary new];
    
    [kernel_Hash_Map setObject:emvl2Ep forKey:@"EMVL2EP"];
    [kernel_Hash_Map setObject:emvl2cl forKey:@"EMVL2CL"];
    [kernel_Hash_Map setObject:emvl2K forKey:@"EMVL2K"];
    [kernel_Hash_Map setObject:emvl2K1 forKey:@"EMVL2K1"];
    [kernel_Hash_Map setObject:emvl2K2 forKey:@"EMVL2K2"];
    [kernel_Hash_Map setObject:emvl2k3 forKey:@"EMVL2K3"];
    [kernel_Hash_Map setObject:emvl2k4 forKey:@"EMVL2K4"];
    [kernel_Hash_Map setObject:emvl2k5 forKey:@"EMVL2K5"];
    [kernel_Hash_Map setObject:emvl2k6 forKey:@"EMVL2K6"];
    [kernel_Hash_Map setObject:emvl2ka forKey:@"EMVL2KA"];
    [kernel_Hash_Map setObject:emvl2kb forKey:@"EMVL2KB"];
    [kernel_Hash_Map setObject:emvl2kc forKey:@"EMVL2KC"];
    
    [kernel_Hash_Map isEqual:key_set];
    
    NSDictionary *fileMap = [kernel_Hash_Map objectForKey:kernel];
    
    if (fileMap == NULL){
        NSLog(@"Unknown Kernel:-%@", kernel);
        return NULL;
    } else {
        return [fileMap objectForKey:hashValue];
    }
    
}

@end
