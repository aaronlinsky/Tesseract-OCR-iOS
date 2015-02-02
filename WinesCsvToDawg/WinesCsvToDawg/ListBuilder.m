//
//  ListBuilder.m
//  WinesCsvToDawg
//
//  Created by Sergey Yuzepovich on 27.01.15.
//  Copyright (c) 2015 Sergey Yuzepovich. All rights reserved.
//

#import "ListBuilder.h"

@implementation ListBuilder

+(void)buildListOfDictionaryWords:(NSArray*)words includeYears:(NSRange)years splitLongWords:(NSUInteger)splitLength{

    if (words != nil && [words count] != 0) {
        words = [ListBuilder cleanUpAndParseWords:words];
    }
    
    if(splitLength > 0){
        words = [ListBuilder splitLongWords:words length:splitLength];
    }
    
    if(years.location != 0 && years.length != 0){
        words = [ListBuilder addYears:years toWords:words];
    }
    
    words = [ListBuilder removeDuplicates:words];
    
    [ListBuilder writeToFile:words];
}

+(NSArray*)cleanUpAndParseWords:(NSArray*)srcWords{
    NSMutableArray *dstWords = [[NSMutableArray alloc]init];
    
    NSMutableCharacterSet *separators = [NSMutableCharacterSet punctuationCharacterSet];
    [separators formUnionWithCharacterSet:[NSMutableCharacterSet symbolCharacterSet]];
    [separators formUnionWithCharacterSet:[NSMutableCharacterSet decimalDigitCharacterSet]];
    [separators formUnionWithCharacterSet:[NSMutableCharacterSet whitespaceAndNewlineCharacterSet]];
    [separators formUnionWithCharacterSet:[ListBuilder nonAsciiCharacterSet]];
    
    for (NSString *word in srcWords) {
        NSArray* filteredWords = [[word componentsSeparatedByCharactersInSet:separators] filteredArrayUsingPredicate:
        [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
            return [(NSString*) evaluatedObject length] > 1;//skip empty and short words
        }]];

        [dstWords addObjectsFromArray: filteredWords ];
    }
    
    return dstWords;
}

+(NSCharacterSet*)nonAsciiCharacterSet
{
    NSMutableString *asciiCharacters = [NSMutableString string];
    for (NSInteger i = 32; i < 127; i++)  {
        [asciiCharacters appendFormat:@"%c", (char)i];
    }
    return [[NSCharacterSet characterSetWithCharactersInString:asciiCharacters] invertedSet];
}

+(NSArray*)splitLongWords:(NSArray*)srcWords length:(NSUInteger)len{
    NSMutableArray *dstWords = [[NSMutableArray alloc]init];
    
    for (NSString *word in srcWords) {
        [dstWords addObject:word];//always add base word
        if(word.length >= len * 1.5){
            NSArray *subWords = [ListBuilder splitWord:word withWindow:len];
            [dstWords addObjectsFromArray:subWords];
        }
    }
    return dstWords;
}

+(NSArray*)splitWord:(NSString*)word withWindow:(NSUInteger)length{
    
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

+(NSArray*)addYears:(NSRange)yearsRange toWords:(NSArray*)srcWords{
    NSMutableArray *dstWords = [[NSMutableArray alloc]initWithArray:srcWords];
    for (NSUInteger i=yearsRange.location; i<=yearsRange.length+yearsRange.location; i++) {
        [dstWords addObject:[NSString stringWithFormat:@"%lu",i]];
    }
    
    return dstWords;
}

+(NSArray*)removeDuplicates:(NSArray*)srcWords{
    NSOrderedSet *set = [NSOrderedSet orderedSetWithArray:srcWords];
    return set.array;
}

+(void)writeToFile:(NSArray*)words{
    NSString *stringToWrite=[[NSString alloc]init];
    
    for (NSString* w in words){
        stringToWrite=[stringToWrite stringByAppendingString: [w stringByAppendingString:@"\n"] ];
    }
    
    [stringToWrite writeToFile:(NSString*)outputWordsFilePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    NSLog(@"Written %lu words to words.list file",words.count);
}
@end
