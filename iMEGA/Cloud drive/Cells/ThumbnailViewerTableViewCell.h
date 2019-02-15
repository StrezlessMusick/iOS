
#import <UIKit/UIKit.h>

@interface ThumbnailViewerTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *thumbnailImageView;
@property (weak, nonatomic) IBOutlet UIImageView *thumbnailPlayImageView;

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;

@property (weak, nonatomic) IBOutlet UILabel *addedByLabel;

@property (weak, nonatomic) IBOutlet UILabel *infoLabel;

@property (weak, nonatomic) IBOutlet UIImageView *incomingOrOutgoingImageView;
@property (weak, nonatomic) IBOutlet UIImageView *uploadOrVersionImageView;

@property (weak, nonatomic) IBOutlet UILabel *timeLabel;

@property (weak, nonatomic) IBOutlet UIView *thumbnailViewerView;

@property (strong, nonatomic) NSArray<MEGANode *> *nodesArray;

- (void)configureForRecentAction:(MEGARecentActionBucket *)recentActionBucket;

@end
