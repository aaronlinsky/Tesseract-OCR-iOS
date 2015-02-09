//
//  BatchProcessor.h
//  Template Framework Project
//
//  Created by Sergey Yuzepovich on 06.02.15.
//  Copyright (c) 2015 Daniele Galiotto - www.g8production.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Metrics : NSObject
@property CGFloat successPercent;
@property CGFloat partialPercent;
@property CGFloat failPercent;

@property NSUInteger successCount;
@property NSUInteger partialCount;
@property NSUInteger failCount;
@property NSUInteger totalCount;
@end

@interface ImageInfo : NSObject
@property(nonatomic,copy) NSString * winery;
@property(nonatomic,strong) NSArray * acceptedVarieties;
@property(nonatomic,strong) NSArray * acceptedYears;
@property(nonatomic,strong) NSArray * acceptedVineyards;
@property(nonatomic,strong) NSArray * acceptedSubregions;
@end

@interface BatchProcessor : NSObject

-(Metrics*)processImages:(NSArray*)imageNames withInfos:(NSArray*)imagesInfos completion:(void(^)(UIImage *img, ImageInfo *recognizedInfo))imageCompletionBlock;

@end
