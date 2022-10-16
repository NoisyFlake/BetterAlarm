#import <UIKit/UIKit.h>
#import "ColorUtils.h"

@implementation UIColor (BetterAlarm)

+(UIColor *)betterAlarmRGBAColorFromHexString:(NSString *)string {
    if(string == nil || string.length == 0) {
        return nil;
    }

    CGFloat alpha = 1.0;
    NSUInteger location = [string rangeOfString:@":"].location;
    NSString *hexString;

    if(location != NSNotFound) {
        alpha = [[string substringFromIndex:(location + 1)] floatValue];
        hexString = [string substringWithRange:NSMakeRange(0, location)];
    } else {
        hexString = [string copy];
    }

    unsigned rgbValue = 0;
    NSScanner *scanner = [NSScanner scannerWithString:string];

    if([hexString rangeOfString:@"#"].location == 0) {
        [scanner setScanLocation:1];
    }

    [scanner scanHexInt:&rgbValue];

    return [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16) / 255.0
                    green:((rgbValue & 0xFF00) >> 8) / 255.0
                    blue:(rgbValue & 0xFF) / 255.0
                    alpha:alpha];
}

- (UIColor *)betterAlarmLighterColor {
    CGFloat h, s, b, a;
    if ([self getHue:&h saturation:&s brightness:&b alpha:&a]) {
        return [UIColor colorWithHue:h saturation:s brightness:MIN(b * 1.4, 1.0) alpha:a];
    }
        
    return nil;
}

@end