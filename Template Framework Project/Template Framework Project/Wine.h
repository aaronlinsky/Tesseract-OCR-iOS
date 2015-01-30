//
//  Wine.h
//  Template Framework Project
//
//  Created by Sergey Yuzepovich on 23.01.15.
//  Copyright (c) 2015 Daniele Galiotto - www.g8production.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RecognizableEntity.h"

@interface Wine : RecognizableEntity

@property(nonatomic,readonly) NSArray   *years;

-(instancetype)initWithDisplayName:(NSString*)display recognizedNames:(NSArray*)recognized years:(NSArray*)years;

@end
