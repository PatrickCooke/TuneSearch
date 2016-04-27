//
//  ResultsCollectionViewCell.h
//  TuneSearch
//
//  Created by Patrick Cooke on 4/27/16.
//  Copyright © 2016 Patrick Cooke. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ResultsCollectionViewCell : UICollectionViewCell

@property(nonatomic,weak) IBOutlet UIImageView *albumArtImageView;
@property(nonatomic,weak) IBOutlet UILabel     *TrackLabel;
@property(nonatomic,weak) IBOutlet UILabel     *ArtistLabel;

@end
