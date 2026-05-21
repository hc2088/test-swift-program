#import "ADDemoCell.h"
#import "ADAsyncCardView.h"
#import "ADFeedItem.h"
#import "ADSyncCardView.h"
#import "ADUIKitCardView.h"
#import "ADYYAsyncCardView.h"

@interface ADDemoCell ()
@property (nonatomic, strong) UIView *cardView;
@end

@implementation ADDemoCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = [UIColor colorWithRed:0.92 green:0.94 blue:0.97 alpha:1.0];
        self.contentView.backgroundColor = self.backgroundColor;

        if ([reuseIdentifier containsString:@"LayerClass"]) {
            _cardView = [[ADYYAsyncCardView alloc] initWithFrame:CGRectZero];
        } else if ([reuseIdentifier containsString:@"UIKit"]) {
            _cardView = [[ADUIKitCardView alloc] initWithFrame:CGRectZero];
        } else if ([reuseIdentifier containsString:@"Async"]) {
            _cardView = [[ADAsyncCardView alloc] initWithFrame:CGRectZero];
        } else {
            _cardView = [[ADSyncCardView alloc] initWithFrame:CGRectZero];
        }
        _cardView.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:_cardView];

        [NSLayoutConstraint activateConstraints:@[
            [_cardView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:16.0],
            [_cardView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-16.0],
            [_cardView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:6.0],
            [_cardView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-6.0]
        ]];
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    if ([self.cardView respondsToSelector:@selector(resetForReuse)]) {
        [(id)self.cardView resetForReuse];
    }
}

- (void)configureWithItem:(ADFeedItem *)item {
    if ([self.cardView respondsToSelector:@selector(setItem:)]) {
        [(id)self.cardView setItem:item];
    }
}

@end
