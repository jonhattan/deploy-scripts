#!/bin/bash

#set -x

E_BADARGS=65

EXPECTED_ARGS=4

if [ $# -ne $EXPECTED_ARGS ]
then
  echo " This script expect $EXPECTED_ARGS arguments instead of $#"
  exit $E_BADARGS
fi

MV=$(which mv)
RM=$(which rm)
DATE=$(which date)
SED=$(which sed)
CAT=$(which cat)
DRUSH=$(which drush)


### CONFIG
DEP_NAME=$1
DEP_BRANCH=$2
DEP_USER=$3
MAKEFILE_NAME=$4

. $($(which dirname) $($(which readlink) -f "$0"))/autodeploy-common.sh

# Clonar RAMA REPO con submoduless en dir tmp
# clone-with-subs.sh $REPO $BRANCH $TARGET
. $LIB/clone-with-subs.sh $REPO_BARE $DEP_BRANCH $TMP_DIR

# Build 1
BUILD_DIR="$TMP_DIR/tmp"
COLUMNS=72 $DRUSH make $TMP_DIR/$MAKEFILE_NAME $BUILD_DIR
#BUILD_SITES_DIR="$TMP_DIR/tmp2"
#COLUMNS=72 $DRUSH make  --contrib-destination --working-copy --no-core $TMP_DIR/drupal-org.make $BUILD_SITES_DIR
#$MV -a $BUILD_SITES_DIR/* $BUILD_DIR/sites/all/

# Copiar files y settings
# copy-files-settings.sh $SOURCE $TARGET
. $LIB/drupal-copy-files-settings.sh $DST_DIR $BUILD_DIR

# Arreglar permisos
# fix-drupal-perms.sh $TARGET
. $LIB/drupal-fix-perms.sh $BUILD_DIR

# Firmar Robots
REPO_HASH=$($CAT $TMP_DIR/.git_hash)
REPO_DATE=$($CAT $TMP_DIR/.git_date)
SIGN="# Environment generated by $DEP_USER from $DEP_BRANCH (hash: $REPO_HASH, date: $REPO_DATE, make-file: $MAKEFILE_NAME) for site $SITE_NAME on $($DATE '+%Y-%m-%d %H:%M %Z')"
$SED  -i  '1{s|^|'"${SIGN}\n"'|}' $BUILD_DIR/robots.txt

# Eliminar archivos no para produccion
$RM $BUILD_DIR/.git*

# Loggear despliegue
LOG_DIR=$($(which dirname) "${LOG_FILE}")
if [ ! -d $LOG_DIR ]; then
  mkdir -p $LOG_DIR
fi
echo -e "$($DATE '+%Y-%m-%d %H:%M %Z')\t$DEP_BRANCH\t$REPO_DATE\t$REPO_HASH\t$DEP_USER" >> $LOG_FILE

$RM -r $DST_DIR
$MV $BUILD_DIR $DST_DIR
$RM -r $TMP_DIR

# Reload apache
$APA2CTL restart

# Update y revert de features
COLUMNS=72 $DRUSH -r $DST_DIR -l $SITE_NAME cc all
COLUMNS=72 $DRUSH -r $DST_DIR -l $SITE_NAME updatedb -y
#COLUMNS=72 $DRUSH -r $DST_DIR -l $SITE_NAME fra -y
COLUMNS=72 $DRUSH cache-clear drush
COLUMNS=72 $DRUSH -r $DST_DIR -l $SITE_NAME features-revert-all -y

# Borrar caches
COLUMNS=72 $DRUSH -r $DST_DIR -l $SITE_NAME cc all
#TODO: Add varnish clear support via autodeploy-common
#varnishadm -T :6082 -S /etc/varnish/secret "ban req.http.host ~ '${SITE_NAME}' && req.url ~ '^/'"

exit 0
