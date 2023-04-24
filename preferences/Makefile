INSTALL_TARGET_PROCESSES = Preferences

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = BetterAlarm

BetterAlarm_FILES = $(wildcard *.m CustomCells/*.m ../sources/ColorUtils.m)
BetterAlarm_INSTALL_PATH = $(THEOS_PACKAGE_INSTALL_PREFIX)/Library/PreferenceBundles
BetterAlarm_FRAMEWORKS = UIKit
BetterAlarm_PRIVATE_FRAMEWORKS = Preferences
BetterAlarm_CFLAGS = -fobjc-arc -DPACKAGE_VERSION='@"$(THEOS_PACKAGE_BASE_VERSION)"'

include $(THEOS_MAKE_PATH)/bundle.mk
