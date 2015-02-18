//
//  ViewController.h
//  mySelfies
//
//  Created by Marcos Garcia on 2/17/15.
//  Copyright (c) 2015 Marcos Garcia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ConnectionViewController.h"

@interface ViewController : UIViewController <UIWebViewDelegate, ConnectionDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UIGestureRecognizerDelegate>

@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (nonatomic, retain) NSMutableData *dataResponse;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionSelfies;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *btnSmall;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *btnBig;

- (IBAction)getSmallSize:(id)sender;
- (IBAction)getLargeSize:(id)sender;

@end

