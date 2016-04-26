//
//  ResultsViewCell.h
//  TuneSearch
//
//  Created by Patrick Cooke on 4/26/16.
//  Copyright © 2016 Patrick Cooke. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ResultsViewCell : UITableViewCell

@property(nonatomic, weak) IBOutlet UILabel     *trackTitleLable;
@property(nonatomic, weak) IBOutlet UILabel     *artistNameLable;
@property(nonatomic, weak) IBOutlet UILabel     *albumTitleLable;
@property(nonatomic, weak) IBOutlet UIImageView *albumArtImageView;

@end

