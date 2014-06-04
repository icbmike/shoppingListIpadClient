//
//  SLViewController.h
//  Shopping List
//
//  Created by Mike on 6/01/14.
//  Copyright (c) 2014 Mike. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SLViewController : UITableViewController <UITableViewDataSource, UITableViewDelegate>
{

IBOutlet UIBarButtonItem * addButton;
IBOutlet UIBarButtonItem * trashButton;

}
- (IBAction)refreshShoppingList:(UIRefreshControl *)refreshControl;
- (IBAction)addItem:(UIBarButtonItem *)button;
- (IBAction)deleteList:(UIBarButtonItem *)button;


@end
