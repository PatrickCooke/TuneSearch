//
//  Song.m
//  TuneSearch
//
//  Created by Patrick Cooke on 4/26/16.
//  Copyright © 2016 Patrick Cooke. All rights reserved.
//

#import "Song.h"

@implementation Song

- (id) initWithArtistName:(NSString *)artistName andSongTitle:(NSString *)songTitle andalbumTitle:(NSString *)albumTitle andAlbumtArtFileName:(NSString *)albumArtFileName andtrackExplicit:(NSString *)trackExplicit andtrackId:(NSString *)trackId {
    self = [super init];
    if (self) {
        self.artistName = artistName;
        self.songTitle = songTitle;
        self.albumTitle = albumTitle;
        self.albumArtFileName = albumArtFileName;
        self.trackExplicit = trackExplicit;
        self.trackId = trackId;
    }
    return self;
}

@end
