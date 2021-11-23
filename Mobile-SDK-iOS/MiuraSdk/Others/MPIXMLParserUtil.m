#import "MPIXMLParserUtil.h"


@implementation MPIXMLParserUtil

- (void)dealloc {
    myParser = nil;
    currentRecord = nil;
}


#pragma mark - function for external use

+ (NSArray *)parseXML:(NSData *)xmlData {
    return [[[self alloc] init] parseXML:xmlData];
}

- (NSArray *)parseXML:(NSData *)xmlData {
    // XML data object
    receiveData = [[NSMutableData alloc] initWithData:xmlData];

    // Parse XML data object
    myParser = [[NSXMLParser alloc] initWithData:receiveData];
    [myParser setDelegate:self];
    [myParser setShouldResolveExternalEntities:YES];
    BOOL success = [myParser parse];
    if (success) {
        NSMutableArray *aryReturn = [[NSMutableArray alloc] init];
        [aryReturn addObject:currentRecord];
        return [aryReturn copy];
    }
    else {
        return nil;
    }
}


#pragma mark - XMLParser delegate

- (void)parser:(NSXMLParser *)parser
    didStartElement:(NSString *)elementName
    namespaceURI:(NSString *)namespaceURI
    qualifiedName:(NSString *)qName
    attributes:(NSDictionary *)attributeDict {
    if ([elementName isEqualToString:@"response"]) {
        currentRecord = [[NSMutableDictionary alloc] init];
    }
}

- (void)parser:(NSXMLParser *)parser
    foundCharacters:(NSString *)string {
    if (!currentStringValue) {
        currentStringValue = [[NSMutableString alloc] initWithCapacity:50];
    }
    NSString *strBuf = nil;
    // Convert new line character for reciept from "\r\n" to "\r"
    if ([@"\r" isEqualToString:string]) {
        strBuf = @"\r";
    } else {
        strBuf = [[NSString alloc] initWithString:[string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
    }
    [currentStringValue appendString:strBuf];
}

- (void)parser:(NSXMLParser *)parser
    didEndElement:(NSString *)elementName
    namespaceURI:(NSString *)nameSpaceURI
    qualifiedName:(NSString *)qName {
    if ([elementName isEqualToString:@"err_code"] || [elementName isEqualToString:@"err_str"]) {
        [_connectionError setValue:currentStringValue forKey:elementName];
    } else {
        if ([elementName isEqualToString:@"response"]) {
            return;
        }
        [currentRecord setValue:currentStringValue forKey:elementName];
    }
    currentStringValue = nil;
}

@end