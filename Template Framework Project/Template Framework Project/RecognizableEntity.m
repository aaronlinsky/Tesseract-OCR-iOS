//
//  RecognizableEntity.m
//  Template Framework Project
//
//  Created by Sergey Yuzepovich on 30.01.15.
//  Copyright (c) 2015 Daniele Galiotto - www.g8production.com. All rights reserved.
//

#import "RecognizableEntity.h"

@implementation RecognizableEntity

-(instancetype)initWithDisplayName:(NSString*)display recognizedNames:(NSArray*)recognized
{
    self = [super init];
    if(self){
        _displayName = display;
        _recognizedNames = recognized;
    }
    return self;
}

@end
