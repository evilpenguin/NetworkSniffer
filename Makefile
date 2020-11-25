THEOS_DEVICE_IP = 127.0.0.1
THEOS_DEVICE_PORT = 2222
DEBUG = 1

include $(THEOS)/makefiles/common.mk

TARGET := iphone:10.0
ARCHS := armv7 arm64 arm64e
TWEAK_NAME = NetworkSniffer
$(TWEAK_NAME)_CFLAGS += -DTHEOS_LEAN_AND_MEAN -fobjc-arc
$(TWEAK_NAME)_FILES = \
	Tweak.xm \
	NSProtocol.m \

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
