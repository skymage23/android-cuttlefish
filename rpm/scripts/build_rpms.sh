#!/bin/bash

#
# Builds the Android Cuttlefish RPMs.  Building RPMs requires
# a bit more setup than DEB files. We do that here.
#

#
# Environment variable parameters:
# FORCE_RPM:    Force the build of the RPM packages on non-RHEL/Fedora
#               systems.
#
# AUTO_YES:     Assume "Yes" or "Y" for all interactive prompts.
#

function print_err {
    >&2 echo "Error: $1"
}

function die {
    if [ $# -lt 2 ]; then
        #Hello
        print_err 'Function: die. Message: Too few arguments.'
        exit 1
    fi

    if [ $# -gt 3 ]; then
        print_err 'Function: die. Message: Too many arguments.'
        exit 1
    fi
    
    #Regular expression checking adapted from
    #  https://stackoverflow.com/a/806923
    local retcode=1;
    local re='^[0-9]+$'
    if [ $# -gt 2 ]; then
        #Bash-ism. May not work on other shells.
        if [[ $3 =~ $re ]]; then
            retcode=$3
        else
            print_err 'Function: die. Message: Invalid return code provided.'
        fi 
    fi

    print_err "Function: $1. Message: $2"
    exit $retcode
}

PROJECT_TOP=""
function locate_project_top {
    local dir="$PWD"
    while [ "$PROJECT_TOP" == "" ]; do
        local re_top_check="android-cuttlefish$"
        for var in "$dir"/*; do
            if [ $var =~ $re_top_check ]; then
                PROJECT_TOP="$dir/$var";
                break
            fi
        done
        dir="$dir/.."
    done
    PROJECT_TOP="$(realpath $PROJECT_TOP)"
}

#Are we RHEL/Fedora?
function rhel_or_fedora {
    which dnf 2>&1 >/dev/null;
    return $?
}

function is_rpmdevtree_set_up {
    local retcode=0;

    [ ! -d "$HOME/rpmbuild" ] && retcode=1
    [ ! -d "$HOME/rpmbuild/BUILD" ] && retcode=1
    [ ! -d "$HOME/rpmbuild/BUILDROOT" ] && retcode=1
    [ ! -d "$HOME/rpmbuild/RPMS" ] && retcode=1
    [ ! -d "$HOME/rpmbuild/SOURCES" ] && retcode=1
    [ ! -d "$HOME/rpmbuild/SPECS" ] && retcode=1
    [ ! -d "$HOME/rpmbuild/SRPMS" ] && retcode=1
    
    return $retcode
}

function main {

    if ! rhel_or_fedora && [ "$FORCE_RPM" == ""]; then
        local message="$(cat <<<EOF
You are attempting to build the Cuttlefish RPM packages on a system
that is not Red Hat Enterprise Linux (RHEL) or Fedora. While this
is certainly possible, it is untested. Hence, we die here.
If you want to continue anyway, set FORCE_RPM to any value
and then invoke this script again.
EOF
)"
        die 'main' $message
    fi

    if ! which realpath 2>&1 >/dev/null; then
        #Different message here because "coreutils" missing could mean a bad OS install.
        #I want to encourage users to check on that rather than simply installing the package.
        die "main" "\"realpath\" is not installed. Make sure the \"coreutils\" package is installed."
    fi

    if ! which rpmbuild 2>&1 >/dev/null; then
        die 'main' "\"rpmbuild\" is not installed. Please run \"sudo dnf install rpmdevtools\"."
    fi

    if ! which rpmdev-setuptree 2>&1 >/dev/null; then
        die 'main' "\"rpmdev-setuptree\" is not installed. Please run \"sudo dnf install rpmdevtools\"."
    fi

    if ! is_rpmdevtree_set_up; then
        local prompt_answered='';
        while [ "$prompt_answered" == '' ]; do
            echo "RPM build environment not yet set up."
            echo "Run \"rpmdev-setuptree\" (this will set up"
            echo "the RPM development directory structure (root: rpmbuild)"
            echo -n "under your home directory)?: (Y/n): "

            read char
            echo
            echo
            if [ "$char" == "Y" ]; then     
                echo "Running \"rpmdev-setuptree\"."
                ! rpmdevp-setuptree && die 'main' "Failed to set up RPM build tree in \"$HOME\""
                prompt_answered="TRUE"
            elif [ "$char" == "n" -o "$char" == "N" ]; then
                ! die 'main' 'User has opted not to set up the RPM dev environment. We need to die.'
            fi
        done       
    fi

    locate_project_top

    local specs_dir="$HOME/rpmbuild/SPECS"
    local sources_dir="$HOME/rpmbuild/SOURCES"
}

if [ "$DEBUG" != "TRUE" ]; then
    main $@
    exit $?
fi