export TARGET = iphone:clang:latest
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

after-install::
	install.exec "killall -9 mediaserverd"
