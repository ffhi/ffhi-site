##	gluon site.mk makefile example

##	DEFAULT_GLUON_RELEASE
#		version string to use for images
#		gluon relies on
#			opkg compare-versions "$1" '>>' "$2"
#		to decide if a version is newer or not.

GLUON_MULTIDOMAIN=1

# Autoupdater im Image standardmäßig an (Gluon: ohne diese Variable ist er aus). Ein Knoten holt nur Updates, die mit den
# Schlüsseln seines Zweigs signiert sind (site.conf, good_signatures). Der Besitzer kann ihn im Konfigurationsmodus abschalten.
GLUON_AUTOUPDATER_ENABLED ?= 1

#DEFAULT_GLUON_RELEASE := 0.6+exp$(shell date '+%Y%m%d')
# BUILD_DATE setzt die CI einmal fuer alle Jobs, damit Images und Manifest dasselbe Release tragen
DEFAULT_GLUON_RELEASE := WG-0.8Alpha+stable$(if $(BUILD_DATE),$(BUILD_DATE),$(shell date '+%Y%m%d'))
# Variables set with ?= can be overwritten from the command line

##	GLUON_RELEASE
#		call make with custom GLUON_RELEASE flag, to use your own release version scheme.
#		e.g.:
#			$ make images GLUON_RELEASE=23.42+5
#		would generate images named like this:
#			gluon-ff%site_code%-23.42+5-%router_model%.bin

GLUON_RELEASE ?= $(DEFAULT_GLUON_RELEASE)

# Default priority for updates.
GLUON_PRIORITY ?= 0

# Region code required for some images; supported values: us eu
GLUON_REGION ?= eu

# Languages to include
GLUON_LANGS ?= de en
