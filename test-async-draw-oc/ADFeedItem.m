#import "ADFeedItem.h"

@interface ADFeedItem ()
@property (nonatomic, copy, readwrite) NSString *title;
@property (nonatomic, copy, readwrite) NSString *subtitle;
@property (nonatomic, copy, readwrite) NSString *badge;
@property (nonatomic, copy, readwrite) NSArray<NSNumber *> *bars;
@property (nonatomic, assign, readwrite) CGFloat hue;
@property (nonatomic, assign, readwrite) NSUInteger version;
@end

@implementation ADFeedItem

+ (NSArray<ADFeedItem *> *)demoItemsWithCount:(NSInteger)count version:(NSUInteger)version {
    NSMutableArray<ADFeedItem *> *items = [NSMutableArray arrayWithCapacity:count];

    for (NSInteger index = 0; index < count; index++) {
        NSUInteger seed = version * 131 + (NSUInteger)index * 17;
        NSMutableArray<NSNumber *> *bars = [NSMutableArray arrayWithCapacity:24];

        for (NSInteger barIndex = 0; barIndex < 24; barIndex++) {
            NSUInteger value = (seed + (NSUInteger)barIndex * 37) % 100;
            [bars addObject:@(0.18 + (CGFloat)value / 120.0)];
        }

        ADFeedItem *item = [[ADFeedItem alloc] init];
        item.version = version;
        item.hue = fmod((0.11 * index) + (0.07 * version), 1.0);
        item.bars = bars;
        item.badge = [NSString stringWithFormat:@"v%lu  item-%02ld", (unsigned long)version, (long)index];
        item.title = [NSString stringWithFormat:@"Async Raster Demo %02ld", (long)index];
        item.subtitle = [NSString stringWithFormat:@"seed=%lu  redraw=%lu  scroll this list and tap burst update. This card intentionally draws many bars, circles and rich text to simulate a relatively heavy custom rendering task.", (unsigned long)seed, (unsigned long)version];
        [items addObject:item];
    }

    return items;
}

@end
