#include "PreferenceHeaders.h"

@implementation BetterAlarmTimerController

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [self loadSpecifiersFromPlistName:@"Timer" target:self];
	}

	return _specifiers;
}

@end