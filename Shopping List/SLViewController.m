//
//  SLViewController.m
//  Shopping List
//
//  Created by Mike on 6/01/14.
//  Copyright (c) 2014 Mike. All rights reserved.
//

#import "SLViewController.h"
#import <dispatch/queue.h>
#import <Foundation/NSURLConnection.h>
#import <Foundation/NSJSONSerialization.h>

@interface SLViewController ()

@end

@implementation SLViewController

const NSInteger ALERT_TAG_ADD = 0;
const NSInteger ALERT_TAG_DELETE_ITEM = 1;
const NSInteger ALERT_TAG_DELETE_LIST = 2;

NSMutableArray * shopping_list_items;
NSInteger selectedIndex;

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        shopping_list_items = [[NSMutableArray alloc] init];

    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:addButton, trashButton, nil];
    
    UILongPressGestureRecognizer *lpgr = [[UILongPressGestureRecognizer alloc]
                                          initWithTarget:self action:@selector(handleLongPress:)];
    lpgr.minimumPressDuration = 1.2; //seconds
    [self.tableView addGestureRecognizer:lpgr];
    
    [self refreshShoppingList:self.refreshControl];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)handleLongPress:(UILongPressGestureRecognizer *)gestureRecognizer
{
    
    if(gestureRecognizer.state == UIGestureRecognizerStateEnded){
        CGPoint p = [gestureRecognizer locationInView:self.tableView];
        
        selectedIndex = [[self.tableView indexPathForRowAtPoint:p] row];
        
        NSString * message  = [NSString stringWithFormat:@"Are you sure you want to remove \"%@\" from the list?", shopping_list_items[selectedIndex] ];
        
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Remove item from shopping list?" message:message delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Confirm", nil];
        alert.tag = ALERT_TAG_DELETE_ITEM;
        [alert show];
        
    }
    
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    
    if (alertView.tag == ALERT_TAG_DELETE_ITEM) {
        
        if (buttonIndex != 0) { //Confirm Button has index 1
            
            if(!self.refreshControl.isRefreshing) [self.refreshControl beginRefreshing];
            
            //Send a DELETE request
            //Do long running task on different thread
            dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0); //Pass 0 for flags because docs say so :/
            dispatch_async(queue, ^{
                
                NSURL * url = [NSURL URLWithString:[NSString stringWithFormat:@"http://shoppinglistmike.herokuapp.com/shopping_list/%ld", selectedIndex]];
                NSMutableURLRequest * request = [[NSMutableURLRequest alloc] initWithURL:url];
                [request setHTTPMethod:@"DELETE"];
                
                NSHTTPURLResponse * response = nil;
                NSError * error = nil;
                
                [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
                
                if (error == nil) {
                    NSLog(@"Status code: %ld", response.statusCode);
                }else{
                    NSLog(@"%@", error.description);
                }
                
                //Success completion block
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [self refreshShoppingList:self.refreshControl];
                    [self.tableView reloadData];
                    [self.refreshControl endRefreshing];
                });
                
            });
            
        }
    }else if (alertView.tag == ALERT_TAG_ADD){
        if (buttonIndex != 0) {
            
            //Get the text for the new item
            NSString * itemText = [alertView textFieldAtIndex:0].text;
            
            if(!self.refreshControl.isRefreshing) [self.refreshControl beginRefreshing];
            
            //Send a POST request
            //Do long running task on different thread
            dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0); //Pass 0 for flags because docs say so :/
            dispatch_async(queue, ^{
                
                //Concstruct the request
                NSURL * url = [NSURL URLWithString:@"http://shoppinglistmike.herokuapp.com/shopping_list"];
                
                
                NSMutableURLRequest * request = [[NSMutableURLRequest alloc] initWithURL:url];
                [request setHTTPMethod:@"POST"];

                NSMutableDictionary * data = [[NSMutableDictionary alloc] init];
                [data setObject:itemText forKey:@"shopping_list_item"];
                NSError * error = nil;
                NSData * requestBody = [NSJSONSerialization dataWithJSONObject:data options:kNilOptions error:&error];
                
                if(error == nil){
                    [request setHTTPBody:requestBody];
                    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
                    NSHTTPURLResponse * response;
                    NSError * requestError = nil;
                    [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
                    
                    if (requestError == nil) {
                        NSLog(@"Status code: %ld", (long)response.statusCode);
                    }else{
                        NSLog(@"%@", requestError.description);
                    }
                }else{
                    NSLog(@"%@", error.description);
                }

                //Success completion block
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [self refreshShoppingList:self.refreshControl];
                    [self.tableView reloadData];
                    [self.refreshControl endRefreshing];
                });
            });
            
            
        }
    }else if (alertView.tag == ALERT_TAG_DELETE_LIST){
        if(!self.refreshControl.isRefreshing) [self.refreshControl beginRefreshing];
        
        //Send a DELETE request
        //Do long running task on different thread
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0); //Pass 0 for flags because docs say so :/
        dispatch_async(queue, ^{
            
            NSURL * url = [NSURL URLWithString:@"http://shoppinglistmike.herokuapp.com/shopping_list"];
            NSMutableURLRequest * request = [[NSMutableURLRequest alloc] initWithURL:url];
            [request setHTTPMethod:@"DELETE"];
            
            NSHTTPURLResponse * response = nil;
            NSError * error = nil;
            
            [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
            
            if (error == nil) {
                NSLog(@"Status code: %ld", response.statusCode);
            }else{
                NSLog(@"%@", error.description);
            }
            
            //Success completion block
            dispatch_sync(dispatch_get_main_queue(), ^{
                [self refreshShoppingList:self.refreshControl];
                [self.tableView reloadData];
                [self.refreshControl endRefreshing];
            });
            
        });
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell * cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    [cell.textLabel setText:shopping_list_items[[indexPath row]]];
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [shopping_list_items count];
}


- (IBAction)addItem:(UIBarButtonItem *)button
{
    UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Add Item to Shopping List" message:nil delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Add Item", nil];
    
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    alert.tag = ALERT_TAG_ADD;
    [alert show];
}

- (IBAction)refreshShoppingList:(UIRefreshControl *)refreshControl
{
    if(!refreshControl.isRefreshing) [refreshControl beginRefreshing];
    
    [shopping_list_items removeAllObjects];
    
    //Do long running task on different thread
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0); //Pass 0 for flags because docs say so :/
    dispatch_async(queue, ^{
        
        NSURL * url = [NSURL URLWithString:@"http://shoppinglistmike.herokuapp.com/shopping_list"];
        NSURLRequest * request = [[NSURLRequest alloc] initWithURL:url];
        
        NSHTTPURLResponse * response = nil;
        NSError * error = nil;
        
        NSData * responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        if (error == nil) {
            //Request was succesful :)
            if(response.statusCode==200){
                //Response looks pretty good too :D
                
                NSError * parsingError = nil;
                
                NSArray * json = [NSJSONSerialization JSONObjectWithData:responseData options:kNilOptions error:&parsingError];
                
                if (parsingError == nil) {
                    [shopping_list_items addObjectsFromArray:json];
                }else{
                    NSLog(@"Parsing error %@: ", parsingError.description);
                }
            }
        }else{
            //An error occured D:
            NSLog(@"Couldn't complete request");
        }

        //Completion block
        dispatch_sync(dispatch_get_main_queue(), ^{

            [self.tableView reloadData];
            [refreshControl endRefreshing];
        });
    });
    
}

- (IBAction)deleteList:(UIBarButtonItem *)button
{
    UIAlertView * alert = [[UIAlertView alloc ]initWithTitle:@"Delete entire list?" message:@"Are you sure you want to delete the entire list?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Do it", nil];
    alert.tag = ALERT_TAG_DELETE_LIST;
    [alert show];
    
}



@end
