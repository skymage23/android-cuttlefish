FROM fedora:latest

#This is a cheap way to update the package indices.
#However, it returns non-zero if there are updates
#available, hence, we do this weirdness so our
#docker build isn't killed by updates.
RUN dnf check-update; \
retcode=$?; \
if [ $retcode -eq 0 ] || [ $retcode -eq 100 ]; then exit 0; else exit $retcode; fi

RUN dnf install -y python3
RUN dnf install -y rpm-build
