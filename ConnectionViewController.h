//
//  ConnectionViewController.h
//  mySelfies
//
//  Created by Marcos Garcia on 2/17/15.
//  Copyright (c) 2015 Marcos Garcia. All rights reserved.
//

#import <UIKit/UIKit.h>

//Protocol for connection
@protocol ConnectionDelegate <NSObject>

-(void)connectionFinish:(NSDictionary *)JSONObject succes:(BOOL)success serviceName:(NSString *)name;

@end

@interface ConnectionViewController : UIViewController <NSURLConnectionDataDelegate>{
    NSMutableData *webData;
    NSURLConnection *connection;
    NSString *webServiceName;
    id<ConnectionDelegate> delegate;
}

@property (nonatomic, retain) id <ConnectionDelegate> delegate;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *indicator;
@property (nonatomic, retain) NSString *webServiceName;
@property (weak, nonatomic) IBOutlet UIView *containerLoad;


-(void)connect:(NSMutableURLRequest *)req;
-(void)start;
-(void)finish;
-(void)setPositionFromFrame:(CGRect)frame;
-(void)errorAlert:(NSString *)title :(NSString *)message;





@end
