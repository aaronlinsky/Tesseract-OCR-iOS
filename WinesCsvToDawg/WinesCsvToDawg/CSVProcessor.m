//
//  CsvToList.m
//  WinesCsvToDawg
//
//  Created by Sergey Yuzepovich on 27.01.15.
//  Copyright (c) 2015 Sergey Yuzepovich. All rights reserved.
//

#import "CSVProcessor.h"
#import "CHCSVParser.h"

@interface CSVProcessor() <CHCSVParserDelegate>
@property(nonatomic,strong) NSMutableOrderedSet *fields;
@property(nonatomic)        BOOL filterDigits;
@property(nonatomic)        BOOL filterSpecial;
@end

@implementation CSVProcessor

+(instancetype) instance{
    static id instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[CSVProcessor alloc]init];
    });
    return instance;
}

-(instancetype)init{
    self = [super init];
    if(self){
        _fields = [[NSMutableOrderedSet alloc]init];
    }
    return self;
}

+(NSArray*)csv:(NSString*)path filteringNumbers:(BOOL)filterNums filteringSpecialChars:(BOOL) filterSpecs{
    [CSVProcessor instance].filterDigits = filterNums;
    [CSVProcessor instance].filterSpecial = filterSpecs;
    
    NSInputStream *stream = [NSInputStream inputStreamWithURL:[NSURL fileURLWithPath:path]];
    NSStringEncoding encoding = NSWindowsCP1251StringEncoding;
    CHCSVParser *csv = [[CHCSVParser alloc]initWithInputStream:stream usedEncoding:&encoding delimiter:','];
    csv.sanitizesFields = YES;
    csv.trimsWhitespace = YES;
    csv.recognizesBackslashesAsEscapes = YES;
    csv.recognizesComments = YES;
    csv.delegate = [CSVProcessor instance];
    [csv parse];
    
    return [[CSVProcessor instance].fields array];
}


- (void)parser:(CHCSVParser *)parser didReadField:(NSString *)field atIndex:(NSInteger)fieldIndex{
    if([field integerValue] == 0){//skipping integers
        if(![_fields containsObject:field]){//skipping dupes
            [_fields addObject:field];
        }
//        else{
//            NSLog(@"Dupe: %@",field);
//        }
    }
}

- (void)parser:(CHCSVParser *)parser didFailWithError:(NSError *)error{
    NSLog(@"CSV parser failed with error %s",error.localizedDescription.UTF8String);
    exit(1);
}

- (void)parser:(CHCSVParser *)parser didEndLine:(NSUInteger)recordNumber{
}

- (void)parserDidBeginDocument:(CHCSVParser *)parser{
}
- (void)parserDidEndDocument:(CHCSVParser *)parser;{
    NSLog(@"CSV parsing finished successfully. %lu fields collected",[self.fields count]);
}

@end
