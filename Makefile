DEBUG = 0
FINALPACKAGE = 1

ARCHS = arm64 arm64e

include BaiduIMECleaner_Build.mk
include $(THEOS)/makefiles/common.mk

TWEAK_NAME = BaiduIMECleaner
BaiduIMECleaner_FILES = $(wildcard Hooks/*.xm Sources/*.m)
BaiduIMECleaner_CFLAGS = -fobjc-arc -I./Headers -I./Sources
BaiduIMECleaner_FRAMEWORKS = UIKit Foundation CoreFoundation
BaiduIMECleaner_LIBRARIES = substrate

include $(THEOS_MAKE_PATH)/tweak.mk
