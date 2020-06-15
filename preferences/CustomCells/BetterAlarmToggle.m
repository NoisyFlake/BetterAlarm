#include "../PreferenceHeaders.h"

@implementation BetterAlarmToggle

-(instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier specifier:(PSSpecifier *)specifier {
	self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier specifier:specifier];

	if (self) [((UISwitch *)[self control]) setOnTintColor:kBETTERALARMCOLOR];

	return self;
}

@end
