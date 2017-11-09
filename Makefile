include theos/makefiles/common.mk

TWEAK_NAME = SlackHistory
SlackHistory_FILES = /mnt/d/codes/SlackHistory/Tweak.xm
SlackHistory_FRAMEWORKS = CydiaSubstrate Foundation UIKit
SlackHistory_CFLAGS = -fobjc-arc
SlackHistory_LDFLAGS = -Wl,-segalign,4000

SlackHistory_ARCHS = armv7 arm64
export ARCHS = armv7 arm64

include $(THEOS_MAKE_PATH)/tweak.mk
