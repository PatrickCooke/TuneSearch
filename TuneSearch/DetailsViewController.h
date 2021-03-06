//
//  DetailsViewController.h
//  TuneSearch
//
//  Created by Patrick Cooke on 4/26/16.
//  Copyright © 2016 Patrick Cooke. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Song.h"
#import <MessageUI/MessageUI.h>
#import <AVFoundation/AVFoundation.h>

@interface DetailsViewController : UIViewController <MFMailComposeViewControllerDelegate, MFMessageComposeViewControllerDelegate,UIGestureRecognizerDelegate>

@property (nonatomic,strong) Song *currentTune;

@end

