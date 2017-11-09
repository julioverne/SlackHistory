#import <dlfcn.h>
#import <objc/runtime.h>
#import <substrate.h>

#define NSLog(...)

@interface SLHTTPClient : NSObject
- (NSString*)accessToken;
@end

@interface SLKDependencies : NSObject
- (SLHTTPClient*)httpClient;
@end

@interface SLAppDelegate : NSObject
- (SLKDependencies*)dependencies;
@end

@interface SMUMessageDetailViewController : UIViewController
@end

@interface SLKMessage : NSObject
- (BOOL)isEdited;
@end

@interface SMUMessageActionsDelegate : NSObject
- (SLKMessage*)messageFromCell:(id)arg1;
@end

@interface SMUMessageCell : UITableViewCell
- (SMUMessageActionsDelegate*)actionsDelegate;
- (id)_viewControllerForAncestor;
@end

@interface SMUMessageDrawParameters : NSObject
- (NSString*)channelId;
- (NSString*)timestamp;
@end

@interface SMUMessageCellView : UIView
- (SMUMessageCell*)messageCell;
- (SMUMessageDrawParameters*)parameters;
- (id)_viewControllerForAncestor;
@end

@interface UIProgressHUD : UIView
- (void) hide;
- (void) setText:(NSString*)text;
- (void) showInView:(UIView *)view;
@end

%hook SMUMessageCellView
%new
- (void)handlePressHistory
{
	NSString* textHistory = nil;
	NSString* channelId = nil;
	NSString* timestamp = nil;
	NSString* token = nil;
	NSString* textTitle = @"History";
	
	@try {
		if(SMUMessageDrawParameters* parameters = [self parameters]) {
			channelId = [parameters channelId];
			timestamp = [parameters timestamp];
		}
		token = [[[(SLAppDelegate*)[[UIApplication sharedApplication] delegate] dependencies] httpClient] accessToken];
	}@catch(NSException* ex) {
	}
	
	@try {
		
		NSError *error = nil;
				NSHTTPURLResponse *responseCode = nil;
				NSMutableURLRequest *Request = [[NSMutableURLRequest alloc]	initWithURL:[NSURL URLWithString:@"https://slack.com/api/eventlog.history"] cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:15.0];
				[Request setHTTPMethod:@"POST"];
				[Request setValue:@"com.tinyspeck.chatlyio/3.31 (iPhone; iOS 10.2; Scale/2.00)" forHTTPHeaderField:@"User-Agent"];

				
				[Request setHTTPBody:[[NSString stringWithFormat:@"channel=%@&count=2000&start=%@&token=%@", channelId, timestamp, token] dataUsingEncoding:NSUTF8StringEncoding]];
				
				NSData *receivedData = [NSURLConnection sendSynchronousRequest:Request returningResponse:&responseCode error:&error];
				
				if(receivedData && !error) {
					NSDictionary *JSON = [NSJSONSerialization JSONObjectWithData:receivedData?:[NSData data] options:NSJSONReadingMutableContainers error:nil];
					@try {
						NSDateFormatter *_formatter=[[NSDateFormatter alloc]init];
						[_formatter setDateFormat:@"MM/dd/yy hh:mm:ss"];
						
						if(NSArray* events = JSON[@"events"]) {
							for(NSDictionary* eventNow in events) {
								if(NSString* subtype = eventNow[@"subtype"]) {
									if([subtype isEqualToString:@"message_changed"]) {
										if(NSDictionary* message = eventNow[@"message"]) {
											if(NSString* ts = message[@"ts"]) {
												if([ts isEqualToString:timestamp]) {
													textHistory = [textHistory?:@"" stringByAppendingFormat:@"\n⌚[%@]:\n%@\n", [_formatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:[eventNow[@"ts"]?:@"" doubleValue]]], message[@"text"]];
												}
											}
										}
									}
								}
							}
							
						}
						
					} @catch (NSException * e) {
						
					}
				} else if (error) {
						UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"SlackHistory" 
						    message:[error description]
						    delegate:nil
						    cancelButtonTitle:@"OK" 
						    otherButtonTitles:nil];
						[alert show];
				}
		
	}@catch(NSException* ex) {
	}
	
	if(textHistory) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:textTitle
                                                    message:textHistory
                                                    delegate:nil 
                                                    cancelButtonTitle:@"OK" 
                                                    otherButtonTitles:nil];
		[alert show];
	}
}
- (void)layoutSubviews
{
	%orig;
	
	BOOL isEdited = NO;
	@try {
		if(SMUMessageCell* messageCell = [self messageCell]) {
			if(SMUMessageActionsDelegate* actionsDelegate = [messageCell actionsDelegate]) {
				if(SLKMessage* message = [actionsDelegate messageFromCell:messageCell]) {
					isEdited = [message isEdited];
				}
			}
		}
	}@catch(NSException* ex) {
	}
	if(UIView* oldBT = [self viewWithTag:6481]) {
		[oldBT removeFromSuperview];
	}
	if(isEdited) {
		UIButton *buttonPop = [UIButton buttonWithType:UIButtonTypeRoundedRect];
		buttonPop.tag = 6481;
		buttonPop.titleLabel.font = [UIFont systemFontOfSize:12];
		buttonPop.titleLabel.textColor = [UIColor colorWithRed:0.40 green:0.40 blue:0.40 alpha:1.0];
		[buttonPop setFrame:CGRectMake(self.frame.size.width - 70, 0, 60,23)];
		[buttonPop setTitle:@"History" forState:UIControlStateNormal];
		[buttonPop setContentHorizontalAlignment:UIControlContentHorizontalAlignmentRight];
		[buttonPop addTarget:self action:@selector(handlePressHistory) forControlEvents:UIControlEventTouchDown];
		[self addSubview:buttonPop];
	}
}
%end