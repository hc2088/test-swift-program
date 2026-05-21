#import <UIKit/UIKit.h>

@class ADFeedItem;

NS_ASSUME_NONNULL_BEGIN

@interface ADAsyncCardView : UIView

@property (nonatomic, strong, nullable) ADFeedItem *item;
- (void)resetForReuse;

@end

NS_ASSUME_NONNULL_END
