//
//  ArrayTransformer.m
//  tipsi
//
//  Created by Sergey Yuzepovich on 19.02.15.
//  Copyright (c) 2015 tipsi. All rights reserved.
//

#import "ArrayTransformer.h"

@implementation ArrayTransformer

+ (Class)transformedValueClass
{
    return [NSArray class];
}

+ (BOOL)allowsReverseTransformation
{
    return YES;
}

- (id)transformedValue:(id)value
{
    return [NSKeyedArchiver archivedDataWithRootObject:value];
}

- (id)reverseTransformedValue:(id)value
{
    return [NSKeyedUnarchiver unarchiveObjectWithData:value];
}

@end