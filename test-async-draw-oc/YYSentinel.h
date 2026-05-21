//
//  YYSentinel.h
//  Extracted and trimmed from YYKit for standalone demo usage.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface YYSentinel : NSObject

@property (nonatomic, assign, readonly) int32_t value;

- (int32_t)increase;

@end

NS_ASSUME_NONNULL_END
