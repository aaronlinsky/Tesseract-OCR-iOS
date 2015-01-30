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

static NSUInteger lastSelection = -1;

@interface WineryPickerController ()
@property(nonatomic,strong) NSArray *wineries;
@property(nonatomic,strong) NSMutableArray *filteredWineries;
@end

@implementation WineryPickerController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _wineries = [[[WinesDatabase wineriesAndVarieties] allKeys] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [(NSString *)obj1 compare:(NSString *)obj2];
    }];
    
    _filteredWineries = [[NSMutableArray alloc]initWithArray:_wineries];
        
    self.clearsSelectionOnViewWillAppear = NO;
    [self.searchDisplayController.searchResultsTableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"WineryCell"];
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

    if (tableView == self.searchDisplayController.searchResultsTableView) {
        cell.textLabel.text = self.filteredWineries[indexPath.row];
    } else {
        cell.textLabel.text = self.wineries[indexPath.row];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{

    lastSelection = indexPath.row;
    
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        [(G8ViewController*)self.presentingViewController.presentingViewController setWinery:self.filteredWineries[lastSelection]];
    } else {
        [(G8ViewController*)self.presentingViewController.presentingViewController setWinery:self.wineries[lastSelection]];
    }

    [self dismissViewControllerAnimated:YES completion:nil];
}


-(void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope {
    [self.filteredWineries removeAllObjects];

    self.filteredWineries =
    [self.wineries filteredArrayUsingPredicate:
     [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        return [(NSString*)evaluatedObject containsString: searchText];
    }]].mutableCopy;
}

-(BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {
    [self filterContentForSearchText:searchString scope:
     [[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:[self.searchDisplayController.searchBar selectedScopeButtonIndex]]];
    return YES;
}
@end
