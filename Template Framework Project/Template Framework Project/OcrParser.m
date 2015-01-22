//
//  OcrParser.m
//  Template Framework Project
//
//  Created by Sergey Yuzepovich on 22.01.15.
//  Copyright (c) 2015 Daniele Galiotto - www.g8production.com. All rights reserved.
//

#import "OcrParser.h"
#import "NSString+Levenshtein.h"

//static NSUInteger const MAX_VARIETY_DISTANCE = 4;
//static NSUInteger const MAX_YEAR_DISTANCE = 1;

@interface OcrParser()
@property(nonatomic,strong) NSDictionary* wines;
@end

@implementation OcrParser

+(instancetype)instance
{
    static id instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[OcrParser alloc]init];
    });
    
    return instance;
}

-(instancetype)init
{
    self = [super init];
    if(self)
    {
        self.wines =
                    @{@"mira"       :   @{@"PINOT" : @[ @"2010", @"2011" ],
                                          @"CABERNET" : @[ @"2009", @"2010", @"2011" ],
                                          @"CHARDONNAY" : @[ @"2010", @"2011", @"2012" ],
                                          @"SYRAH" : @[ @"2009", @"2010" ]},
                      
                      @"not-mira"   :   @{@"test" : @[ @"1234" ] }};
    }
    return self;
}

+(BOOL)parseWine:(NSString*)wineFamily ocrString:(NSString*)text toYear:(NSString**)year andVariety:(NSString**)variety
{
    *year = *variety = @"???";
    
    if ([text length] < 10)
        return NO;
    
    NSDictionary* wineVarietiesAndYears = [OcrParser instance].wines[wineFamily];
    if(wineVarietiesAndYears == nil)
        return NO;

//    NSArray *rows = [text componentsSeparatedByString:@"\n"];
    NSArray *rows = [text componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    NSString *bestVariety;
    NSUInteger bestDistance = [[OcrParser instance] bestMatchFromArray:wineVarietiesAndYears.allKeys inArray:rows match:&bestVariety];

    if(bestDistance < [bestVariety length]/2+1){

        NSString *bestYear;
        bestDistance = [[OcrParser instance] bestMatchFromArray:wineVarietiesAndYears[bestVariety] inArray:rows match:&bestYear];

        if(bestDistance < [bestYear length]/2+1){
            *variety = bestVariety;
            *year = bestYear;
        }
    }
    
    return YES;
}

-(NSUInteger) bestMatchFromArray:(NSArray*)arr1 inArray:(NSArray*)arr2 match:(NSString**)bestMatchedString
{
    NSUInteger bestDistance = UINT32_MAX;
    NSString* bestMatch;
    for (NSString *a1 in arr1) {
        for (NSString* a2 in arr2) {
            NSUInteger curDistance = [a1 levenshteinDistanceToString:a2];
            if(curDistance < bestDistance){
                bestDistance = curDistance;
                bestMatch = a1;
            }
        }
    }
    
    *bestMatchedString = bestMatch;
    return bestDistance;
}

@end
