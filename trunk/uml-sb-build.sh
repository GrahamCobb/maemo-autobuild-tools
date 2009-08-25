#!/bin/sh
#
# uml-sb-build <packages>
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
#   --uml <number>
#
#     number to assign to uml engine -- must be two hex digits.  Default is 01.
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
#     specifies the scratchbox home directory (parent of mud-builder)
#     Defaults to /home/scratchbox-apophis/users/cobb/home/cobb
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

if [ -d "/vranx-linux/home" ]
then
 v="/vranx-linux/home/scratchbox-apophis/users/cobb/home/cobb"
else
 v="/home/scratchbox-apophis/users/cobb/home/cobb"
fi
num="01"
env=""
opts=""
while [ "${1:0:1}" = "-" ]
do
  if [ "$1" = "--uml" ]
      then
      num=$2
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
      v=$2
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

if [ ! -d "$v" ]
then
  echo "V=$v DOES NOT EXIST"
  exit 2
fi

mkdir $v/tmp
tmpfile=`mktemp -p $v/tmp`

# Here are the commands which will be executed in the UML environment
cat <<EOF >$tmpfile
    #ls
    echo "*****************************************"
    echo "* Starting Scratchbox build             *"
    echo "*****************************************"
    sudo cp /etc/resolv.conf /scratchbox/etc/resolv.conf
    for t in /scratchbox/users/scratchbox/targets/*
    do
      sudo cp -v /etc/resolv.conf \$t/etc/
    done
EOF
    [ -z "$env" ] || echo scratchbox sb-conf select $env >>$tmpfile
cat <<EOF >>$tmpfile
    scratchbox v/qemu-build $opts "$@"
    #sleep 30s
    echo "*****************************************"
    echo "* Scratchbox build finished             *"
    echo "*****************************************"
    sudo shutdown -h now

EOF

chmod +rx $tmpfile

#~/qemu/uml --linux ./linux-grc-sb-32 --con0 none,fd:1 $num SB_V=$v SB_CMD=/media/host/$tmpfile
#~/qemu/uml --linux /usr/bin/linux.uml.maemo --con0 null,fd:1 $num SB_V=$v SB_CMD=/media/host/$tmpfile
~/qemu/uml --linux ./linux-grc-sb-32 --con0 null,fd:1 $num SB_V=$v SB_CMD=/media/host/$tmpfile
#~/qemu/uml --linux /home/cobb/qemu/my-uml-32/uml-maemo-2.6.26-1um/linux-source-2.6.26/linux --con0 null,fd:1 $num SB_V=$v SB_CMD=/media/host/$tmpfile
