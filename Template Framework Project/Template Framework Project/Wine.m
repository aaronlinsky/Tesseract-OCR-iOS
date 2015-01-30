//
//  Wine.m
//  Template Framework Project
//
//  Created by Sergey Yuzepovich on 23.01.15.
//  Copyright (c) 2015 Daniele Galiotto - www.g8production.com. All rights reserved.
//

#import "Wine.h"

@implementation Wine

-(instancetype)initWithDisplayName:(NSString*)display recognizedNames:(NSArray*)recognized years:(NSArray*)years
{
    self = [super initWithDisplayName:display recognizedNames:recognized];
    if(self){
        _years = years;
    }
    return self;
}

@end
