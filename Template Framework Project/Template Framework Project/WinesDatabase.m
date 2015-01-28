//
//  WinesDatabase.m
//  Template Framework Project
//
//  Created by Sergey Yuzepovich on 28.01.15.
//  Copyright (c) 2015 Daniele Galiotto - www.g8production.com. All rights reserved.
//

#import "WinesDatabase.h"
#import "CHCSVParser.h"

static NSString* const DB = @"TermListByWinery";

@interface WinesDatabase()<CHCSVParserDelegate>
@property(nonatomic,strong) NSMutableDictionary *wineriesVarieties;
@end

@implementation WinesDatabase
{
    NSString *lastKey;
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
    }
    return self;
}

+(NSDictionary*)winerysAndVarieties{
//    NSFileManager *fileMgr = [NSFileManager defaultManager];
    NSString *dbPath = [[NSBundle mainBundle] pathForResource:DB ofType:@"csv"];
    
    NSInputStream *stream = [NSInputStream inputStreamWithURL:[NSURL fileURLWithPath:dbPath]];
    NSStringEncoding encoding = NSWindowsCP1251StringEncoding;
    CHCSVParser *csv = [[CHCSVParser alloc]initWithInputStream:stream usedEncoding:&encoding delimiter:','];
    csv.sanitizesFields = YES;
    csv.trimsWhitespace = YES;
    csv.recognizesBackslashesAsEscapes = YES;
    csv.recognizesComments = YES;
    csv.delegate = [WinesDatabase instance];
    [csv parse];

    return [WinesDatabase instance].wineriesVarieties;
}


- (void)parser:(CHCSVParser *)parser didReadField:(NSString *)field atIndex:(NSInteger)fieldIndex{
    switch (fieldIndex) {
        case 0:
            lastKey = field;
            break;
        case 1:
            if(self.wineriesVarieties[lastKey] == nil){
                self.wineriesVarieties[lastKey] = [NSMutableArray arrayWithObject: field];
            }
            else{
                [self.wineriesVarieties[lastKey] addObject: field];
            }
            break;
        default:
            break;
    }
}

- (void)parser:(CHCSVParser *)parser didFailWithError:(NSError *)error{
    NSLog(@"CSV parser failed with error %s",error.localizedDescription.UTF8String);
}

- (void)parser:(CHCSVParser *)parser didEndLine:(NSUInteger)recordNumber{
}

- (void)parserDidBeginDocument:(CHCSVParser *)parser{
}
- (void)parserDidEndDocument:(CHCSVParser *)parser;{
    NSLog(@"CSV parsing finished successfully. %lu fields collected",[self.wineriesVarieties count]);
}


@end
