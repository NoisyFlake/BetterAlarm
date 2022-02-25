#include "PreferenceHeaders.h"

@implementation BetterAlarmBaseController

- (void)viewDidLayoutSubviews {
	[super viewDidLayoutSubviews];

	self.navigationItem.navigationBar.tintColor = kBETTERALARMCOLOR;
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];

	if ([self isMemberOfClass:[BetterAlarmRootListController class]] && self.navigationController.viewControllers.count == 1) {
		// Remove the navigationBar tintColor as the user is about to leave our settings area
		self.navigationItem.navigationBar.tintColor = nil;
	}
}

-(UITableViewStyle)tableViewStyle {
	return (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"13.0")) ? 2 : [super tableViewStyle];
}

-(void)_returnKeyPressed:(id)arg1 {
	[self.view endEditing:YES];
	[super _returnKeyPressed:arg1];
}

@end
