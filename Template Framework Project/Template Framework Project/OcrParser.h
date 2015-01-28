//
//  OcrParser.h
//  Template Framework Project
//
//  Created by Sergey Yuzepovich on 22.01.15.
//  Copyright (c) 2015 Daniele Galiotto - www.g8production.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OcrParser : NSObject

+(instancetype)instance;
+(BOOL)parseWine:(NSString*)wineFamily  ocrString:(NSString*)text toYear:(NSString**)year andVariety:(NSString**)variety;
+(BOOL)parseUnknownWine:(NSString*)ocrText toYear:(NSString**)year andVariety:(NSString**)variety;

@end
