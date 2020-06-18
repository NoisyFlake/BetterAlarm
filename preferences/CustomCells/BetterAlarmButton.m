#include "../PreferenceHeaders.h"

@implementation BetterAlarmButton

-(void) layoutSubviews {
	[super layoutSubviews];

	UIColor *textColor = kBETTERALARMCOLOR;
	if ([[self.specifier propertyForKey:@"textColor"] isEqual:@"regular"]) textColor = [UIColor respondsToSelector:@selector(labelColor)] ? UIColor.labelColor : UIColor.darkTextColor;
	if ([[self.specifier propertyForKey:@"textColor"] isEqual:@"disabled"]) textColor = UIColor.systemGrayColor;

	self.textLabel.textColor = textColor;
	self.textLabel.highlightedTextColor = textColor;
}

@end
