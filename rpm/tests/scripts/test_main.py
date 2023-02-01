#!/usr/bin/env python3

import os
import sys
import typing

def print_err(*args, **kwargs):
    print(*args, file=sys.stderr, **kwargs)    

def die(name: str, message: str, retcode: int):
    #Sanity check return code
    #Is an integer?
    if not isinstance(retcode, int):
        print_err("Function: die: ")
        sys.exit(1)
    print_err("Function: {name}, Message: {message}"
        .format(
            name=name, 
            message=message
        ))    
    sys.exit(1)

#os.walk doesn't make any sense here to me.
#we are not interested in scanning every
#subdirectory of '/'.
def locate_project_top() -> Tuple[bool, str]:
    retval=''
    dir = os.getcwd()
    found = False
    for node in os.scandir(dir):
        if node.name == "RPM_BUILD.md":
            retval=dir
            found = True
            break

    if found is True:
        return found, dir

    #This will probably break on Windows:
    while found is False and dir != '/':
        #Hello
        dir = os.path.abspath(os.path.join(dir, '..'))
        for node in os.scandir(dir):
            if node.name == "RPM_BUILD.md":
                retval=dir
                found=True
                break
    return found, retval

#Tests are ran using Docker containers.
#This simulates a fresh Fedora install
#for each test.

class TestContainer:
    def __init__(self, name: str, imageName: str):
        self.isRunning: bool = False
        self.name: str = name
        self.imageName: str = imageName


class TestEnvironment:
    def __init__(self):
        raise NotImplementedError
    def listTestImages(self):
        raise NotImplementedError
    def listTestContainers(self):
        raise NotImplementedError

def main():
    raise NotImplementedError


if __name__ == "__main__":
    main()
