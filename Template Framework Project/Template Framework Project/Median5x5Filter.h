//
//  Median5x5Filter.h
//  Template Framework Project
//
//  Created by Sergey Yuzepovich on 02.02.15.
//  Copyright (c) 2015 Daniele Galiotto - www.g8production.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GPUImageMedianFilter.h"

@interface Median5x5Filter : GPUImageMedianFilter
- (id)initWithImage:(UIImage*)image;

@end
