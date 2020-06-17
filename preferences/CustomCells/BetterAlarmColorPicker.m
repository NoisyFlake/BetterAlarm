#include "../PreferenceHeaders.h"
#include "../../sources/ColorUtils.h"

@implementation BetterAlarmColorPicker

-(NSString *)previewColor {
    NSUserDefaults *prefs = [[NSUserDefaults alloc] initWithSuiteName:@"com.noisyflake.betteralarm"];
    return [prefs valueForKey:[self.specifier propertyForKey:@"key"]] ?: [self.specifier propertyForKey:@"default"];
}

-(void)createAccessoryView {
    _colorPreview = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 29, 29)];
    _colorPreview.layer.cornerRadius = 29 / 2;
    // _colorPreview.layer.borderWidth = 1;

    // _colorPreview.layer.borderColor = UIColor.systemGray2Color.CGColor;
    _colorPreview.layer.shadowOpacity = 0.5;
    _colorPreview.layer.shadowOffset = CGSizeZero;
    _colorPreview.layer.shadowRadius = 5.0;
    _colorPreview.layer.shadowColor = UIColor.systemGrayColor.CGColor;
}

-(void)updateCellDisplay {
    // Set necessary options for sparks colorpicker
    if ([self.options valueForKey:@"defaults"] == nil || [self.options valueForKey:@"fallback"] == nil) {
        [self.options setObject:@"com.noisyflake.betteralarm" forKey:@"defaults"];
        [self.options setObject:([self.specifier propertyForKey:@"default"] ?: @"#FFFFFF:1.00") forKey:@"fallback"];
    }

    [self.specifier setButtonAction:@selector(openColourPicker)];

    if (_colorPreview == nil) {
        [self createAccessoryView];
    }

    if (self.accessoryView != _colorPreview) {
        // Overwrite sparks colour preview with our custom one
        self.accessoryView = _colorPreview;
    }

    _colorPreview.backgroundColor = [UIColor betterAlarmRGBAColorFromHexString:[self previewColor]];
    
    CGFloat alpha = 0.0;
	[_colorPreview.backgroundColor getRed:nil green:nil blue:nil alpha:&alpha];
    _colorPreview.hidden = (alpha == 0);
}

@end
