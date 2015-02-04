//
//  Template Framework Project.h
//  Template Framework Project
//
//  Created by Sergey Yuzepovich on 04.02.15.
//  Copyright (c) 2015 Daniele Galiotto - www.g8production.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface DictionariesEntity : NSManagedObject

@property (nonatomic, retain) id varieties;
@property (nonatomic, retain) id vineyards;
@property (nonatomic, retain) id subregions;

@end
