//
//  BaseEntity.h
//  Template Framework Project
//
//  Created by Sergey Yuzepovich on 04.02.15.
//  Copyright (c) 2015 Daniele Galiotto - www.g8production.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface BaseEntity : NSManagedObject

@property (nonatomic, retain) NSString * displayName;
@property (nonatomic, retain) NSOrderedSet *recognizedNames;
@end

@interface BaseEntity (CoreDataGeneratedAccessors)

- (void)insertObject:(NSManagedObject *)value inRecognizedNamesAtIndex:(NSUInteger)idx;
- (void)removeObjectFromRecognizedNamesAtIndex:(NSUInteger)idx;
- (void)insertRecognizedNames:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeRecognizedNamesAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInRecognizedNamesAtIndex:(NSUInteger)idx withObject:(NSManagedObject *)value;
- (void)replaceRecognizedNamesAtIndexes:(NSIndexSet *)indexes withRecognizedNames:(NSArray *)values;
- (void)addRecognizedNamesObject:(NSManagedObject *)value;
- (void)removeRecognizedNamesObject:(NSManagedObject *)value;
- (void)addRecognizedNames:(NSOrderedSet *)values;
- (void)removeRecognizedNames:(NSOrderedSet *)values;
@end
