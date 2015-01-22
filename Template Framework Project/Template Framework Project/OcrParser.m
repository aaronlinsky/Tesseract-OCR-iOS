//
//  OcrParser.m
//  Template Framework Project
//
//  Created by Sergey Yuzepovich on 22.01.15.
//  Copyright (c) 2015 Daniele Galiotto - www.g8production.com. All rights reserved.
//

#import "OcrParser.h"

@implementation OcrParser

+(BOOL)parseString:(NSString*)text toYear:(NSString**)year andVariety:(NSString**)variety
{
    *year = arc4random_uniform(100) < 10 ? @"???" : @"1234";
    *variety = arc4random_uniform(100) < 10 ? @"???" : @"Tasty";
    return YES;
}

@end
