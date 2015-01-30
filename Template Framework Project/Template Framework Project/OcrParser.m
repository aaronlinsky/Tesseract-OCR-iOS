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
#import "WinesDatabase.h"

#define vintages  @[@"1980",@"1981",@"1982",@"1983",@"1984",@"1985",@"1986",@"1987",@"1988",@"1989",@"1990",@"1991",@"1992",@"1993",@"1994",@"1995",@"1996",@"1997",@"1998",@"1999",@"2000",@"2001",@"2002",@"2003",@"2004",@"2005",@"2006",@"2007",@"2008",@"2009",@"2010",@"2011",@"2012",@"2013",@"2014",@"2015",@"2016",@"2017",@"2018",@"2019",@"2020"];

static NSUInteger const MAX_VARIETY_DISTANCE = 2;
static NSUInteger const MAX_YEAR_DISTANCE = 1;

@interface OcrParser()
//@property(nonatomic,strong) NSDictionary* wines;//with vuforia
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
//        WineDictionary *mira_wd = [[WineDictionary alloc]init];
//        [mira_wd insert:[[Wine alloc]
//                         initWithDisplayName:@"Pinot Noir"
//                         recognizedNames:@[@"PINOT",@"NOIR"]
//                         years:@[@"2010",@"2011"]]];
//        
//        [mira_wd insert:[[Wine alloc]
//                         initWithDisplayName:@"Cabernet Sauvignon"
//                         recognizedNames:@[@"CABERNET",@"SAUVIGNON",@"CABER",@"ERNET",@"SAUVI",@"IGNON",@"BERN",@"UVIGN"]
//                         years:@[@"2009", @"2010", @"2011"]]];
//        
//        [mira_wd insert:[[Wine alloc]
//                         initWithDisplayName:@"Chardonnay"
//                         recognizedNames:@[@"CHARDONNAY",@"CHARD",@"ONNAY",@"ARDON"]
//                         years:@[@"2010", @"2011", @"2012"]]];
//        
//        [mira_wd insert:[[Wine alloc]
//                         initWithDisplayName:@"Syrah"
//                         recognizedNames:@[@"SYRAH"]
//                         years:@[@"2009", @"2010"]]];
//        
//        self.wines = @{@"mira": mira_wd};
        self.wines2 = [WinesDatabase wineriesAndVarieties];
    }
    return self;
}

+(BOOL)parseWine:(NSString*)wineFamily ocrString:(NSString*)text toYear:(NSString**)year andVariety:(NSString**)variety{
    *year = *variety = @"???";
    
    if ([text length] < 10)
        return NO;
    
    NSArray *wineVarieties = [OcrParser instance].wines2[wineFamily];
    if(wineVarieties == nil)//specified winery not present
        return NO;

    NSArray *rows = [text componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *oneLine = [rows componentsJoinedByString:@""];
    
    //first pass: trying to match substring exactly
    for (Wine *wine in wineVarieties) {
        
        NSString *exactMatch;
        BOOL exact = [[OcrParser instance] exactMatchInString:oneLine inArray:wine.recognizedNames match:&exactMatch];
        if(exact){
            NSLog(@"Exact match: %@",exactMatch);
            *variety = wine.displayName;
            NSArray *years = wine.years != nil ? wine.years : vintages;
            [[OcrParser instance] bestMatchFromArray:years inArray:rows match:year];
            return YES;
        }
    }
    
    //second pass: best Levenshtein distance
    for (Wine *wine in wineVarieties) {

        NSString *bestVariety;
        NSUInteger bestDistance = [[OcrParser instance] bestMatchFromArray:wine.recognizedNames inArray:rows match:&bestVariety];

        if(bestDistance <= MAX_VARIETY_DISTANCE){
            NSLog(@"Levenshtein(%lu): %@",bestDistance,bestVariety);

            NSArray *years = wine.years != nil ? wine.years : vintages;

            NSString *bestYear;
            bestDistance = [[OcrParser instance] bestMatchFromArray:years inArray:rows match:&bestYear];

            if(bestDistance <= MAX_YEAR_DISTANCE){
                *variety = wine.displayName;
                *year = bestYear;
                return YES;
            }
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
