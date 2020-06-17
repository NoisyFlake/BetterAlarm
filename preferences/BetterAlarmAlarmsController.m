#include "PreferenceHeaders.h"

@implementation BetterAlarmAlarmsController

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [self loadSpecifiersFromPlistName:@"Alarms" target:self];
	}

	return _specifiers;
}

@end