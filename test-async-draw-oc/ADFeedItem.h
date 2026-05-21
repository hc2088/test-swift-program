#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ADFeedItem : NSObject

@property (nonatomic, copy, readonly) NSString *title;
@property (nonatomic, copy, readonly) NSString *subtitle;
@property (nonatomic, copy, readonly) NSString *badge;
@property (nonatomic, copy, readonly) NSArray<NSNumber *> *bars;
@property (nonatomic, assign, readonly) CGFloat hue;
@property (nonatomic, assign, readonly) NSUInteger version;

+ (NSArray<ADFeedItem *> *)demoItemsWithCount:(NSInteger)count version:(NSUInteger)version;

@end

NS_ASSUME_NONNULL_END
