//
//  BaseEntity+Extensions.h
//  Template Framework Project
//
//  Created by Sergey Yuzepovich on 04.02.15.
//  Copyright (c) 2015 Daniele Galiotto - www.g8production.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BaseEntity.h"

@interface BaseEntity(Extensions)

-(instancetype)initWithDisplayName:(NSString*)display recognizedNames:(NSOrderedSet*)recognized;
+(NSArray*)shortNames:(NSString*)longName;
+(NSOrderedSet*)createShortNamesObjectsFromStringArray:(NSArray*) arr storeToContext:(NSManagedObjectContext*)context;
-(void)createShortNamesObjectsFromDisplayNameAndstoreToContext:(NSManagedObjectContext*)context;

@end
