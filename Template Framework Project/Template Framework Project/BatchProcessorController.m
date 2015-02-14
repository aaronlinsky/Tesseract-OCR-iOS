//
//  BatchProcessorController.m
//  Template Framework Project
//
//  Created by Sergey Yuzepovich on 06.02.15.
//  Copyright (c) 2015 Daniele Galiotto - www.g8production.com. All rights reserved.
//

#import "BatchProcessorController.h"
#import "BatchProcessorCell.h"
#import "BatchProcessor.h"
#import "G8ViewController.h"

typedef enum : NSUInteger {
    infosMatchFound,
    infosPartialMatch,
    infosMismatch
} ImageInfoComparisonResult;

@interface BatchProcessorController ()
@end

@implementation BatchProcessorController
{
    G8ViewController* mainVC;
    NSString *initialWinery;
    BOOL canceled;
    UIAlertView *progessAlert;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.ocrResults = [[NSMutableArray alloc]init];
}

-(void)viewDidAppear:(BOOL)animated{
    mainVC = (G8ViewController*)self.presentingViewController.presentingViewController;
    initialWinery = mainVC.winery;

}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.images.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    BatchProcessorCell *cell = [tableView dequeueReusableCellWithIdentifier:@"BatchProcessorCell"forIndexPath:indexPath];
    
    UIImage *thumbnailImage = self.images[indexPath.row];
    dispatch_async(dispatch_get_main_queue(), ^{
        [cell.imageView setImage:thumbnailImage];
        
        UITableViewCellSelectionStyle selectionStyle = cell.selectionStyle;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        [cell setSelected:YES];
        [cell setSelected:NO];
        cell.selectionStyle = selectionStyle;
    });

    cell.imageInfo.text = [self.imageInfos[indexPath.row] description];
    
    if(indexPath.row < self.ocrResults.count){
        cell.ocrInfo.text = [self.ocrResults[indexPath.row] description];
    }
    
    return cell;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
- (IBAction)start:(id)sender {
    static NSUInteger index = 0;
    
    UIImage *curImage = self.images[index];
    ImageInfo *curImageInfo = self.imageInfos[index];
   mainVC.winery = curImageInfo.winery;
    
    if(index == 0){
        [self.ocrResults removeAllObjects];
        progessAlert = [[UIAlertView alloc]     initWithTitle:@"Please Wait..."
                                                message: [NSString stringWithFormat:@"Processing image 1/%ld",self.images.count]
                                                delegate:self
                                                cancelButtonTitle:nil otherButtonTitles: nil] ;
        UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        
        // Adjust the indicator so it is up a few pixels from the bottom of the alert
        indicator.center = CGPointMake(progessAlert.bounds.size.width / 2, progessAlert.bounds.size.height - 50);
        [indicator startAnimating];
        [progessAlert addSubview:indicator];

        progessAlert.delegate = self;
        [progessAlert show];
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self processImage:curImage withCompletion:^(OcrResult *i) {
            [self reportOcrCompletion:i];
            index++;
            if(index >= self.images.count || canceled){
                canceled = NO;
                index = 0;
                [self batchProcessFinished];
                return;
            }
            [self start:nil];
        }];
    });
}

-(void)processImage:(UIImage*) img withCompletion:(void(^)(OcrResult *i))block{
    if(img == nil || block == nil){
        return;
    }
    [TesseractRecognizer preprocessAndRecognizeImage:img withMode:adaptiveBinarization forWinery:mainVC.winery withCompletion:block ready:nil];
//    [mainVC preprocessAndRecognizeImage:img withMode:adaptiveBinarization withBlock:block];
}

-(void)reportOcrCompletion:(OcrResult *)i{
    static NSUInteger idx=0;
    if(idx>=self.imageInfos.count){
        i=0;
    }
    idx++;

    [self.ocrResults addObject:i];
    
    progessAlert.message = [NSString stringWithFormat:@"Processing image %lu/%ld",idx,self.images.count];
    [self.tableView reloadData];
}

-(void)batchProcessFinished{
    [progessAlert dismissWithClickedButtonIndex:0 animated:YES];
    
    NSString *results = [self processingResultsFormatted];
    progessAlert = [[UIAlertView alloc]     initWithTitle:@"Results"
                                                  message:results
                                                 delegate:self
                                        cancelButtonTitle:@"Ok" otherButtonTitles: nil] ;
    [progessAlert show];
}

-(NSString *)processingResultsFormatted{
    NSUInteger success,partial,fail;
    [self compareSource:self.imageInfos withOcred:self.ocrResults outSuccess:&success outPartial:&partial outFails:&fail];
    return [NSString stringWithFormat: @"Successful:%ld\nPartial:%ld\nFailed:%ld\nFail rate:%.1f%%",success,partial,fail,  (float)fail / (success+partial+fail) * 100 ];
}

-(void)compareSource:(NSArray*)src withOcred:(NSArray*)dst outSuccess:(NSUInteger*)success outPartial:(NSUInteger*)partial outFails:(NSUInteger*)fails{
    *success = *partial = *fails = 0;
    
    for (NSUInteger i=0; i<src.count; i++) {
        ImageInfoComparisonResult result = [self compareInfo:src[i] withResult:dst[i]];
        if(result == infosMatchFound){
            (*success)++;
        }
        if(result == infosPartialMatch){
            (*partial)++;
        }
        if(result == infosMismatch){
            (*fails)++;
        }
    }
}

-(ImageInfoComparisonResult)compareInfo:(ImageInfo*)info withResult:(OcrResult*)result{
 
    if([self caseInsensitiveContainment:info.acceptedSubregions string:result.subregion] ||
       [self caseInsensitiveContainment:info.acceptedVarieties string:result.variety] ||
       [self caseInsensitiveContainment:info.acceptedVineyards string:result.vineyard] ||
       [self caseInsensitiveContainment:info.acceptedYears string:result.year]){
        return infosMatchFound;
    }
    
    NSLog(@"Fail:%@",result);
    return infosMismatch;
}

-(BOOL)caseInsensitiveContainment:(NSArray*)array string:(NSString*)string{
    for (NSString* s in array) {
        if([s caseInsensitiveCompare:string] == NSOrderedSame){
            return YES;
        }
    }
    
    return NO;
}

- (IBAction)cancel:(id)sender {
    [mainVC setWinery:initialWinery];
    [mainVC unpauseCapture];
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
