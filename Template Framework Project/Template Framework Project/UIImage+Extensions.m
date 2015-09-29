//
//  UIImage+Extensions.m
//  tipsi
//
//  Created by Sergey Yuzepovich on 05.02.15.
//  Copyright (c) 2015 tipsi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIImage+Extensions.h"


#if !TARGET_IPHONE_SIMULATOR
#import <Image.h>
#import <QCAR/QCAR.h>

@implementation UIImage(QCAR)

+(UIImage*)imageFromQCARImage:(void*)qcarImage{
    int width = ((QCAR::Image *)qcarImage)->getWidth();
    int height = ((QCAR::Image *)qcarImage)->getHeight();
    int bitsPerComponent = 8;
    int bitsPerPixel = QCAR::getBitsPerPixel(QCAR::RGB888);
    int bytesPerRow = ((QCAR::Image *)qcarImage)->getBufferWidth() * bitsPerPixel / bitsPerComponent;
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault | kCGImageAlphaNone;
    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
    
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, ((QCAR::Image *)qcarImage)->getPixels(), QCAR::getBufferSize(width, height, QCAR::RGB888), NULL);
    
    CGImageRef imageRef = CGImageCreate(width, height, bitsPerComponent, bitsPerPixel, bytesPerRow, colorSpaceRef, bitmapInfo, provider, NULL, NO, renderingIntent);
//    CGImageRef imageRefRetain = CGImageRetain(imageRef);
    UIImage *image = [UIImage imageWithCGImage:imageRef];
    
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpaceRef);
    CGImageRelease(imageRef);
    
    return image;
}

@end
#endif

@implementation UIImage(Transformations)

- (UIImage *)imageRotatedByDegrees:(CGFloat)degrees{
    //Calculate the size of the rotated view's containing box for our drawing space
    UIView *rotatedViewBox = [[UIView alloc] initWithFrame:CGRectMake(0,0,self.size.width, self.size.height)];
    CGAffineTransform t = CGAffineTransformMakeRotation(degrees * M_PI / 180);
    rotatedViewBox.transform = t;
    CGSize rotatedSize = rotatedViewBox.frame.size;
    
    //Create the bitmap context
    UIGraphicsBeginImageContext(rotatedSize);
    CGContextRef bitmap = UIGraphicsGetCurrentContext();
    
    //Move the origin to the middle of the image so we will rotate and scale around the center.
    CGContextTranslateCTM(bitmap, rotatedSize.width/2, rotatedSize.height/2);
    
    //Rotate the image context
    CGContextRotateCTM(bitmap, (degrees * M_PI / 180));
    
    //Now, draw the rotated/scaled image into the context
    CGContextScaleCTM(bitmap, 1.0, -1.0);
    CGContextDrawImage(bitmap,CGRectMake(-self.size.width/2,-self.size.height/2,self.size.width,self.size.height),[self CGImage]);
    
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

- (UIImage *)imageScaledBy:(CGFloat)scale{
    
    CGSize newSize = CGSizeMake((NSUInteger)self.size.width * scale, (NSUInteger) self.size.height * scale);
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    [self drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

@end
