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
#import "Subregion.h"

static NSString* const DB = @"TermListByWinery";//@"TermListByWineryNewWorldOnly";

@interface WinesDatabase()<CHCSVParserDelegate>
@property(nonatomic,strong) NSMutableDictionary *wineriesVarieties;
@property(nonatomic,strong) NSMutableDictionary *wineriesVineyards;
@property(nonatomic,strong) NSMutableDictionary *wineriesSubregions;
@end

@implementation WinesDatabase
{
    NSString *lastKey;
    NSString *lastValue;
    NSUInteger lastLine;
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
        _wineriesSubregions= [[NSMutableDictionary alloc]init];
        
        NSString *dbPath = [[NSBundle mainBundle] pathForResource:DB ofType:@"csv"];
        NSInputStream *stream = [NSInputStream inputStreamWithURL:[NSURL fileURLWithPath:dbPath]];
        NSStringEncoding encoding=0;//NSWindowsCP1251StringEncoding;//NSUnicodeStringEncoding;
        CHCSVParser *csv = [[CHCSVParser alloc]initWithInputStream:stream usedEncoding:&encoding delimiter:','];
//        CHCSVParser *csv = [[CHCSVParser alloc]initWithContentsOfCSVFile:dbPath];
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

+(NSDictionary*)wineriesAndSubregions{
    return [WinesDatabase instance].wineriesSubregions;
}


- (void)parser:(CHCSVParser *)parser didReadField:(NSString *)field atIndex:(NSInteger)fieldIndex{
    field = [field  stringByTrimmingCharactersInSet: [NSMutableCharacterSet whitespaceAndNewlineCharacterSet]];
    
    switch (fieldIndex) {
        case 0:
            lastKey = field;
            break;
        case 1:
            lastValue = field;
            break;
        case 2:
            if ([field isEqualToString:@"varietal"]) {
                Wine *wine = [[Wine alloc]initWithDisplayName:lastValue];
                [self addObject:wine toDictionary:self.wineriesVarieties byKey:lastKey];
            }
            if ([field isEqualToString:@"vineyard"]) {
                Vineyard *vineyard = [[Vineyard alloc]initWithDisplayName:lastValue];
                [self addObject:vineyard toDictionary:self.wineriesVineyards byKey:lastKey];
            }
            if ([field isEqualToString:@"subregion"]) {
                Subregion *subregion = [[Subregion alloc]initWithDisplayName:lastValue];
                [self addObject:subregion toDictionary:self.wineriesSubregions byKey:lastKey];
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
    lastLine = recordNumber;
}

- (void)parserDidBeginDocument:(CHCSVParser *)parser{
}

- (void)parserDidEndDocument:(CHCSVParser *)parser;{
    NSLog(@"CSV parsing done. Vars:%lu Vins:%lu Subrs:%lu. Lines:%lu",[self.wineriesVarieties count], [self.wineriesVineyards count],[self.wineriesSubregions count],lastLine);
}



@end
