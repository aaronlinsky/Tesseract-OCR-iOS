//
//  ListBuilder.h
//  WinesCsvToDawg
//
//  Created by Sergey Yuzepovich on 27.01.15.
//  Copyright (c) 2015 Sergey Yuzepovich. All rights reserved.
//

#import <Foundation/Foundation.h>

#define outputWordsFilePath  @"./words.list"

@interface ListBuilder : NSObject

+(void)buildListOfDictionaryWords:(NSArray*)unparsedWords includeYears:(NSRange)years splitLongWords:(NSUInteger)splitLength;

@end
