#import <UIKit/UIKit.h>

@class ADFeedItem;

NS_ASSUME_NONNULL_BEGIN

@interface ADDemoCell : UITableViewCell

- (void)configureWithItem:(ADFeedItem *)item;

@end

NS_ASSUME_NONNULL_END
