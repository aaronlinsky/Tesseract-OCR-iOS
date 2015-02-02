//
//  CsvToList.h
//  WinesCsvToDawg
//
//  Created by Sergey Yuzepovich on 27.01.15.
//  Copyright (c) 2015 Sergey Yuzepovich. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface CSVProcessor : NSObject

+(NSArray*)csv:(NSString*)path filteringNumbers:(BOOL)filterNums filteringSpecialChars:(BOOL) filterSpecs;

@end
