//
//  ConnectionViewController.m
//  mySelfies
//
//  Created by Marcos Garcia on 2/17/15.
//  Copyright (c) 2015 Marcos Garcia. All rights reserved.
//

#import "ConnectionViewController.h"

@interface ConnectionViewController ()

@end

@implementation ConnectionViewController

@synthesize indicator;
@synthesize delegate;
@synthesize webServiceName;

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.containerLoad.layer setCornerRadius:4.0];
    [self.containerLoad.layer setMasksToBounds:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Connection Methods
-(void)connect:(NSMutableURLRequest *)req{
    connection = [[NSURLConnection alloc] initWithRequest:req delegate:self];
    if (connection) {
        webData = [NSMutableData data];
    }
}

-(void)start{
    [indicator startAnimating];
}

-(void)finish{
    [indicator stopAnimating];
    [self.view removeFromSuperview];
}

-(void)setPositionFromFrame:(CGRect)frame{
    CGRect frCnx = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    frCnx.origin.x = (frame.size.width - frCnx.size.width)/2.0;
    frCnx.origin.y = (frame.size.height - frCnx.size.height)/2.0;
    [self.view setFrame:frCnx];
}

- (void) errorAlert:(NSString *)title :(NSString *)message
{
    UIAlertView *alertStatus = [[UIAlertView alloc]initWithTitle:title
                                                         message:message
                                                        delegate:self
                                               cancelButtonTitle:@"Ok"
                                               otherButtonTitles:nil, nil];
    [alertStatus show];
}

#pragma mark - Connection Delegates
-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data{
    [webData appendData:data];
}

-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response{
    [webData setLength:0];
}

-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
    [self finish];
    [delegate connectionFinish:nil succes:NO serviceName:@"Instagram media"];
    [self errorAlert:@"Connection failure" :@"Please try again."];
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection{
    
    NSMutableDictionary *dictionaryContent = [NSMutableDictionary dictionary];
    id JSON = [NSJSONSerialization JSONObjectWithData:webData options:0 error:nil];
    dictionaryContent = JSON;
    [self finish];
    
    if (dictionaryContent != NULL) {
        [delegate connectionFinish:dictionaryContent succes:YES serviceName:webServiceName];
    }
    else{
        [delegate connectionFinish:dictionaryContent succes:NO serviceName:webServiceName];
    }
    
}

#pragma mark - View Methods
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

@end
