//
//  RecognizableEntity.h
//  Template Framework Project
//
//  Created by Sergey Yuzepovich on 30.01.15.
//  Copyright (c) 2015 Daniele Galiotto - www.g8production.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RecognizableEntity : NSObject <NSCoding>

@property(nonatomic,readonly) NSString  *displayName;
@property(nonatomic,readonly) NSArray   *recognizedNames;

-(instancetype)initWithDisplayName:(NSString*)display recognizedNames:(NSArray*)recognized;
-(instancetype)initWithDisplayName:(NSString*)display;

@end
