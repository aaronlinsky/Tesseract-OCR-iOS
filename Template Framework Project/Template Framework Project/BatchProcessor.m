//
//  BatchProcessor.m
//  Template Framework Project
//
//  Created by Sergey Yuzepovich on 06.02.15.
//  Copyright (c) 2015 Daniele Galiotto - www.g8production.com. All rights reserved.
//

#import "BatchProcessor.h"

@implementation Metrics
@end

@implementation ImageInfo

-(NSString*)description{
    return [NSString stringWithFormat:@"%@ %@  %@  %@ %@",
            self.winery,
            [[self.acceptedYears valueForKey:@"description"]componentsJoinedByString: @" " ],
            [[self.acceptedVarieties valueForKey:@"description"]componentsJoinedByString: @" " ],
            [[self.acceptedVineyards valueForKey:@"description"]componentsJoinedByString: @" " ],
            [[self.acceptedSubregions valueForKey:@"description"]componentsJoinedByString: @" " ]];
}

@end

@implementation BatchProcessor

-(Metrics*)processImages:(NSArray*)imageNames withInfos:(NSArray*)imagesInfos completion:(void(^)(UIImage *img, ImageInfo *recognizedInfo))imageCompletionBlock{
    
    Metrics *metrics = [[Metrics alloc]init];
    for (NSString *path in imageNames) {
        UIImage *image = [UIImage imageNamed:path];
        //TODO: process image
        //TODO: calculate recognized Info
        //TODO: update metrics
        if (imageCompletionBlock != nil) {
            imageCompletionBlock(image,nil);//TODO: pass recognized info
        }
    }
    return metrics;
}

@end
