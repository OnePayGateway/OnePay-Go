#import <Foundation/Foundation.h>


@interface MPIXMLParserUtil: NSObject < NSXMLParserDelegate > {
    // Get data
    NSMutableArray                  *contents;
    NSMutableData                   *receiveData;
    NSXMLParser                     *myParser;
    NSMutableDictionary             *currentRecord;
    NSMutableString                 *currentStringValue;
    NSMutableDictionary             *_connectionError;

    // Response data object
    NSMutableDictionary             *parseDictionary;
    NSMutableArray                  *parseArray;
}

+ (NSArray *)parseXML:(NSData *)xmlData;
- (NSArray *)parseXML:(NSData *)xmlData;

@end