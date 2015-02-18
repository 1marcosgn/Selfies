//
//  ViewController.m
//  mySelfies
//
//  Created by Marcos Garcia on 2/17/15.
//  Copyright (c) 2015 Marcos Garcia. All rights reserved.
//

#import "ViewController.h"
#import "SmallImageCollectionViewCell.h"
#import "LargeImageCollectionViewCell.h"


/**
 * Constants to provide the interaction with Instagram API
 *
 * http://instagram.com/developer/endpoints/users/
 */
#define kBaseURL                        @"https://instagram.com/"
#define kInstagramAPIBaseURL            @"https://api.instagram.com"
#define kAuthenticationURL              @"oauth/authorize/?client_id=%@&redirect_uri=%@&response_type=token&scope=likes+comments+basic"  // comments
#define kClientID                       @"06a1af857c41445f864da4dfb6635330"
#define kRedirectURI                    @"http://marcosgnapps.weebly.com/"
#define kAccessToken                    @"access_token="
#define getMediaFromInstagram           @"https://api.instagram.com/v1/tags/selfie/media/recent?access_token="

@interface ViewController (){
    NSString *userToken;
    NSMutableArray *arrImgLinksSmall;
    NSMutableArray *arrImgLinksBig;
    NSString *sizeImage;
    UIView *detailView;
    UIImageView *movingCell;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    sizeImage = @"SMALL";
    [self.collectionSelfies setDelegate:self];
    [self.collectionSelfies setDataSource:self];
    arrImgLinksSmall = [[NSMutableArray alloc]init];
    arrImgLinksBig = [[NSMutableArray alloc]init];
    
    UINib *cellSmall = [UINib nibWithNibName:@"SmallImageCollectionViewCell" bundle:nil];
    [self.collectionSelfies registerNib:cellSmall forCellWithReuseIdentifier:@"smallCell"];
    
    UINib *cellLarge = [UINib nibWithNibName:@"LargeImageCollectionViewCell" bundle:nil];
    [self.collectionSelfies registerNib:cellLarge forCellWithReuseIdentifier:@"largeCell"];
    
    UIPanGestureRecognizer * recognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    recognizer.delegate = self;
    [self.view addGestureRecognizer:recognizer];
    
}

-(void)viewWillAppear:(BOOL)animated{
    
    NSString* urlString = [kBaseURL stringByAppendingFormat:kAuthenticationURL,kClientID,kRedirectURI];
    NSURLRequest* request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    [self.webView setDelegate:self];
    [self.webView loadRequest:request];
    
}

/**
 * Gesture recognizer to get the current image selected by the user
 *
 * @param panRecognizer
 */
-(void)handlePan:(UIPanGestureRecognizer *)panRecognizer{
    
    CGPoint locationPoint = [panRecognizer locationInView:self.collectionSelfies];
    
    if (panRecognizer.state == UIGestureRecognizerStateBegan) {
        
        NSIndexPath *indexPathOfMovingCell = [self.collectionSelfies indexPathForItemAtPoint:locationPoint];
        UICollectionViewCell *cell = [self.collectionSelfies cellForItemAtIndexPath:indexPathOfMovingCell];
        
        UIGraphicsBeginImageContext(cell.bounds.size);
        [cell.layer renderInContext:UIGraphicsGetCurrentContext()];
        UIImage *cellImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        movingCell = [[UIImageView alloc] initWithImage:cellImage];
        [movingCell setCenter:locationPoint];
        [movingCell setAlpha:0.75f];
        [self.collectionSelfies addSubview:movingCell];
        
    }
    
    if (panRecognizer.state == UIGestureRecognizerStateChanged) {
        [movingCell setCenter:locationPoint];
    }
    
    if (panRecognizer.state == UIGestureRecognizerStateEnded) {
        [movingCell removeFromSuperview];
    }
    
}

/**
 * This delegate loads the login view for the instagram account to return the user Token, its load only once
 *
 * @param webView        The web view that is about to load a new frame.
 * @param request        The content location
 * @param navigationType The type of user action that started the load request
 *
 * @return YES if the web view should begin loading content; otherwise, NO
 */
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSString* urlString = [[request URL] absoluteString];
    NSURL *Url = [request URL];
    NSArray *UrlParts = [Url pathComponents];
    
    // runs a loop till the user logs in with Instagram and after login yields a token for that Instagram user
    // do any of the following here
    if ([UrlParts count] == 1)
    {
        NSRange tokenParam = [urlString rangeOfString: kAccessToken];
        if (tokenParam.location != NSNotFound)
        {
            NSString* token = [urlString substringFromIndex: NSMaxRange(tokenParam)];
            // If there are more args, don't include them in the token:
            NSRange endRange = [token rangeOfString: @"&"];
            
            if (endRange.location != NSNotFound)
                token = [token substringToIndex: endRange.location];
            
            if ([token length] > 0 )
            {
                userToken = token;
                
                [self.webView setHidden:YES];
                [self.webView removeFromSuperview];
                
                if ([userToken isEqualToString:@""]) {
                    UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"" message:@"Please try again, we can not get your token" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
                    [alert show];
                }
                else{
                    [self getSelfies];
                }
            }
        }
        else
        {
            NSLog(@"rejected case, user denied request");
        }
        return NO;
    }
    return YES;
}

/**
 * Create a connection using the instagram API to get the tags #selfie, returns a JSON with all the information
 */
-(void)getSelfies{
    
    ConnectionViewController *connection = [[ConnectionViewController alloc]init];
    [connection setDelegate:self];
    [self.view insertSubview:connection.view atIndex:[[self.view subviews]count]];
    [connection start];
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", getMediaFromInstagram, userToken]];
    NSURLRequest *req = [[NSURLRequest alloc]initWithURL:url];
    [connection connect:[req mutableCopy]];
    
}

/**
 * Delegate to provide the connection status
 *
 * @param JSONObject JSON Dictionary with all the elements returning from the webservice
 * @param success    YES | NO it depends of the answer
 * @param name       name of the webservice
 */
-(void)connectionFinish:(NSDictionary *)JSONObject succes:(BOOL)success serviceName:(NSString *)name{
    
    if ([JSONObject count] == 0 || success == NO) {
        [self extraValidationforData];
    }
    else{
        NSMutableDictionary *elements = [NSMutableDictionary dictionary];
        elements = [JSONObject valueForKey:@"data"];
    
        for (id subElement in elements) {
            [arrImgLinksSmall addObject:[[[subElement valueForKey:@"images"]valueForKey:@"thumbnail"]valueForKey:@"url"]];    //150x150
            [arrImgLinksBig addObject:[[[subElement valueForKey:@"images"]valueForKey:@"standard_resolution"]valueForKey:@"url"]]; //640x640
        }
        [self.collectionSelfies reloadData];
    }
}

#pragma mark - CollectionView Delegates
-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    return 1;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    int numberSections = 0;
    if ([sizeImage isEqualToString:@"SMALL"]) {
        numberSections = (int)[arrImgLinksSmall count];
    }
    else if ([sizeImage isEqualToString:@"LARGE"]){
        numberSections = (int)[arrImgLinksBig count];
    }
    return numberSections;
}

/**
 * Loads the pictures for each cell in the collection view
 *
 * @param collectionView An object representing the collection view requesting this information
 * @param indexPath      The index path that specifies the location of the item.
 *
 * @return A configured cell object. You must not return nil from this method.
 */
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    
    static NSString *cellIdentifier = @"";
    UICollectionViewCell *cell = [[UICollectionViewCell alloc]init];
    SmallImageCollectionViewCell *cellSmall;
    LargeImageCollectionViewCell *cellLarge;
    
    if ([sizeImage isEqualToString:@"SMALL"]) {
        cellIdentifier = @"smallCell";
        cellSmall = (SmallImageCollectionViewCell *) [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    }
    else if ([sizeImage isEqualToString:@"LARGE"]){
        cellIdentifier = @"largeCell";
        cellLarge = (LargeImageCollectionViewCell *) [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    }
    
    NSURL *url = [NSURL URLWithString:[arrImgLinksSmall objectAtIndex:indexPath.row]];
    
    [self downloadImageWithURL:url completionBlock:^(BOOL succeeded, NSData *data) {
        if (succeeded) {
            if ([sizeImage isEqualToString:@"SMALL"]) {
                cellSmall.imgDisplay.image = [[UIImage alloc] initWithData:data];
            }
            else if ([sizeImage isEqualToString:@"LARGE"]){
                cellLarge.imgDisplay.image = [[UIImage alloc] initWithData:data];
            }
        }
    }];
    
    if ([sizeImage isEqualToString:@"SMALL"]) {
        return cellSmall;
    }
    else if ([sizeImage isEqualToString:@"LARGE"]){
        return cellLarge;
    }
    else{
        return cell;
    }
    
}

/**
 * Loading the image in an asynchronous way
 *
 * @param url               link from the image to load
 * @param completionBlock   block to be asynchronously execute
 */
- (void)downloadImageWithURL:(NSURL *)url completionBlock:(void (^)(BOOL succeeded, NSData *data))completionBlock
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (!error) {
            completionBlock(YES, data);
        } else {
            completionBlock(NO, nil);
        }
    }];
}

/**
 * Called every time when the user select a specific cell to show the image detail
 *
 * @param collectionView the collection object
 * @param indexPath      The index path of the cell that was selected
 */
-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    
    NSString *url = [arrImgLinksBig objectAtIndex:indexPath.row];
    detailView = [[UIView alloc]initWithFrame:CGRectMake(40, 90, 300, 350)];
    [detailView setBackgroundColor:[UIColor grayColor]];
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [button addTarget:self action:@selector(closeDetailView) forControlEvents:UIControlEventTouchUpInside];
    [button setTitle:@"Close" forState:UIControlStateNormal];
    [button setBackgroundColor:[UIColor blackColor]];
    [button setTintColor:[UIColor whiteColor]];
    button.frame = CGRectMake(0, 310, 300, 40);
    [button setUserInteractionEnabled:YES];
    
    UIImageView *imageDetail = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, 300, 310)];
    
    [self downloadImageWithURL:[NSURL URLWithString:url] completionBlock:^(BOOL succeeded, NSData *data) {
        if (succeeded) {
            imageDetail.image = [[UIImage alloc]initWithData:data];
        }
    }];
    
    [detailView addSubview:imageDetail];
    [detailView addSubview:button];
    [self.view addSubview:detailView];
    
    [self.collectionSelfies setUserInteractionEnabled:NO];

}

/**
 * Removes the detail view from the main view
 */
-(void)closeDetailView{
    [detailView removeFromSuperview];
    [self.collectionSelfies setUserInteractionEnabled:YES];
}

/**
 * Defines trhe size for a large or small cell
 *
 * @param collectionView       collectionview object
 * @param collectionViewLayout the layout of the collectionview
 * @param indexPath            The index path of the cell
 *
 * @return size for the cell
 */
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
    
    if ([sizeImage isEqualToString:@"SMALL"]) {
        return CGSizeMake(80.0f, 80.0f);
    }
    else if ([sizeImage isEqualToString:@"LARGE"]){
        return CGSizeMake(180.0f, 180.0f);
    }
    else{
        return CGSizeMake(0.0f, 0.0f);
    }
    
}

/**
 * Extra validation for web service
 */
-(void)extraValidationforData{
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"" message:@"Please try again" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
    [alert show];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

/**
 * Changes the size of the images and reload the collection view
 *
 * @param sender
 */
- (IBAction)getSmallSize:(id)sender {
    sizeImage = @"SMALL";
    [self.collectionSelfies reloadData];
}

/**
 * Changes the size of the images and reload the collection view
 *
 * @param sender
 */
- (IBAction)getLargeSize:(id)sender {
    sizeImage = @"LARGE";
    [self.collectionSelfies reloadData];
}

@end
