//
//  ViewController.m
//  TuneSearch
//
//  Created by Patrick Cooke on 4/25/16.
//  Copyright © 2016 Patrick Cooke. All rights reserved.
//

#import "ViewController.h"
#import "Reachability.h"

@interface ViewController ()

@property (nonatomic, strong)        NSString *hostName;
@property (nonatomic, strong)        NSArray *resultsArray;
@property (nonatomic, weak) IBOutlet UITextField *searchTextField;
@property (nonatomic,weak)  IBOutlet UITableView  *resultsTableView;
@property (nonatomic, weak) IBOutlet UISearchBar *searchBar;

@end

@implementation ViewController

#pragma mark - Global Variables

Reachability *hostReach;
Reachability *internetReach;
Reachability *wifiReach;
bool internetAvailable;
bool serverAvailable;

#pragma mark - Interactivity Methods

-(IBAction)getFilePressed:(id)sender {
    [_searchBar resignFirstResponder];
    NSString *rawSearchString = [_searchBar.text lowercaseString];
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
                //NSLog(@"got data %@", data);
                //NSString *dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                //NSLog(@"Got String %@", dataString);
                NSJSONSerialization *json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
                NSLog(@"Got jSON %@", json);
                _resultsArray = [(NSDictionary *)json objectForKey:@"results"];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"dataRcvMsg" object:nil];
//                    [_resultsTableView reloadData];
                });
                for (NSDictionary *resultsDict in _resultsArray) {
                    NSLog(@"Results %@ - %@", [resultsDict objectForKey:@"artistName"],[resultsDict objectForKey:@"trackName"]);
                }
                
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
    return _resultsArray.count;
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    NSDictionary* currentTune = _resultsArray[indexPath.row];
    cell.textLabel.text = [currentTune objectForKey:@"trackName"];
    cell.detailTextLabel.text = [currentTune objectForKey:@"artistName"];
    if ( [[currentTune objectForKey:@"trackExplicitness"] isEqualToString:@"explicit"]) {
        cell.backgroundColor = [UIColor redColor];
    } else if ([[currentTune objectForKey:@"trackExplicitness"] isEqualToString:@"notExplicit"]){
        cell.backgroundColor = [UIColor whiteColor];
    }
    
    
    return cell;
}

#pragma mark - Searchbar Delegate

//-(BOOL)searchBarShouldReturn:(UISearchBar *)searchBar {
//    [self getFilePressed:self];
//    return true;
//}

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
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
