#!/bin/sh

# Type of script: unattended
# To be runned on: -
# To be runned by: root
# Arguments: $TARGET
# Local dependencies: - none -
# Remote dependencies: - none -
# Short description: A script to fix file permissions on a TARGET Symfony installations

E_BADARGS=65
E_BADDEPS=66
E_TARGET_DONT_EXISTS=68
E_UNSUPPORTED_FW_VERSION=69

EXPECTED_ARGS=1

#echo $0
if [ $# -ne $EXPECTED_ARGS ]
then
  echo " This script expect $EXPECTED_ARGS arguments instead of $#"
  exit $E_BADARGS
fi

FIND=$(which find)
CHMOD=$(which chmod)
CHOWN=$(which chown)
SED=$(which sed)

#TARGET=$1
TARGET=$(echo $1 | $SED -e "s/\/*$//")
: ${FRAMEWORK_VERSION:="1"}
echo "*** Fixing file permissions for $TARGET"

echo "*** Framework version: ${FRAMEWORK_VERSION} ***"

if [ ! -d $TARGET ]; then
  echo " ABORTED: Target $TARGET doesn't exists"
  exit $E_TARGET_DONT_EXISTS
fi

: ${OWNER:="root"}
: ${WWW_US:="www-data"}
: ${WWW_GR:="www-data"}


DIR=$TARGET
A_SET="${TARGET}/htdocs/protected/config/main.php"
A_SET_2="${TARGET}/htdocs/protected/config/console.php"
F_DIR_1="${TARGET}/htdocs/protected/runtime"
F_DIR_2="${TARGET}/htdocs/assets"

FIND_NO_F_DIRS="$FIND $DIR -wholename '$F_DIR_1' -prune -or -wholename '$F_DIR_2' -prune"

echo "*** Fixing permissions ***"
# Generales
#echo "find $DIR \( ! -user root -or ! -group $WWW_GR \)"
#$FIND $DIR -wholename "$F_DIR" -prune -or  \( ! -user root -or ! -group $WWW_GR \) -print
eval "$FIND_NO_F_DIRS -or  \( ! -user root -or ! -group $WWW_GR \) -exec $CHOWN root:$WWW_GR {} \;"
#echo "find $DIR \( -type d -and ! -perm u=rwx,g=rxs,o= \)"
#$FIND $DIR -wholename "$F_DIR" -prune -or \( -type d -and ! -perm u=rwx,g=rxs,o= \)
eval "$FIND_NO_F_DIRS -or \( -type d -and ! -perm u=rwx,g=rxs,o= \) -exec $CHMOD u=rwx,g=rxs,o= {} \;"
#echo "find $DIR \( -type f -and ! -perm u=rw,g=r,o= \)"
#$FIND $DIR -wholename "$F_DIR" -prune -or \( -type f -and ! -perm u=rw,g=r,o= \)
eval "$FIND_NO_F_DIRS -or \( -type f -and ! -perm u=rw,g=r,o= \) -exec $CHMOD u=rw,g=r,o= {} \;"

# Permisos Files
if [ -d $F_DIR_1 ]; then
  $CHMOD 2770 $F_DIR_1
  $FIND $F_DIR_1 \( ! -user $WWW_US -or ! -group $WWW_GR \) -exec $CHOWN $WWW_US:$WWW_GR {} \;
  $FIND $F_DIR_1 \( -type d -and ! -perm u=rwx,g=rwxs,o= \) -exec $CHMOD u=rwx,g=rwxs,o= {} \;
  $FIND $F_DIR_1 \( -type f -and ! -perm u=rw,g=rw,o= \) -exec $CHMOD u=rw,g=rw,o= {} \;
fi
if [ -d $F_DIR_2 ]; then
  $CHMOD 2770 $F_DIR_2
  $FIND $F_DIR_2 \( ! -user $WWW_US -or ! -group $WWW_GR \) -exec $CHOWN $WWW_US:$WWW_GR {} \;
  $FIND $F_DIR_2 \( -type d -and ! -perm u=rwx,g=rwxs,o= \) -exec $CHMOD u=rwx,g=rwxs,o= {} \;
  $FIND $F_DIR_2 \( -type f -and ! -perm u=rw,g=rw,o= \) -exec $CHMOD u=rw,g=rw,o= {} \;
fi

#Permisos Setings 440
if [ -e $A_SET ]; then
  $CHMOD 440 $A_SET
fi
if [ -e $A_SET_2 ]; then
  $CHMOD 440 $A_SET_2
fi

