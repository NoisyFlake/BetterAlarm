export TARGET = iphone:latest:14.0
export ARCHS = arm64 arm64e

INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = BetterAlarm

BetterAlarm_FILES = $(wildcard sources/*.x sources/*.m)
BetterAlarm_CFLAGS = -fobjc-arc
BetterAlarm_FRAMEWORKS = AVFoundation

include $(THEOS_MAKE_PATH)/tweak.mk
SUBPROJECTS += preferences
include $(THEOS_MAKE_PATH)/aggregate.mk
