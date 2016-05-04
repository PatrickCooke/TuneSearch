//
//  ViewController.m
//  TuneSearch
//
//  Created by Patrick Cooke on 4/25/16.
//  Copyright © 2016 Patrick Cooke. All rights reserved.
//

#import "ViewController.h"
#import "Reachability.h"
#import "ResultsViewCell.h"
#import "AppDelegate.h"
#import "Song.h"
#import "DetailsViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "ResultsCollectionViewCell.h"

@interface ViewController ()

@property (nonatomic, strong)        NSString           *hostName;
@property (nonatomic, strong)        NSMutableArray     *resultsArray;
@property (nonatomic, weak) IBOutlet UISearchBar        *songSearchBar;
@property (nonatomic,weak) IBOutlet  UICollectionView   *ResultsCollectionView;
@property (nonatomic,strong)         AVPlayer           *audioplayer;
@property (nonatomic,weak) IBOutlet  UIView             *menuView;
@property (nonatomic,weak) IBOutlet  NSLayoutConstraint *menuTopConstraint;
@property (nonatomic,weak) IBOutlet  NSLayoutConstraint *menuCollectConstraint;
@property (nonatomic,weak) IBOutlet  NSLayoutConstraint *bottomCollectConstraint;


@end

@implementation ViewController

#pragma mark - Global Variables

Reachability *hostReach;
Reachability *internetReach;
Reachability *wifiReach;
bool internetAvailable;
bool serverAvailable;

#pragma mark - Keyboard Methods

- (void)keyboardMoved:(NSNotification *)aNotification {
    NSLog(@"keyboard changed");
    NSDictionary *userInfo = aNotification.userInfo;
    
    NSValue *beginFrameValue = userInfo[UIKeyboardDidChangeFrameNotification];
    CGRect keyboardBeginFrame = [self.view convertRect:beginFrameValue.CGRectValue fromView:nil];
    
    NSValue *endFrameValue = userInfo[UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardEndFrame = [self.view convertRect:endFrameValue.CGRectValue fromView:nil];
    
    //
    // Get keyboard animation.
    
    NSNumber *durationValue = userInfo[UIKeyboardAnimationDurationUserInfoKey];
    NSTimeInterval animationDuration = durationValue.doubleValue;
    
    NSNumber *curveValue = userInfo[UIKeyboardAnimationCurveUserInfoKey];
    UIViewAnimationCurve animationCurve = curveValue.intValue;
    
    CGRect tableViewFrame = self.ResultsCollectionView.frame;
    tableViewFrame.size.height = (keyboardBeginFrame.origin.y - tableViewFrame.origin.y);
    self.ResultsCollectionView.frame = tableViewFrame;
    
    [UIView animateWithDuration:animationDuration delay:0.0 options:animationCurve animations:^{
        _bottomCollectConstraint.constant = -1*(keyboardEndFrame.origin.y);
    } completion:nil];
}

#pragma mark - Interactivity Methods

-(IBAction)showAndHideSearch:(id)sender {
    //[_songSearchView setHidden:!_songSearchView.hidden];
    NSLog(@"toggle");
    if (_menuView.hidden) {
        [_menuView setHidden:false];
        [UIView animateWithDuration:1.0 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            [_menuView setAlpha:1.0];
            _menuTopConstraint.constant = 0.0;
            _menuCollectConstraint.constant = 0;
            [self.view layoutIfNeeded];
        } completion:^(BOOL finished) {
            //
        }];
    } else {
        [UIView animateWithDuration:1.0 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            [_menuView setAlpha:0.0];
            _menuTopConstraint.constant = -1 *(_menuView.frame.size.height + self.navigationController.navigationBar.frame.size.height);
            _menuCollectConstraint.constant = 0-_menuView.frame.size.height;
            [self.view layoutIfNeeded];
        } completion:^(BOOL finished) {
            [_menuView setHidden:true];
            [_songSearchBar resignFirstResponder];
        }];
    }
}


-(IBAction)samplePreview:(UIButton*)playpausebutton {

    CGPoint playSelection = [playpausebutton convertPoint:CGPointZero toView:_ResultsCollectionView];
    NSIndexPath *indexPath = [_ResultsCollectionView indexPathForItemAtPoint:playSelection];
    Song *currentSong = _resultsArray[indexPath.row];
    NSURL *previewsongUrl = [NSURL URLWithString:currentSong.previewUrl];
    
    _audioplayer = [[AVPlayer alloc] initWithURL:previewsongUrl];
    NSLog(@"Cell %li Picked. URL is %@", indexPath.row, previewsongUrl);
    
    NSLog(@"Button Title is: %@",[[playpausebutton titleLabel] text]);
    if ([[[playpausebutton titleLabel] text] isEqualToString:@"Play"]) {
        NSLog(@"WIll Play");
        [playpausebutton setTitle:@"Pause" forState:UIControlStateNormal];
        [_audioplayer play];
    } else {
        NSLog(@"WIll Pause");
        [playpausebutton setTitle:@"Play" forState:UIControlStateNormal];
        [_audioplayer pause];
    }
}

-(IBAction)getFilePressed:(id)sender {
    [_songSearchBar resignFirstResponder];
    NSString *rawSearchString = [_songSearchBar.text lowercaseString];
    NSString *finalSearchString = [rawSearchString stringByReplacingOccurrencesOfString:@" " withString:@"+"];
    NSLog(@"Get File");
    if (serverAvailable) {
        NSLog(@"Server Available");
        NSURL *fileURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@/search?term=%@", _hostName, finalSearchString]];
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
        [request setURL:fileURL];
        [request setCachePolicy:NSURLRequestReloadIgnoringCacheData];
        [request setTimeoutInterval:30.0];
        NSURLSession *session = [NSURLSession sharedSession];
        [[session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            NSLog(@"Got Response");
            if (([data length] > 0) && (error == nil)) {
                NSJSONSerialization *json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
                NSLog(@"Got jSON %@", json);
                NSArray *tempArray = [(NSDictionary *)json objectForKey:@"results"];
                [_resultsArray removeAllObjects];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"dataRcvMsg" object:nil];
                });
                for (NSDictionary *resultsDict in tempArray) {
                    NSLog(@"songs: %@ track %@", [resultsDict objectForKey:@"artistName"],[resultsDict objectForKey:@"trackId"]);
                    Song *newsong = [[Song alloc] initWithArtistName:[resultsDict objectForKey:@"artistName"] andSongTitle:[resultsDict objectForKey:@"trackName"] andalbumTitle:[resultsDict objectForKey:@"collectionName"] andAlbumtArtFileName:[resultsDict objectForKey:@"artworkUrl100"] andtrackExplicit:[resultsDict objectForKey:@"trackExplicitness"] andtrackId:[NSString stringWithFormat:@"%@.jpg",[resultsDict objectForKey:@"trackId"]] anditemKind:[resultsDict objectForKey:@"kind"] andpreviewUrl:[resultsDict objectForKey:@"previewUrl"] andpreviewName:[NSString stringWithFormat:@"%@.m4a",[resultsDict objectForKey:@"trackId"]] anddescriptString:[resultsDict objectForKey:@"longDescription"] andartistInfoURLString:[resultsDict objectForKey:@"artistViewUrl"] andtrackInfoURLString:[resultsDict objectForKey:@"trackViewUrl"]];
                    [_resultsArray addObject:newsong];
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    [_ResultsCollectionView reloadData];
                });
            }
        }] resume];
        
    } else {
        NSLog(@"Server is not Available");
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Server not Available" message:@"Internet Unavailable, please connect or contact Admin" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style: UIAlertActionStyleDefault handler:nil];
        [alert addAction: okAction];
        [self presentViewController:alert animated:true completion:nil];
    }
}

#pragma mark - CollectionView Method

-(NSInteger) collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _resultsArray.count;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    ResultsCollectionViewCell *cell = (ResultsCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    Song *currentTune = _resultsArray[indexPath.row];
    cell.ArtistLabel.text = currentTune.artistName;
    cell.TrackLabel.text = currentTune.songTitle;
    if ([self file:currentTune.trackId isInDirectory:NSTemporaryDirectory()]) {
        NSLog(@"Not Found %@",currentTune.trackId);
        cell.albumArtImageView.image = [UIImage imageNamed:[NSTemporaryDirectory() stringByAppendingPathComponent:currentTune.trackId]];
    } else {
        cell.albumArtImageView.image = nil;
        [self getImageFromServer:currentTune.trackId fromURL: currentTune.albumArtFileName atIndexPath:indexPath];
        NSLog(@"Not Found %@",currentTune.trackId);
    }
    if ([currentTune.itemKind isEqualToString: @"feature-movie"]) {
        [cell.sampleButton setUserInteractionEnabled:false];
        [cell.sampleButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
    } else if ([currentTune.itemKind isEqualToString: @"tv-episode"]){
        [cell.sampleButton setUserInteractionEnabled:false];
        [cell.sampleButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
    } else if ([currentTune.itemKind isEqualToString: @"song"]){
        [cell.sampleButton setUserInteractionEnabled:true];
        [cell.sampleButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    }
    if ([currentTune.trackExplicit isEqualToString:@"explicit"]) {
        cell.backgroundColor = [UIColor redColor];
    } else if ([currentTune.trackExplicit isEqualToString:@"notExplicit"]) {
        cell.backgroundColor = [UIColor colorWithRed:204.0f/255.0f green:204.0f/255.0f blue:204.0f/255.0f alpha:1.0];
    }
    cell.layer.masksToBounds = YES;
    cell.layer.cornerRadius = 4;
    
    return cell;
}

#pragma mark - Prepare for Segueue

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    DetailsViewController *destController = [segue destinationViewController];
    NSIndexPath *indexpath = [_ResultsCollectionView indexPathsForSelectedItems][0];
    destController.currentTune = [_resultsArray objectAtIndex:indexpath.row];
}

#pragma mark - File System Methods

//- (NSString *)getDocumentsDirectory {
//    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, true);
//    NSLog(@"DocPath: %@",paths[0]);
//    return paths[0];
//} //to find the documents folder

- (BOOL)file:(NSString *)filename isInDirectory:(NSString *)directory {
    NSFileManager *filemanager = [NSFileManager defaultManager];
    NSString *filePath = [directory stringByAppendingPathComponent:filename];
    return [filemanager fileExistsAtPath:filePath];
    //reusable method to check and see if a specific file exists
}

-(void)getImageFromServer:(NSString *)localFileName fromURL:(NSString *)fullFileName atIndexPath:(NSIndexPath *)indexpath {
    if (serverAvailable) {
        //NSLog(@"local:%@ full:%@",localFileName,fullFileName);
        NSURL *fileURL = [NSURL URLWithString:fullFileName];
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
        [request setURL:fileURL];
        [request setCachePolicy:NSURLRequestReloadIgnoringCacheData];
        [request setTimeoutInterval:30.0];
        NSURLSession *session = [NSURLSession sharedSession];
        [[session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            //NSLog(@"Image Length:%li error: %@",[data length],error);
            if (([data length] > 0) && (error == nil)) {
                NSString *savedFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:localFileName];
                UIImage *imageTemp = [UIImage imageWithData:data];
                if (imageTemp !=nil) {
                    [data writeToFile:savedFilePath atomically:true];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [_ResultsCollectionView reloadItemsAtIndexPaths:@[indexpath]];
//                        [_resultsTableView reloadRowsAtIndexPaths:@[indexpath] withRowAnimation:UITableViewRowAnimationAutomatic];
                    });
                }
            }
        }] resume];
    } else {
        NSLog(@"server not available");
    }
}

#pragma mark - Searchbar Delegate

-(void) searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [self getFilePressed:self];
}


#pragma mark - Network Methods

-(void)searchResultRecv:(NSNotification *)notification {
    NSLog(@"Reloading Table");
    [_ResultsCollectionView reloadData];
}

-(void)updateReachabilityStatus:(Reachability *) currentReach { //this method is called anything the network type changes
    NSParameterAssert([currentReach isKindOfClass:[Reachability class]]); //this code makes sure that "currentReach" is actually a Reachablity class
    NetworkStatus netStatus = [currentReach currentReachabilityStatus];
    if (currentReach == hostReach) {
        switch (netStatus) { //this series makes sure if the server is up
            case NotReachable:
                NSLog(@"Sever Not Available");
                serverAvailable = false;
                break;
            case ReachableViaWWAN:
                NSLog(@"Server Reachable via WWAN");
                serverAvailable = true;
            case ReachableViaWiFi:
                NSLog(@"Server Reachable via WiFi");
                serverAvailable = true;
            default:
                break;
        }
    }
    if (currentReach == internetReach || currentReach == wifiReach) {
        switch (netStatus) {
            case NotReachable:
                NSLog(@"Internet not Available");
                internetAvailable = false;
                break;
            case ReachableViaWWAN:
                NSLog(@"Internet Available via WWAN");
                internetAvailable = true;
            case ReachableViaWiFi:
                NSLog(@"Internet Available via WiFi");
                internetAvailable = true;
            default:
                break;
        }
    }
}


-(void)reachablityChanged:(NSNotification *)notification {
    Reachability *currentReach = [notification object];
    [self updateReachabilityStatus:currentReach];
}

#pragma mark - Life Cycle Methods

- (void)viewDidLoad {
    [super viewDidLoad];
    _hostName = @"itunes.apple.com";
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachablityChanged:) name:kReachabilityChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(searchResultRecv:) name:@"dataRcvMsg" object:nil];
    hostReach = [Reachability reachabilityWithHostname:_hostName];
    [hostReach startNotifier];
    
    internetReach = [Reachability reachabilityForInternetConnection];
    [internetReach startNotifier];
    
    wifiReach = [Reachability reachabilityForLocalWiFi];
    [wifiReach startNotifier];
    
    _resultsArray = [[NSMutableArray alloc] init];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardMoved:) name:UIKeyboardDidChangeFrameNotification object:nil];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
