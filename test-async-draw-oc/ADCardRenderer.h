#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class ADFeedItem;

NS_ASSUME_NONNULL_BEGIN

@interface ADCardRenderer : NSObject

+ (dispatch_queue_t)renderQueue;
+ (nullable UIImage *)imageForItem:(ADFeedItem *)item
                              size:(CGSize)size
                             scale:(CGFloat)scale
                         cancelled:(nullable BOOL (^)(void))cancelled;
+ (void)drawItem:(ADFeedItem *)item
          inRect:(CGRect)rect
       cancelled:(nullable BOOL (^)(void))cancelled;

@end

NS_ASSUME_NONNULL_END
