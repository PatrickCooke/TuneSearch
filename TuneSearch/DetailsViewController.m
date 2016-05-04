//
//  DetailsViewController.m
//  TuneSearch
//
//  Created by Patrick Cooke on 4/26/16.
//  Copyright © 2016 Patrick Cooke. All rights reserved.
//

#import "DetailsViewController.h"
#import <Social/Social.h>
#import "AppDelegate.h"
#import "Song.h"
#import <AVFoundation/AVFoundation.h>
#import <SafariServices/SafariServices.h>

@interface DetailsViewController ()

@property (nonatomic,weak) IBOutlet UILabel *kindLabel;
@property (nonatomic,weak) IBOutlet UILabel *songTitleLabel;
@property (nonatomic,weak) IBOutlet UILabel *albumTitleLabel;
@property (nonatomic,weak) IBOutlet UILabel *artistLabel;
@property (nonatomic,weak) IBOutlet UITextView *descriptTextView;
@property (nonatomic,weak) IBOutlet UIImageView *albumcoverImageView;
@property (nonatomic,weak) IBOutlet UIButton *samplePlayButton;
@property (nonatomic,weak) IBOutlet UIButton *samplePauseButton;
@property (nonatomic,weak) IBOutlet UIButton *artistInfoButton;

@property (nonatomic,strong) AVPlayer *audioplayer;



@end

CGFloat lastScale;
CGFloat firstX;
CGFloat firstY;
CGFloat lastRotation;

@implementation DetailsViewController

#pragma mark - Interactivity Methods

-(IBAction)emailButtonPressed:(id)sender {
    NSLog(@"email");
    if ([MFMailComposeViewController canSendMail]) {
        MFMailComposeViewController *mailVC = [[MFMailComposeViewController alloc] init];
        mailVC.mailComposeDelegate = self;
        [mailVC setSubject:[NSString stringWithFormat:@"I LOVE %@", _currentTune.songTitle]];
        [mailVC setMessageBody:@"Do you know how much I love it?" isHTML:false];
        [mailVC setToRecipients:@[@"tom@theironyard.com"]];
        [self.navigationController presentViewController:mailVC animated: true completion:nil];
    }
}

-(void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    [self becomeFirstResponder];
    [self dismissViewControllerAnimated:true completion:nil];
}

-(IBAction)smsButtonPressed:(id)sender {
    NSLog(@"sms");
    if ([MFMessageComposeViewController canSendText]) {
        MFMessageComposeViewController *textVC = [[MFMessageComposeViewController alloc] init];
        textVC.body =[NSString stringWithFormat:@"I love %@", _currentTune.songTitle];
        textVC.messageComposeDelegate = self;
        [self.navigationController presentViewController:textVC animated:true completion:nil];
    }
}

-(void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result {
    [self becomeFirstResponder];
    [self dismissViewControllerAnimated:true completion:nil];
}

-(IBAction)fbButtonPressed:(id)sender {
    NSLog(@"fb");
    if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeFacebook]) {
        SLComposeViewController *fbVC = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook];
        [fbVC setInitialText:[NSString stringWithFormat: @"I LOVE %@",_currentTune.songTitle]];
        [self.navigationController presentViewController:fbVC animated:true completion:nil];
    }
}

-(IBAction)twitterButtonPressed:(id)sender {
    NSLog(@"twitter");
    if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter]) {
        SLComposeViewController *twitterVC = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
        [twitterVC setInitialText:[NSString stringWithFormat: @"I LOVE %@",_currentTune.songTitle]];
        [self.navigationController presentViewController:twitterVC animated:true completion:nil];
    }
}

-(IBAction)whateverButtonPressed:(id)sender {
    NSLog(@"whatever");
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:@[[NSString stringWithFormat:@"I love %@",_currentTune.songTitle]] applicationActivities:nil];
    [self.navigationController presentViewController:activityVC animated:true completion:nil];
}

-(IBAction)sampleAudioPreview:(id)sender {
    if ([[[_samplePlayButton titleLabel] text] isEqualToString:@"Play Sample of Song"]) {
        [_samplePlayButton setTitle:@"Pause Sample of Song" forState:UIControlStateNormal];
        [_audioplayer play];
    } else {
        [_samplePlayButton setTitle:@"Play Sample of Song" forState:UIControlStateNormal];
        [_audioplayer pause];
    }
}

//-(IBAction)sampleAudioPause:(id)sender {
//    [_audioplayer pause];
//}

-(IBAction)showArtistUrlPressed:(id)sender {//much more elegant method (over showing website via UIWebView) when showing a website within an app
    NSLog(@"pressed artist Info - %@",_currentTune.artistInfoURLString);
    SFSafariViewController *SafairVC = [[SFSafariViewController alloc] initWithURL:[NSURL URLWithString:_currentTune.artistInfoURLString]];
    [self.navigationController presentViewController:SafairVC animated:true completion:nil];
}

-(IBAction)showTrackUrlPressed:(id)sender {//much more elegant method (over showing website via UIWebView) when showing a website within an app
    NSLog(@"pressed track Info - %@",_currentTune.trackInfoURLString);
    SFSafariViewController *SafairVC = [[SFSafariViewController alloc] initWithURL:[NSURL URLWithString:_currentTune.trackInfoURLString]];
[self.navigationController presentViewController:SafairVC animated:true completion:nil];
}


#pragma mark - Gesture Methods


-(IBAction)imagePinched:(UIPinchGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateBegan) {
        lastScale = 1.0;
    }
    CGFloat scale = 1.0 - (lastScale - gesture.scale);
    CGAffineTransform currentTransform = _albumcoverImageView.transform;
    CGAffineTransform newTransform = CGAffineTransformScale(currentTransform, scale, scale);
    [_albumcoverImageView setTransform:newTransform];
    lastScale = gesture.scale;
}

-(IBAction)imageRotated:(UIRotationGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateEnded) {
        lastRotation = 0.0;
        return;
    }
    CGFloat rotation = 0.0 - (lastRotation - gesture.rotation);
    CGAffineTransform currentTransform = _albumcoverImageView.transform;
    CGAffineTransform newtransform = CGAffineTransformRotate(currentTransform, rotation);
    [_albumcoverImageView setTransform:newtransform];
    lastRotation = gesture.rotation;
}

-(IBAction)imagePan:(UIPanGestureRecognizer *)gesture {
    CGPoint translatedPoint = [gesture translationInView:self.view];
    if (gesture.state == UIGestureRecognizerStateBegan) {
        firstX = _albumcoverImageView.center.x;
        firstY = _albumcoverImageView.center.y;
    }
    translatedPoint = CGPointMake(firstX+translatedPoint.x, firstY+translatedPoint.y);
    [_albumcoverImageView setCenter:translatedPoint];
}

-(BOOL) gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer{
    return true;
}



#pragma mark - Life Cycle Methods

- (void)viewDidLoad {
    [super viewDidLoad];
    _songTitleLabel.text=_currentTune.songTitle;
    _kindLabel.text = _currentTune.itemKind;
    _albumTitleLabel.text = _currentTune.albumTitle;
    _artistLabel.text = _currentTune.artistName;
    _descriptTextView.text = _currentTune.descriptString;
    _albumcoverImageView.image = [UIImage imageNamed:_currentTune.trackId];
    NSLog(@"title-artist, album %@ - %@ - %@", _currentTune.songTitle, _currentTune.artistName, _currentTune.albumTitle);
    NSLog(@"image id - %@", _currentTune.trackId);
    
    NSURL *audioPreview = [NSURL URLWithString:_currentTune.previewUrl];
    _audioplayer = [[AVPlayer alloc] initWithURL:audioPreview];
    NSLog(@"song url - %@", _currentTune.previewUrl);
    //NSLog(@"song name %@", _currentTune.previewName);
    if ([_currentTune.itemKind isEqualToString: @"feature-movie"]) {
        [_artistInfoButton setUserInteractionEnabled:false];
        [_artistInfoButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
        [_samplePlayButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
        [_samplePauseButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
    } else if ([_currentTune.itemKind isEqualToString: @"tv-episode"]){
        [_samplePlayButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
        [_samplePauseButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
    } else {
        [_artistInfoButton setUserInteractionEnabled:true];
        [_samplePauseButton setUserInteractionEnabled:true];
        [_samplePlayButton setUserInteractionEnabled:true];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


@end
