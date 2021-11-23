#import "MPITag.h"
#import "MPIBinaryUtil.h"


@interface MPITag () {
}
@property(nonatomic, strong, readwrite) MPIDescription *tagDescription;
@end


@implementation MPITag


+ (instancetype)tagWithTag:(TLVTag)tag {
    return [[MPITag alloc] initWithTag:tag];
}

- (instancetype)initWithTag:(TLVTag)tag {
    self = [super init];
    if (self) {
        self.tagDescription = [MPIDescription descriptionWithTag:tag];
    }
    return self;
}

- (void)dealloc {
    self.tagDescription = nil;
}

- (NSString *)outline {
    NSMutableString *ms = [[NSMutableString alloc] init];

    [ms appendString:self.tagDescription.outline];
    [ms appendString:@"("];
    [ms appendFormat:@"0x%@", [MPIBinaryUtil hexStringWithInt:self.tagDescription.tag]];
    [ms appendString:@")"];

    return [ms copy];
}

@end