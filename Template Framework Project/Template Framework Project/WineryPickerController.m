//
//  WineryPickerController.m
//  Template Framework Project
//
//  Created by Sergey Yuzepovich on 30.01.15.
//  Copyright (c) 2015 Daniele Galiotto - www.g8production.com. All rights reserved.
//

#import "WineryPickerController.h"
#import "WinesDatabase.h"
#import "G8ViewController.h"
#import "WineryPickerCell.h"

static NSUInteger lastSelection = -1;

@interface WineryPickerController ()
@property(nonatomic,strong) NSArray *wineries;
@property(nonatomic,strong) NSDictionary *wineriesVarieties;
@property(nonatomic,strong) NSDictionary *wineriesVineyards;
@property(nonatomic,strong) NSDictionary *wineriesSubregions;
@property(nonatomic,strong) NSMutableArray *filteredWineries;
@end

@implementation WineryPickerController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _wineriesVarieties = [WinesDatabase wineriesAndVarieties];
    _wineriesVineyards = [WinesDatabase wineriesAndVineyards];
    _wineriesSubregions = [WinesDatabase wineriesAndSubregions];
    _wineries = [[_wineriesVarieties allKeys] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [(NSString *)obj1 compare:(NSString *)obj2];
    }];
    
    _filteredWineries = [[NSMutableArray alloc]initWithArray:_wineries];
        
    self.clearsSelectionOnViewWillAppear = NO;
//    [self.searchDisplayController.searchResultsTableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"WineryCell"];
    [self.searchDisplayController.searchResultsTableView registerClass:[WineryPickerCell class] forCellReuseIdentifier:@"WineryCell"];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        return self.filteredWineries.count;
    }
    return self.wineries.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"WineryCell"];

    NSString *winery;
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        winery = self.filteredWineries[indexPath.row];
    } else {
        winery = self.wineries[indexPath.row];
    }
    
    cell.textLabel.text = winery;
    cell.detailTextLabel.text =  [NSString stringWithFormat:@"Varieties:%lu Vineyards:%lu Locations:%lu", [self.wineriesVarieties[winery] count], [self.wineriesVineyards[winery] count], [self.wineriesSubregions[winery] count]];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{

    lastSelection = indexPath.row;
    
    NSString *winery;
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        winery = self.filteredWineries[lastSelection];
    } else {
        winery = self.wineries[lastSelection];
    }

    G8ViewController* mainVC = (G8ViewController*)self.presentingViewController.presentingViewController;
    [mainVC setWinery:winery];
    [mainVC unpauseCapture];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}


-(void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope {
    [self.filteredWineries removeAllObjects];

    self.filteredWineries =
    [self.wineries filteredArrayUsingPredicate:
     [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        return [(NSString*)evaluatedObject rangeOfString: searchText options:NSCaseInsensitiveSearch].length > 0;
    }]].mutableCopy;
}

-(BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {
    [self filterContentForSearchText:searchString scope:
     [[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:[self.searchDisplayController.searchBar selectedScopeButtonIndex]]];
    return YES;
}
@end
