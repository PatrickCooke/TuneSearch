//
//  Song.h
//  TuneSearch
//
//  Created by Patrick Cooke on 4/26/16.
//  Copyright © 2016 Patrick Cooke. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Song : NSObject

@property (nonatomic, strong) NSString *artistName;
@property (nonatomic, strong) NSString *songTitle;
@property (nonatomic, strong) NSString *albumTitle;
@property (nonatomic, strong) NSString *albumArtFileName;
@property (nonatomic, strong) NSString *trackExplicit;
@property (nonatomic, strong) NSString *trackId;



-(id) initWithArtistName: (NSString *)artistName andSongTitle: (NSString *)songTitle andalbumTitle:(NSString *)albumTitle andAlbumtArtFileName: (NSString *)albumArtFileName andtrackExplicit: (NSString *)trackExplicit andtrackId:(NSString *)trackId;

@end
