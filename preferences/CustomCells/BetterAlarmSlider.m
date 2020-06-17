#include "../PreferenceHeaders.h"

UILabel *rightLabel;
UILabel *leftLabel;

@implementation BetterAlarmSlider
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier specifier:(PSSpecifier *)specifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier specifier:specifier];

    if (self) {
        leftLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 11, 0, 0)];
        leftLabel.text = specifier.properties[@"leftLabel"];
        [leftLabel sizeToFit];
        [self.contentView addSubview:leftLabel];
        [self.contentView bringSubviewToFront:leftLabel];

        rightLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        rightLabel.text = specifier.properties[@"rightLabel"];
        [rightLabel sizeToFit];
        [self.contentView addSubview:rightLabel];
        [self.contentView bringSubviewToFront:rightLabel];
    }

    return self;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    [self.control setFrame:CGRectMake(leftLabel.frame.size.width + 25, self.control.frame.origin.y, self.control.frame.size.width - leftLabel.frame.size.width - rightLabel.frame.size.width - 20, self.control.frame.size.height)];

    [rightLabel setFrame:CGRectMake(self.control.frame.origin.x + self.control.frame.size.width + 10, 11, 0, 0)];
    [rightLabel sizeToFit];
}
@end