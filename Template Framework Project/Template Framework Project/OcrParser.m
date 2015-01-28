//
//  OcrParser.m
//  Template Framework Project
//
//  Created by Sergey Yuzepovich on 22.01.15.
//  Copyright (c) 2015 Daniele Galiotto - www.g8production.com. All rights reserved.
//

#import "OcrParser.h"
#import "NSString+Levenshtein.h"
#import "Wine.h"
#import "WineDictionary.h"
#import "WinesDatabase.h"

static NSUInteger const MAX_VARIETY_DISTANCE = 2;
static NSUInteger const MAX_YEAR_DISTANCE = 1;

@interface OcrParser()
@property(nonatomic,strong) NSDictionary* wines;//with vuforia
@property(nonatomic,strong) NSDictionary* wines2;//without vuforia
@end

@implementation OcrParser

+(instancetype)instance{
    static id instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[OcrParser alloc]init];
    });
    
    return instance;
}

-(instancetype)init{
    self = [super init];
    if(self){
        WineDictionary *mira_wd = [[WineDictionary alloc]init];
        [mira_wd insert:[[Wine alloc]
                         initWithDisplayName:@"Pinot Noir"
                         recognizedNames:@[@"PINOT",@"NOIR"]
                         years:@[@"2010",@"2011"]]];
        
        [mira_wd insert:[[Wine alloc]
                         initWithDisplayName:@"Cabernet Sauvignon"
                         recognizedNames:@[@"CABERNET",@"SAUVIGNON",@"CABER",@"ERNET",@"SAUVI",@"IGNON",@"BERN",@"UVIGN"]
                         years:@[@"2009", @"2010", @"2011"]]];
        
        [mira_wd insert:[[Wine alloc]
                         initWithDisplayName:@"Chardonnay"
                         recognizedNames:@[@"CHARDONNAY",@"CHARD",@"ONNAY",@"ARDON"]
                         years:@[@"2010", @"2011", @"2012"]]];
        
        [mira_wd insert:[[Wine alloc]
                         initWithDisplayName:@"Syrah"
                         recognizedNames:@[@"SYRAH"]
                         years:@[@"2009", @"2010"]]];
        
        self.wines = @{@"mira": mira_wd};
//        self.wines2 = [WinesDatabase winerysAndVarieties];
    }
    return self;
}

+(BOOL)parseWine:(NSString*)wineFamily ocrString:(NSString*)text toYear:(NSString**)year andVariety:(NSString**)variety{
    *year = *variety = @"???";
    
    if ([text length] < 10)
        return NO;
    
    WineDictionary *wineVarietiesAndYears = [OcrParser instance].wines[wineFamily];
    if(wineVarietiesAndYears == nil)
        return NO;

    NSArray *rows = [text componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *oneLine = [rows componentsJoinedByString:@""];
    
    //first pass: trying to match substring exactly
    NSString *exactMatch;
    BOOL exact = [[OcrParser instance] exactMatchInString:oneLine inArray:wineVarietiesAndYears.allKeys match:&exactMatch];
    if(exact){
        NSLog(@"Exact match: %@",exactMatch);
        *variety = [(Wine*)wineVarietiesAndYears[exactMatch] displayName];
        NSArray *years = [(Wine*)wineVarietiesAndYears[exactMatch] years];
        [[OcrParser instance] bestMatchFromArray:years inArray:rows match:year];
        return YES;
    }
    
    //second pass: best Levenshtein distance
    NSString *bestVariety;
    NSUInteger bestDistance = [[OcrParser instance] bestMatchFromArray:wineVarietiesAndYears.allKeys inArray:rows match:&bestVariety];

    if(bestDistance < MAX_VARIETY_DISTANCE){
        NSLog(@"Levenshtein: %@",bestVariety);

        NSArray *years = [(Wine*)wineVarietiesAndYears[bestVariety] years];

        NSString *bestYear;
        bestDistance = [[OcrParser instance] bestMatchFromArray:years inArray:rows match:&bestYear];

        if(bestDistance < MAX_YEAR_DISTANCE){
            *variety = [(Wine*)wineVarietiesAndYears[bestVariety] displayName];
            *year = bestYear;
            return YES;
        }
    }
    
    return NO;
}

//WARNING! This method is still in "work in progress" state.
+(BOOL)parseUnknownWine:(NSString*)ocrText toYear:(NSString**)year andVariety:(NSString**)variety{
    
    NSArray *rows = [ocrText componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *oneLine = [rows componentsJoinedByString:@""];

    //attempt to find winery
    NSString *exactMatch;
    BOOL exact = [[OcrParser instance] exactMatchInString:oneLine inArray:[OcrParser instance].wines2.allKeys match:&exactMatch];
    if (exact) {//found winery exactly
        //iterate all winery's wines and return best one
        //TODO: code here
    }

    //for each entry in array search for best match (Levenshtein) in ocrText
    //if best match is better than threshold - return it
    return NO;
}

-(BOOL) exactMatchInString:(NSString*)text inArray:(NSArray*)candidates match:(NSString**)match{
    for (NSString* c in candidates) {
        if ([text rangeOfString:c options:NSCaseInsensitiveSearch].location != NSNotFound) {
            *match = c;
            return YES;
        }
    }
    return NO;
}

-(NSUInteger) bestMatchFromArray:(NSArray*)arr1 inArray:(NSArray*)arr2 match:(NSString**)bestMatchedString{
    NSUInteger bestDistance = UINT32_MAX;
    for (NSString *a1 in arr1) {
        for (NSString* a2 in arr2) {
            NSUInteger curDistance = [a1 levenshteinDistanceToString:a2];
            if(curDistance < bestDistance){
                bestDistance = curDistance;
                *bestMatchedString = a1;
            }
        }
    }
    
    return bestDistance;
}

@end
