#include "PreferenceHeaders.h"

@implementation BetterAlarmAlarmsController

- (NSArray *)specifiers {
	if (!_specifiers) {
		NSMutableArray *mutableSpecifiers = [[self loadSpecifiersFromPlistName:@"Alarms" target:self] mutableCopy];

		NSUserDefaults *preferences = [[NSUserDefaults alloc] initWithSuiteName:@"com.noisyflake.betteralarm"];

		for (PSSpecifier *spec in [mutableSpecifiers reverseObjectEnumerator]) {
			if ([spec.properties[@"id"] isEqual:@"smartSnoozeSlider"]) {
				if (![preferences boolForKey:@"alarmSmartSnooze"]) [mutableSpecifiers removeObject:spec];
			}

			if ([spec.properties[@"id"] isEqual:@"buttonSizeGroup"] || [spec.properties[@"id"] isEqual:@"buttonSizeSlider"]) {
				if ([preferences boolForKey:@"alarmSmartSnooze"]) [mutableSpecifiers removeObject:spec];
			}

			if ([spec.properties[@"id"] isEqual:@"alarmConfirmationType"]) {
				if (![preferences boolForKey:@"alarmConfirmation"]) [mutableSpecifiers removeObject:spec];
			}
		}

		_specifiers = mutableSpecifiers;
	}

	return _specifiers;
}

- (void)setSmartSnooze:(id)value specifier:(PSSpecifier*)specifier {
	[super setPreferenceValue:value specifier:specifier];

	if ([value boolValue] == YES) {
		if ([self specifierForID:@"smartSnoozeSlider"] == nil) {
			NSArray *specifiers = [self loadSpecifiersFromPlistName:@"Alarms" target:self];
			for (PSSpecifier *spec in specifiers) {
				if ([spec.properties[@"id"] isEqual:@"smartSnoozeSlider"]) {
					[self insertSpecifier:spec afterSpecifierID:@"smartSnoozeToggle" animated:YES];
					break;
				}
			}
		}
		[self removeSpecifierID:@"buttonSizeGroup" animated:YES];
		[self removeSpecifierID:@"buttonSizeSlider" animated:YES];
	} else {
		[self removeSpecifierID:@"smartSnoozeSlider" animated:YES];

		if ([self specifierForID:@"buttonSizeSlider"] == nil) {
			NSArray *specifiers = [self loadSpecifiersFromPlistName:@"Alarms" target:self];
			for (PSSpecifier *spec in specifiers) {
				if ([spec.properties[@"id"] isEqual:@"buttonSizeGroup"]) {
					[self insertSpecifier:spec afterSpecifierID:@"smartSnoozeToggle" animated:YES];
				}
				if ([spec.properties[@"id"] isEqual:@"buttonSizeSlider"]) {
					[self insertSpecifier:spec afterSpecifierID:@"buttonSizeGroup" animated:YES];
				}
			}
		}

	}
}

- (void)setConfirmation:(id)value specifier:(PSSpecifier*)specifier {
	[super setPreferenceValue:value specifier:specifier];

	if ([value isEqualToString:@"qrcode"]) {
		UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Important"
									message: @"Make sure to print out the QR code found in the main menu before using this option. You can't disable the alarm without it!"
									preferredStyle:UIAlertControllerStyleAlert];

		[alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];

		[self presentViewController:alert animated:YES completion:nil];
	}
}

@end