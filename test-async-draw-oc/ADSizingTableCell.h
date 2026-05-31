#import <UIKit/UIKit.h>

@class ADSizingCardContent;

NS_ASSUME_NONNULL_BEGIN

@interface ADSizingTableCell : UITableViewCell

+ (NSString *)reuseIdentifier;
- (void)configureWithContent:(ADSizingCardContent *)content;

@end

NS_ASSUME_NONNULL_END
