//
//  WineDictionary.m
//  Template Framework Project
//
//  Created by Sergey Yuzepovich on 23.01.15.
//  Copyright (c) 2015 Daniele Galiotto - www.g8production.com. All rights reserved.
//

#import "WineDictionary.h"
#import "Wine.h"

@implementation WineDictionary
{
    NSMutableDictionary *wines;
}

-(instancetype)init
{
    self = [super init];
    if(self)
    {
        wines = [[NSMutableDictionary alloc]init];
    }
    
    return self;
}


-(void)insert:(Wine*)wine
{
    for (NSString *name in wine.recognizedNames) {
        if( wines[name] == nil){
            [wines setObject:wine forKey:name];
        }
        else{
            [[NSException exceptionWithName:@"Duplicate key" reason:[NSString stringWithFormat: @"Key %@ already exists",name ]  userInfo:nil] raise];
        }
    }
}

-(NSArray*)allKeys
{
    return wines.allKeys;
}

- (id)objectForKeyedSubscript:(id <NSCopying>)key
{
    return wines[key];
}

- (void)setObject:(id)obj forKeyedSubscript:(id <NSCopying>)key
{
    wines[key] = obj;
}



@end
