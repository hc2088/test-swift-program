#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ADSizingCardContent : NSObject

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *body;
@property (nonatomic, copy) NSString *imageCaption;
@property (nonatomic, strong) UIColor *tintColor;
@property (nonatomic, assign) BOOL showsImage;

+ (NSArray<ADSizingCardContent *> *)demoContents;

@end

@interface ADSizingBaseCardView : UIView

@property (nonatomic, strong, nullable) ADSizingCardContent *content;
@property (nonatomic, assign) CGFloat preferredMaxLayoutWidth;

+ (CGFloat)heightForContent:(ADSizingCardContent *)content width:(CGFloat)width;
+ (CGSize)sizeForContent:(ADSizingCardContent *)content fittingWidth:(CGFloat)width;
- (CGSize)sizeThatFits:(CGSize)size;
- (void)drawCardInRect:(CGRect)rect;

@end

@interface ADSizingSyncCardView : ADSizingBaseCardView
@end

@interface ADSizingAsyncCardView : ADSizingBaseCardView
- (void)resetAsyncDisplay;
@end

NS_ASSUME_NONNULL_END
