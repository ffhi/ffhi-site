##	gluon site.mk makefile example

##	GLUON_SITE_PACKAGES
#		specify gluon/openwrt packages to include here
#		The gluon-mesh-batman-adv-* package must come first because of the dependency resolution

GLUON_FEATURES := \
	autoupdater \
	ebtables-filter-multicast \
	ebtables-filter-ra-dhcp \
	ebtables-limit-arp \
	mesh-batman-adv-15 \
	mesh-vpn-fastd \
	radvd \
	alfred \
	respondd \
	status-page \
	web-advanced \
	web-wizard \
	web-private-wifi

GLUON_SITE_PACKAGES := \
	iwinfo \
	iptables \
	haveged

#       Removed packages
#	gluon-next-node \


# x86-generic
ifeq ($(GLUON_TARGET),x86-generic)
# support acpi shutdown for openwrt as VM
GLUON_SITE_PACKAGES += \
        kmod-button-hotplug
endif

# x86-64
ifeq ($(GLUON_TARGET),x86-64)
# support acpi shutdown for openwrt as VM
GLUON_SITE_PACKAGES += \
        kmod-button-hotplug
endif

GLUON_LANGS ?= de en

##	DEFAULT_GLUON_RELEASE
#		version string to use for images
#		gluon relies on
#			opkg compare-versions "$1" '>>' "$2"
#		to decide if a version is newer or not.

DEFAULT_GLUON_RELEASE := 0.9.0


##	GLUON_RELEASE
#		call make with custom GLUON_RELEASE flag, to use your own release version scheme.
#		e.g.:
#			$ make images GLUON_RELEASE=23.42+5
#		would generate images named like this:
#			gluon-ff%site_code%-23.42+5-%router_model%.bin

# Allow overriding the release number from the command line
GLUON_RELEASE ?= $(DEFAULT_GLUON_RELEASE)

# Default priority for updates.
GLUON_PRIORITY ?= 30
