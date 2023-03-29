#import <UIKit/UIKit.h>
#import "ColorUtils.h"

@implementation UIColor (BetterAlarm)

+ (UIColor *)colorFromP3String:(NSString *)string {
    NSArray *components = [string componentsSeparatedByString:@" "];
    if ([components count] != 4) return UIColor.clearColor;

    return [UIColor colorWithDisplayP3Red:[components[0] floatValue] green:[components[1] floatValue] blue:[components[2] floatValue] alpha:[components[3] floatValue]];
}

- (UIColor *)betterAlarmLighterColor {
    CGFloat h, s, b, a;
    if ([self getHue:&h saturation:&s brightness:&b alpha:&a]) {
        return [UIColor colorWithHue:h saturation:s brightness:MIN(b * 1.4, 1.0) alpha:a];
    }
        
    return nil;
}

@end