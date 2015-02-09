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
    self.ocredImageInfos = [[NSMutableArray alloc]init];
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
    
    if(indexPath.row < self.ocredImageInfos.count){
        cell.ocrInfo.text = [self.ocredImageInfos[indexPath.row] description];
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
//    ImageInfo *curImageInfo = self.imageInfos[index];
//    mainVC.winery = curImageInfo.winery;
    
    if(index == 0){
        [self.ocredImageInfos removeAllObjects];
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
        [self processImage:curImage withCompletion:^(ImageInfo *i) {
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

-(void)processImage:(UIImage*) img withCompletion:(void(^)(ImageInfo *i))block{
    if(img == nil || block == nil){
        return;
    }
    [mainVC preprocessAndRecognizeImage:img withMode:adaptiveBinarization withBlock:block];
}

-(void)reportOcrCompletion:(ImageInfo *)i{
    static NSUInteger idx=0;
    if(idx>=self.imageInfos.count){
        i=0;
    }
    idx++;

    [self.ocredImageInfos addObject:i];
    
    progessAlert.message = [NSString stringWithFormat:@"Processing image %lu/%ld",idx,self.images.count];
    [self.tableView reloadData];
}

-(void)batchProcessFinished{
    [progessAlert dismissWithClickedButtonIndex:0 animated:YES];
    //TODO: show results popup
}

- (IBAction)cancel:(id)sender {
    [mainVC setWinery:initialWinery];
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
