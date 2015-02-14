//
//  BatchProcessorController.h
//  Template Framework Project
//
//  Created by Sergey Yuzepovich on 06.02.15.
//  Copyright (c) 2015 Daniele Galiotto - www.g8production.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BatchProcessorController : UITableViewController

@property(nonatomic,strong) NSArray *images;
@property(nonatomic,strong) NSArray *imageInfos;
@property(nonatomic,strong) NSMutableArray *ocrResults;


@end
