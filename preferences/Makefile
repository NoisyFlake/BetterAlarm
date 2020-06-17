include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = BetterAlarm

BetterAlarm_FILES = $(wildcard *.m CustomCells/*.m ../sources/ColorUtils.m)
BetterAlarm_INSTALL_PATH = /Library/PreferenceBundles
BetterAlarm_FRAMEWORKS = UIKit
BetterAlarm_PRIVATE_FRAMEWORKS = Preferences
BetterAlarm_LIBRARIES = sparkcolourpicker
BetterAlarm_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/BetterAlarm.plist$(ECHO_END)
