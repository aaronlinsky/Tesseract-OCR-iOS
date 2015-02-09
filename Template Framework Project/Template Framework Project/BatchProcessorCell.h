//
//  BatchProcessorCell.h
//  Template Framework Project
//
//  Created by Sergey Yuzepovich on 06.02.15.
//  Copyright (c) 2015 Daniele Galiotto - www.g8production.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BatchProcessorCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *imageInfo;
@property (weak, nonatomic) IBOutlet UILabel *ocrInfo;
@end
