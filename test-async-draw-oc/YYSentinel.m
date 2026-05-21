//
//  YYSentinel.m
//  Extracted and trimmed from YYKit for standalone demo usage.
//

#import "YYSentinel.h"
#import <stdatomic.h>

@implementation YYSentinel {
    atomic_int_least32_t _value;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        atomic_init(&_value, 0);
    }
    return self;
}

- (int32_t)value {
    return atomic_load_explicit(&_value, memory_order_relaxed);
}

- (int32_t)increase {
    return atomic_fetch_add_explicit(&_value, 1, memory_order_relaxed) + 1;
}

@end
