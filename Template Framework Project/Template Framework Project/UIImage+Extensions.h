//
//  UIImage+Extensions.h
//  tipsi
//
//  Created by Sergey Yuzepovich on 05.02.15.
//  Copyright (c) 2015 tipsi. All rights reserved.
//

#import <Foundation/Foundation.h>

#if !TARGET_IPHONE_SIMULATOR

@interface UIImage(QCAR)
+(UIImage*)imageFromQCARImage:(void*)qcarImage;
@end

#endif

@interface UIImage(Transformations)
-(UIImage *)imageRotatedByDegrees:(CGFloat)degrees;
-(UIImage *)imageScaledBy:(CGFloat)scale;
@end
