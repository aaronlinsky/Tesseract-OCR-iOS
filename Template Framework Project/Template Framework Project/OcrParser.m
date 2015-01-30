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
#import "Vineyard.h"
#import "RecognizableEntity.h"
#import "WinesDatabase.h"

#define vintages  @[@"1980",@"1981",@"1982",@"1983",@"1984",@"1985",@"1986",@"1987",@"1988",@"1989",@"1990",@"1991",@"1992",@"1993",@"1994",@"1995",@"1996",@"1997",@"1998",@"1999",@"2000",@"2001",@"2002",@"2003",@"2004",@"2005",@"2006",@"2007",@"2008",@"2009",@"2010",@"2011",@"2012",@"2013",@"2014",@"2015",@"2016",@"2017",@"2018",@"2019",@"2020"]

static NSUInteger const MAX_VARIETY_DISTANCE = 1;
static NSUInteger const MAX_YEAR_DISTANCE = 1;

@interface OcrParser()
@property(nonatomic,strong) NSDictionary* wines;
@property(nonatomic,strong) NSDictionary* vineyards;
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
        self.wines = [WinesDatabase wineriesAndVarieties];
        self.vineyards = [WinesDatabase wineriesAndVineyards];
    }
    return self;
}

+(BOOL)parseWine:(NSString*)wineFamily ocrString:(NSString*)text toYear:(NSString**)year variety:(NSString**)variety vineyard:(NSString**)vineyard{
    *year = *variety = *vineyard = @"???";
    
    if ([text length] < 10)
        return NO;
    
    NSArray *wineVarieties = [OcrParser instance].wines[wineFamily];
    NSArray *wineVineyards = [OcrParser instance].vineyards[wineFamily];
    if(wineVarieties == nil && wineVineyards == nil)//specified winery not present
        return NO;

    NSArray *rows = [text componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    //variety match
    Wine *varietyMatch = (Wine*)[OcrParser searchStringArray:rows withEntitiesArray:wineVarieties];
    if (varietyMatch) {
        *variety = varietyMatch.displayName;
    }
    
    //year (Levenshtein-only) match
    NSString *bestYear;
    NSUInteger bestYearDistance = [[OcrParser instance] bestMatchFromArray:vintages inArray:rows match:&bestYear];
    if(bestYearDistance <= MAX_YEAR_DISTANCE){
        *year = bestYear;
    }

    //vineyard match
    Vineyard *vineyardMatch = (Vineyard*)[OcrParser searchStringArray:rows withEntitiesArray:wineVineyards];
    if(vineyardMatch){
        *vineyard = vineyardMatch.displayName;
    }
    
    if(*year && (varietyMatch || vineyardMatch) )
        return YES;
    
    return NO;
}

+(RecognizableEntity*)searchStringArray:(NSArray*)src withEntitiesArray:(NSArray*)patterns{
    NSString *oneLine = [src componentsJoinedByString:@""];
    
    //first pass: trying to match substring exactly
    for (RecognizableEntity *entity in patterns) {
        NSString *exactMatch;
        BOOL exact = [[OcrParser instance] exactMatchInString:oneLine inArray:entity.recognizedNames match:&exactMatch];
        if(exact){
            NSLog(@"Exact match: %@",exactMatch);
            return entity;
        }
    }
    
    //second pass: best Levenshtein distance
    RecognizableEntity *bestMatchEntity;
    NSString *bestMatch;//debugging purposes only
    NSUInteger bestDistance = UINT32_MAX;
    for (RecognizableEntity *entity in patterns) {
        NSUInteger distance = [[OcrParser instance] bestMatchFromArray:entity.recognizedNames inArray:src match:&bestMatch];
        if(distance < bestDistance){
            bestDistance = distance;
            bestMatchEntity = entity;
        }
    }
    if(bestDistance <= MAX_VARIETY_DISTANCE){
        NSLog(@"Levenshtein(%lu): %@",bestDistance,bestMatch);
        return bestMatchEntity;
    }

    return nil;
}

//WARNING! This method is still in "work in progress" state.
+(BOOL)parseUnknownWine:(NSString*)ocrText toYear:(NSString**)year andVariety:(NSString**)variety{
    
    NSArray *rows = [ocrText componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *oneLine = [rows componentsJoinedByString:@""];

    //attempt to find winery
    NSString *exactMatch;
    BOOL exact = [[OcrParser instance] exactMatchInString:oneLine inArray:[OcrParser instance].wines.allKeys match:&exactMatch];
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
