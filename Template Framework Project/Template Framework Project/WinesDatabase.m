//
//  WinesDatabase.m
//  Template Framework Project
//
//  Created by Sergey Yuzepovich on 28.01.15.
//  Copyright (c) 2015 Daniele Galiotto - www.g8production.com. All rights reserved.
//

#import "WinesDatabase.h"
#import "CHCSVParser.h"
#import "Wine.h"
#import "Vineyard.h"

static NSUInteger const WORD_SPLIT_LEN = 5;
static NSString* const DB = @"TermListByWineryNewWorldOnly";

@interface WinesDatabase()<CHCSVParserDelegate>
@property(nonatomic,strong) NSMutableDictionary *wineriesVarieties;
@property(nonatomic,strong) NSMutableDictionary *wineriesVineyards;
@end

@implementation WinesDatabase
{
    NSString *lastKey;
    NSString *lastValue;
}

+(instancetype)instance{
    static id instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[WinesDatabase alloc]init];
    });
    
    return instance;
}

-(instancetype) init{
    self = [super init];
    if(self){
        _wineriesVarieties = [[NSMutableDictionary alloc]init];
        _wineriesVineyards = [[NSMutableDictionary alloc]init];
        
        NSString *dbPath = [[NSBundle mainBundle] pathForResource:DB ofType:@"csv"];
        NSInputStream *stream = [NSInputStream inputStreamWithURL:[NSURL fileURLWithPath:dbPath]];
        NSStringEncoding encoding = nil;//NSUnicodeStringEncoding;//NSWindowsCP1251StringEncoding;
        CHCSVParser *csv = [[CHCSVParser alloc]initWithInputStream:stream usedEncoding:&encoding delimiter:','];
        csv.sanitizesFields = YES;
        csv.trimsWhitespace = YES;
        csv.recognizesBackslashesAsEscapes = YES;
        csv.recognizesComments = YES;
        csv.delegate = self;
        [csv parse];
    }
    return self;
}

+(NSDictionary*)wineriesAndVarieties{
    return [WinesDatabase instance].wineriesVarieties;
}

+(NSDictionary*)wineriesAndVineyards{
    return [WinesDatabase instance].wineriesVineyards;
}


- (void)parser:(CHCSVParser *)parser didReadField:(NSString *)field atIndex:(NSInteger)fieldIndex{
    switch (fieldIndex) {
        case 0:
            lastKey = field;
            break;
        case 1:
            lastValue = field;
            break;
        case 2:
            if ([field isEqualToString:@"varietal"]) {
                NSArray *wineOCRnames = [self shortNames:lastValue];
                Wine *wine = [[Wine alloc]initWithDisplayName:lastValue recognizedNames:wineOCRnames years:nil];
                [self addObject:wine toDictionary:self.wineriesVarieties byKey:lastKey];
            }
            if ([field isEqualToString:@"vineyard"]) {
                NSArray *yardOCRnames = [self shortNames:lastValue];
                Vineyard *vineyard = [[Vineyard alloc] initWithDisplayName:lastValue recognizedNames:yardOCRnames];
                [self addObject:vineyard toDictionary:self.wineriesVineyards byKey:lastKey];
            }
            break;
        default:
            break;
    }
}

-(void) addObject:(id)object toDictionary:(NSMutableDictionary*)dictionary byKey:(NSString*)key
{
    if(dictionary[key] == nil){
        dictionary[key] = [NSMutableArray arrayWithObject: object];
    }
    else{
        [dictionary[key] addObject: object];
    }
}

- (void)parser:(CHCSVParser *)parser didFailWithError:(NSError *)error{
    NSLog(@"CSV parser failed with error %s",error.localizedDescription.UTF8String);
}

- (void)parser:(CHCSVParser *)parser didEndLine:(NSUInteger)recordNumber{
//    NSLog(@"Ended line %lu",recordNumber);
}

- (void)parserDidBeginDocument:(CHCSVParser *)parser{
}

- (void)parserDidEndDocument:(CHCSVParser *)parser;{
    NSLog(@"CSV parsing finished successfully. Varieties:%lu Vineries:%lu",[self.wineriesVarieties count], [self.wineriesVineyards count]);
}

-(NSArray*)shortNames:(NSString*)longName{
    NSArray *dst = [self cleanUpAndParseWords:@[longName]];
    dst = [self splitLongWords:dst length:WORD_SPLIT_LEN];
    return dst;
}

-(NSArray*)cleanUpAndParseWords:(NSArray*)srcWords{
    NSMutableArray *dstWords = [[NSMutableArray alloc]init];
    
    NSMutableCharacterSet *separators = [NSMutableCharacterSet punctuationCharacterSet];
    [separators formUnionWithCharacterSet:[NSMutableCharacterSet symbolCharacterSet]];
    [separators formUnionWithCharacterSet:[NSMutableCharacterSet decimalDigitCharacterSet]];
    [separators formUnionWithCharacterSet:[NSMutableCharacterSet whitespaceAndNewlineCharacterSet]];
    [separators formUnionWithCharacterSet:[self nonAsciiCharacterSet]];
    
    for (NSString *word in srcWords) {
        NSArray* filteredWords = [[word componentsSeparatedByCharactersInSet:separators] filteredArrayUsingPredicate:
                                  [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
            return [(NSString*) evaluatedObject length] > 1;//skip empty and short words
        }]];
        
        [dstWords addObjectsFromArray: filteredWords ];
    }
    
    return dstWords;
}
-(NSCharacterSet*)nonAsciiCharacterSet{
    NSMutableString *asciiCharacters = [NSMutableString string];
    for (NSInteger i = 32; i < 127; i++)  {
        [asciiCharacters appendFormat:@"%c", (char)i];
    }
    return [[NSCharacterSet characterSetWithCharactersInString:asciiCharacters] invertedSet];
}


-(NSArray*)splitLongWords:(NSArray*)srcWords length:(NSUInteger)len{
    NSMutableArray *dstWords = [[NSMutableArray alloc]init];
    
    for (NSString *word in srcWords) {
        [dstWords addObject:word];//always add base word
        if(word.length >= len * 1.5){
            NSArray *subWords = [self splitWord:word withWindow:len];
            [dstWords addObjectsFromArray:subWords];
        }
    }
    return dstWords;
}

-(NSArray*)splitWord:(NSString*)word withWindow:(NSUInteger)length{
    NSMutableArray *subwords = [[NSMutableArray alloc]init];
    for (int i=0; i+length < word.length;) {
        NSRange range;
        range.location = i;
        range.length = length;
        [subwords addObject: [word substringWithRange:range] ];
        
        i += length/2;
    }
    return subwords;
}


@end
