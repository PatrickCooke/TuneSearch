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

@interface ViewController ()

@property (nonatomic, strong)        NSString *hostName;
@property (nonatomic, strong)        NSMutableArray *resultsArray;
@property (nonatomic, weak) IBOutlet UITextField *searchTextField;
@property (nonatomic, weak) IBOutlet UITableView  *resultsTableView;
@property (nonatomic, weak) IBOutlet UISearchBar *songSearchBar;
@property (nonatomic, weak) IBOutlet UIView         *songSearchView;

@end

@implementation ViewController

#pragma mark - Global Variables

Reachability *hostReach;
Reachability *internetReach;
Reachability *wifiReach;
bool internetAvailable;
bool serverAvailable;
//bool showHide;

#pragma mark - Interactivity Methods

-(IBAction)showAndHideSearch:(id)sender {
    [_songSearchView setHidden:!_songSearchView.hidden];
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
                    Song *newsong = [[Song alloc] initWithArtistName:[resultsDict objectForKey:@"artistName"] andSongTitle:[resultsDict objectForKey:@"trackName"] andalbumTitle:[resultsDict objectForKey:@"collectionName"] andAlbumtArtFileName:[resultsDict objectForKey:@"artworkUrl60"] andtrackExplicit:[resultsDict objectForKey:@"trackExplicitness"] andtrackId:[NSString stringWithFormat:@"%@.jpg",[resultsDict objectForKey:@"trackId"]] anditemKind:[resultsDict objectForKey:@"kind"] andpreviewUrl:[resultsDict objectForKey:@"previewURL"] andpreviewName:[NSString stringWithFormat:@"%@.m4a",[resultsDict objectForKey:@"trackId"]] anddescriptString:[resultsDict objectForKey:@"longDescription"]];
                    [_resultsArray addObject:newsong];
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    [_resultsTableView reloadData];
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

#pragma mark - Table View Methods

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSLog(@"count:%lu",(unsigned long)_resultsArray.count);
    return _resultsArray.count;
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ResultsViewCell *cell = (ResultsViewCell *)[tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    Song* currentTune = _resultsArray[indexPath.row];
    cell.trackTitleLable.text = currentTune.songTitle;
    cell.artistNameLable.text = currentTune.artistName;
    cell.albumTitleLable.text = currentTune.albumTitle;
    if ([self file:currentTune.trackId isInDirectory:NSTemporaryDirectory()]) {
        NSLog(@"Found %@",currentTune.trackId);
        cell.albumArtImageView.image = [UIImage imageNamed:[NSTemporaryDirectory() stringByAppendingPathComponent:currentTune.trackId]];
    } else {
        cell.albumArtImageView.image = nil;
        [self getImageFromServer:currentTune.trackId fromURL: currentTune.albumArtFileName atIndexPath:indexPath];
        NSLog(@"had to fetch %@", currentTune.trackId);
    }
    if ( [currentTune.trackExplicit isEqualToString:@"explicit"]) {
        cell.backgroundColor = [UIColor redColor];
    } else if ([currentTune.trackExplicit isEqualToString:@"notExplicit"]){
        cell.backgroundColor = [UIColor whiteColor];
    }
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath   {
    return 60.0;
}

#pragma mark - Prepare for Segueue

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    DetailsViewController *destController = [segue destinationViewController];
    NSIndexPath *indexpath = [_resultsTableView indexPathForSelectedRow];
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
        NSLog(@"local:%@ full:%@",localFileName,fullFileName);
        NSURL *fileURL = [NSURL URLWithString:fullFileName];
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
        [request setURL:fileURL];
        [request setCachePolicy:NSURLRequestReloadIgnoringCacheData];
        [request setTimeoutInterval:30.0];
        NSURLSession *session = [NSURLSession sharedSession];
        [[session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            NSLog(@"Image Length:%li error: %@",[data length],error);
            if (([data length] > 0) && (error == nil)) {
                NSString *savedFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:localFileName];
                UIImage *imageTemp = [UIImage imageWithData:data];
                if (imageTemp !=nil) {
                    [data writeToFile:savedFilePath atomically:true];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [_resultsTableView reloadRowsAtIndexPaths:@[indexpath] withRowAnimation:UITableViewRowAnimationAutomatic];
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
    [_resultsTableView reloadData];
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
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
