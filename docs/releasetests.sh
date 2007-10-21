#!/bin/sh
# vim:tw=0:ts=4:sw=4

# this is a test script to run everything through its paces before you do a
# release. The basic idea is:

# 1) make distcheck to ensure that all autoconf stuff is setup properly
# 2) build and install mock rpm.
# 3) then use that version of mock to recompile the mock srpm for all supported distros.

# This test will only run on a machine with full access to internet.
# might work with http_proxy= env var, but I havent tested that.

set -e
set -x

DIR=$(cd $(dirname $0); pwd)
TOP_SRCTREE=$DIR/../
cd $TOP_SRCTREE

#make distclean ||:

#./configure
#make distcheck
make rpm

RPM=$(ls mock*.rpm | grep -v src.rpm | grep -v debuginfo)

sudo rpm -e mock
sudo rpm -Uvh --replacepkgs $RPM

sudo rm -rf $TOP_SRCTREE/mock-unit-test
for i in $(ls /etc/mock | grep .cfg | grep -v default | grep -v ppc); do
    mock --resultdir=$TOP_SRCTREE/mock-unit-test --uniqueext=unittest rebuild mock-*.src.rpm  -r $(basename $i .cfg)
done

# test orphanskill
gcc -o docs/daemontest docs/daemontest.c

(pgrep daemontest && echo "Exiting because there is already a daemontest running." && exit 1) || :
testConfig=fedora-7-x86_64
mock -r $testConfig init
cp docs/daemontest /var/lib/mock/$testConfig/root/tmp/
mock -r $testConfig --no-clean -- chroot /tmp/daemontest
(pgrep daemontest && echo "Daemontest FAILED. found a daemontest process running after exit." && exit 1) || :