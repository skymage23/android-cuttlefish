#!/bin/bash

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
    local retcode=0
    local dir="$PWD"
    local re_top_check="android-cuttlefish$"
    local next_dir=''
    PROJECT_TOP=""
    while [ "$PROJECT_TOP" == "" ]; do
        for var in "$dir"/*; do
            if [ $var =~ $re_top_check ]; then
                PROJECT_TOP="$dir/$var";
                break
            fi
        done

        next_dir="$(realpath $dir/..)"
        if [ "$dir" == "$next_dir" ]; then
            #dir and next_dir are equal.
            #This only happens if both are "/",
            #meaning we have traversed to the
            #top of the filesystem tree and
            #still haven't found the project
            #root directory.
            retcode=1
            break;
        fi
        dir=$next_dir
    done

    return $retcode
}

declare -A DOCKER_TEST_IMAGES;
function construct_test_image_list {
   local dockerfile_dir="$PROJECT_TOP/rpm/tests/dockerfiles"
   if [ ! -d "$dockerfile_dir" ]; then
       return 1;
   fi

   for dir in "$dockerfile_dir/*"; do
       #Hello:
       DOCKER_TEST_IMAGES["$dir"]="$dockerfile_dir/$dir"
   done
}

function build_test_images {
    local container_name=''
    for var in ${DOCKER_TEST_IMAGES[@]}; do
        container_name="$(basename $var)"
        docker build -f "$var" -t "$container_name:latest"
        if [ $? -ne 1 ]; then
            print_err "Unable to create Docker container \"$container_name\"."
            return 1
        fi
    done
    return 0;
}

function construct_global_test_environment {
    ! locate_project_top && die 'construct_global_test_environment' \
    'Unable to locate the project root directory.'

    ! construct_test_image_list && die 'construct_global_test_environment' \
    'Unable to construct list of Docker testing containers.'

    #Check if DOCKER_CONTAINERS is empty:
    if [ ${#DOCKER_TEST_IMAGES[@]} -eq 0 ]; then
        local message="$(cat <<<EOF
Unable to find the dockerfiles needed for testing.
Please re-sync your local repository fork,
or reset it to a known good commit.        
)"
        die "main" "$message"
    fi
    
    ! build_test_images && die 'construct_global_test_environment' \
    'Unable to construct Docker testing containers.'
}

function destroy_global_test_environment {

}

function main {
    if ! which docker 2>&1 >/dev/null; then
        die 'main' 'Docker is needed for testing, but it is not installed.'
    fi   
}

if [ "$DEBUG" != "TRUE" ]; then
    main $@
    exit $?
fi