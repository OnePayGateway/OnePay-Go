#import "MPIDescription.h"
#import "../../Others/MPIBinaryUtil.h"


@interface MPIDescription () {
    MPIDescriptionItem _item;
    NSUInteger _undefinedTag;
}
@property(nonatomic, assign, readwrite, getter = getTag) TLVTag tag;
@property(nonatomic, assign, readwrite, getter = isUnknown) BOOL unknown;
@end


@implementation MPIDescription


+ (instancetype)descriptionWithTag:(TLVTag)tag {
    return [[MPIDescription alloc] initWithTag:tag];
}

- (instancetype)initWithTag:(TLVTag)tag {
    self = [super init];
    if (self) {
        _item = [self descriptionItemByTag:tag];
        if (_item.tag == TLVTag_UNKNOWN) {
            _undefinedTag = tag;
        }
        self.tag = _item.tag;
    }
    return self;
}

- (TLVTag)tagID {
    if (_item.tag == TLVTag_UNKNOWN) {
        return _undefinedTag;
    } else {
        return self.tag;
    }
}

- (NSString *)outline {
    NSMutableString *ms = [[NSMutableString alloc] init];

    [ms appendString:NSStringFromClass([MPIDescription class])];
    [ms appendString:@"("];
    [ms appendFormat:@"0x%@", [MPIBinaryUtil hexStringWithInt:self.tag]];
    [ms appendString:@")"];

    return [ms copy];
}





/// Search Tag
- (MPIDescriptionItem)descriptionItemByTag:(TLVTag)tag {
    for (NSUInteger i = 0; i < MPIDescriptionListLength; i++) {
        MPIDescriptionItem item = MPIDescriptionList[i];
        if (item.tag == tag) {
            return item;
            break;
        }
    }
    self.unknown = YES;
    return [self descriptionItemByTag:TLVTag_UNKNOWN];
}

@end
