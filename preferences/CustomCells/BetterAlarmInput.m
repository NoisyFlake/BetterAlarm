#include "../PreferenceHeaders.h"

@implementation BetterAlarmInput

-(void)layoutSubviews {
    [super layoutSubviews];

    UIView *contentView = self.contentView;
    for (UIView *subview in contentView.subviews) {
        if ([subview isKindOfClass:[UITextField class]]) {
            UITextField *input = (UITextField *)subview;
            input.textAlignment = 2;
            input.clearsOnBeginEditing = YES;
            input.tintColor = kBETTERALARMCOLOR;

            UIToolbar* numberToolbar = [[UIToolbar alloc]initWithFrame:CGRectMake(0, 0, 320, 50)];
            numberToolbar.barStyle = UIBarStyleDefault;
            numberToolbar.items = @[[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                                [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                                [[UIBarButtonItem alloc]initWithTitle:@"Apply" style:UIBarButtonItemStyleDone target:self action:@selector(doneWithNumberPad)]];
            [numberToolbar sizeToFit];
            numberToolbar.tintColor = kBETTERALARMCOLOR;
            input.inputAccessoryView = numberToolbar;
        }
    }
}

-(void)doneWithNumberPad {
    [self._viewControllerForAncestor _returnKeyPressed:nil];
}

@end
