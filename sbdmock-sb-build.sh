#!/bin/sh
#
# sbdmock-sb-build <packages>
#
# <packages> should be a list of package names
#
# Note that some package names are special:
#
#  GPE - this is turned into the list of packages that make up GPE
#
# Options:
#
#   --target <environment>
#
#     Scratchbox target to use for the build (for example SDK_22_ARMEL)
#
#   --sdk <codename>
#
#     specify codename for sdk, to pass to MUD.
#
#   --dir <subdir>
#
#     subdirectory of ~/v/sb-qemu/ to use for log and upload/
#
#     default is to use ~/v/sb-qemu itself
#
#   --release <release>
#
#     release version id.  Default is to leave it unchanged in the package files
#
#     <release> should be a release number in form <major>.<minor>-<debian-version>
#     or <major>.<minor>+ (the latter indicates the date should be included in the package version)
#
#   --date <date>
#
#     date to use for SVN fetches.  Default is "now"
#
#   --v <directory>
#
#     Ignored (v subdirectory is assumed to be already set up)
#
#   --repo <address> <distribution> <component>
#
#     repository information to add to apt sources list
#
#     Note that this option must be followed by exactly three arguments.
#     This option can be specified more than once.  Each repository is added as two lines:
#
#     deb <address> <distribution> <component>
#     deb-src <address> <distribution> <component>
#
#   --install <package>
#
#     install a package before starting the build
#
#     The package is installed using "apt-get install <package>".  The build continues
#     if the installation fails.
#
#     This option can be specified more than once.
#
#   --expected <number>
#
#     expected number of .deb's.  If this is specified, the script will
#     check for the expected number and, if so, will create a file called
#     'completed' in the upload directory.
#
#   --cont
#
#     continue a previous build
#     Note: the caller is responsible for having saved the ~/mud-builder/upload
#     directory if they want it, before calling this.  This option causes:
#     1) do not empty the target directory upload directory
#     2) install all packages lying around in mud-builder/upload
#     3) invokes mud with the --depend-nobuild option
#
# The upload directory is emptied and the packages are built using the specified date
#
# NOTE: this script assumes sbdmock is installed in ~/scratchbox/sbdmock/bin/sbdmock
#

setup=""
env=""
opts=""
while [ "${1:0:1}" = "-" ]
do
  if [ "$1" = "--uml" ]
      then
      # ignored
      shift 2
  elif [ "$1" = "--target" ]
      then
      env=$2
      shift 2
  elif [ "$1" = "--dir" ]
      then
      opts="$opts $1 $2"
      shift 2
  elif [ "$1" = "--sdk" ]
      then
      opts="$opts $1 $2"
      shift 2
  elif [ "$1" = "--expected" ]
      then
      opts="$opts $1 $2"
      shift 2
  elif [ "$1" = "--release" ]
      then
      opts="$opts $1 $2"
      shift 2
  elif [ "$1" = "--date" ]
      then
      opts="$opts $1 $2"
      shift 2
  elif [ "$1" = "--repo" ]
      then
      opts="$opts $1 $2 $3 $4"
      shift 4
  elif [ "$1" = "--install" ]
      then
      opts="$opts $1 $2"
      shift 2
  elif [ "$1" = "--v" ]
      then
      # ignored
      shift 2
  elif [ "$1" = "--cont" ]
      then
      opts="$opts $1"
      shift
  else
      echo "$0: Unrecognised option: $1"
      exit 1
  fi
done

if [ -z "$env" ]
then
    echo "*** --target must be specified to use sbdmock ***"
    exit 1
fi

config=$env

# Target-specific hacks
if [ -z "${env##SDK_50*}" ]
  then
  config="maemo-fremantle"
fi
if [ -z "${env##SDK_50_BETA2*}" ]
  then
  config="maemo-fremantle-beta2"
fi
if [ -z "${env##SDK_41*}" ]
  then
  config="maemo-diablo"
fi
if [ -z "${env##SDK_40*}" ]
  then
  config="maemo-chinook"
fi
if [ -z "${env##SDK_3*}" ]
  then
  config="maemo-bora"
fi
if [ -z "${env##SDK_22*}" ]
  then
  config="maemo-gregale"
fi
if [ -z "${env##SDK_20*}" ]
  then
  config="maemo-mistral"
fi
if [ -z "${env##*X86}" ] || [ -z "${env##*I386}" ]
  then
  config="${config}-i386-extras-devel"
fi
if [ -z "${env##*ARMEL}" ]
  then
  config="${config}-armel-extras-devel"
fi


# Scratchbox needs $USER defined but cron only defines LOGNAME
[ -z "$USER" ] && export USER=$LOGNAME

sb-conf killall
sb-conf killall --signal=9

echo ~/scratchbox/sbdmock/bin/sbdmock -r $config -c -- maemo/qemu-build $opts "$@"

~/scratchbox/sbdmock/bin/sbdmock -r $config -c -- maemo/qemu-build $opts "$@"

