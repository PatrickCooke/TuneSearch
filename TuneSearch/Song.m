//
//  Song.m
//  TuneSearch
//
//  Created by Patrick Cooke on 4/26/16.
//  Copyright © 2016 Patrick Cooke. All rights reserved.
//

#import "Song.h"

@implementation Song

- (id) initWithArtistName:(NSString *)artistName andSongTitle:(NSString *)songTitle andalbumTitle:(NSString *)albumTitle andAlbumtArtFileName:(NSString *)albumArtFileName andtrackExplicit:(NSString *)trackExplicit andtrackId:(NSString *)trackId anditemKind:(NSString *)itemKind andpreviewUrl:(NSString *)previewUrl andpreviewName:(NSString *)previewName anddescriptString:(NSString *)descriptString
{
    self = [super init];
    if (self) {
        self.artistName = artistName;
        self.songTitle = songTitle;
        self.albumTitle = albumTitle;
        self.albumArtFileName = albumArtFileName;
        self.trackExplicit = trackExplicit;
        self.trackId = trackId;
        self.itemKind = itemKind;
        self.previewUrl = previewUrl;
        self.previewName = previewName;
        self.descriptString = descriptString;
    }
    return self;
}

@end
