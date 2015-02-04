//
//  RecognizableEntity.m
//  Template Framework Project
//
//  Created by Sergey Yuzepovich on 30.01.15.
//  Copyright (c) 2015 Daniele Galiotto - www.g8production.com. All rights reserved.
//

#import "RecognizableEntity.h"

static NSUInteger const WORD_SPLIT_LEN = 5;

@implementation RecognizableEntity

-(instancetype)initWithDisplayName:(NSString*)display recognizedNames:(NSArray*)recognized{
    self = [super init];
    if(self){
        _displayName = display;
        _recognizedNames = recognized;
    }
    return self;
}

-(instancetype)initWithDisplayName:(NSString*)display{
    self = [super init];
    if(self){
        _displayName = display;
        _recognizedNames = [self shortNames:display];
    }
    return self;
}

-(NSArray*)shortNames:(NSString*)longName{
    NSComparisonResult (^stringsLenLongFirstComparator)(id obj1, id obj2) =
    ^NSComparisonResult(id obj1, id obj2) {
        if([obj1 length] < [obj2 length]){
            return NSOrderedDescending;
        }
        if([obj1 length] == [obj2 length]){
            return NSOrderedSame;
        }
        return NSOrderedAscending;
    };

    NSArray *dst = [self cleanUpAndParseWords:@[longName]];
    dst = [self splitLongWords:dst length:WORD_SPLIT_LEN];
    return [dst sortedArrayUsingComparator:stringsLenLongFirstComparator];
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
            return [(NSString*) evaluatedObject length] > 3;//skip empty and short words
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
