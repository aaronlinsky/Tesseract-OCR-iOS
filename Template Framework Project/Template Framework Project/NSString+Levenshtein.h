//
//  NSString+Levenstein.h
//  Template Framework Project
//
//  Created by Sergey Yuzepovich on 22.01.15.
//  Copyright (c) 2015 Daniele Galiotto - www.g8production.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (levenshteinDistance)
- (NSUInteger)levenshteinDistanceToString:(NSString *)string;
@end
