//
//  OcrParser.h
//  Template Framework Project
//
//  Created by Sergey Yuzepovich on 22.01.15.
//  Copyright (c) 2015 Daniele Galiotto - www.g8production.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OcrParser : NSObject

+(BOOL)parseString:(NSString*)text toYear:(NSString**)year andVariety:(NSString**)variety;

@end
