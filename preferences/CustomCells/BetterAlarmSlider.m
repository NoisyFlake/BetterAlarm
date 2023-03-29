#include "../PreferenceHeaders.h"

@implementation BetterAlarmSlider
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier specifier:(PSSpecifier *)specifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier specifier:specifier];

    if (self) {
        if (specifier.properties[@"leftLabel"]) {
            self.leftLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 11, 0, 0)];
            self.leftLabel.text = specifier.properties[@"leftLabel"];
            [self.leftLabel sizeToFit];
            [self.contentView addSubview:self.leftLabel];
            [self.contentView bringSubviewToFront:self.leftLabel];
        }

        if (specifier.properties[@"rightLabel"]) {
            self.rightLabel = [[UILabel alloc] initWithFrame:CGRectZero];
            self.rightLabel.text = specifier.properties[@"rightLabel"];
            [self.rightLabel sizeToFit];
            [self.contentView addSubview:self.rightLabel];
            [self.contentView bringSubviewToFront:self.rightLabel];
        }

        // iOS 16 fix
        for (NSLayoutConstraint *c in self.control.constraints) {
            [self.control removeConstraint:c];
        }

        [self.control layoutIfNeeded];
    }

    return self;
}
- (void)layoutSubviews {
    [super layoutSubviews];

    // Before iOS 16, we could simply set the frame of the control. However, iOS 16 introduces constraints that don't seem to be easily fixable, so instead we
    // modify the subview (visualElement), since it isn't affected by these constraints

    UISlider *slider = (UISlider *)self.control;
    UIView *visualElement = slider.subviews[0];
    
    if (self.specifier.properties[@"leftLabel"] && self.specifier.properties[@"rightLabel"]) {
        [visualElement setFrame:CGRectMake(self.leftLabel.frame.size.width + 10, visualElement.frame.origin.y, slider.frame.size.width - self.leftLabel.frame.size.width - self.rightLabel.frame.size.width - 20, visualElement.frame.size.height)];

        [self.rightLabel setFrame:CGRectMake(visualElement.frame.origin.x + visualElement.frame.size.width + 20, 11, 0, 0)];
        [self.rightLabel sizeToFit];
    }

    if (![self.specifier.properties[@"showValue"] boolValue]) return;
    
    for (UIView *subview in visualElement.subviews) {
        if ([subview isKindOfClass:NSClassFromString(@"UILabel")]) {
            UILabel *label = (UILabel *)subview;
            label.frame = CGRectMake(label.frame.origin.x, label.frame.origin.y, label.frame.size.width + 15, label.frame.size.height);
        }
    }
}
@end