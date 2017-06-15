#!/bin/bash
# 
# Install the EM software and setup the environment for  LINUX
#
pwd=h
prefix=/home/hadoop/Users/lab_plc/progs
echo "${pwd}" | sudo -S mkdir -p  "${prefix}"
if [ ! -d "${prefix}/spiderweb/" ]; then
	    echo "downloading tar"
        echo "${pwd}" | sudo -S wget --directory-prefix=${prefix}/spiderweb/ https://spider.wadsworth.org/spider_doc/spider/download/spiderweb.22.03.tar.gz
        echo "${pwd}" | sudo -S tar zxvf ${prefix}/spiderweb/spiderweb.22.03.tar.gz -C ${prefix}/spiderweb/
        echo "${pwd}" | sudo -S rm -f ${prefix}/spiderweb/spiderweb.22.03.tar.gz
fi
cd ${prefix}/spiderweb/spider/src
make -f Makefile_linux
export SPIDER_DIR="${prefix}/spiderweb/spider"
export SPBIN_DIR="$SPIDER_DIR/bin/"
export SPMAN_DIR="$SPIDER_DIR/man/"
export SPPROC_DIR="$SPIDER_DIR/proc/"
export PATH="${SPIDER_DIR}/bin:${PATH}" 
cd ${prefix}/spiderweb/spider/bin 	
echo "${pwd}" | sudo -S mv spider_linux spider
echo "${pwd}" | sudo -S grep -q -F 'export PATH=/home/hadoop/Users/lab_plc/progs/spiderweb/spider/bin:$PATH' ~/.bashrc || echo 'export PATH=/home/hadoop/Users/lab_plc/progs/spiderweb/spider/bin:$PATH' >> ~/.bashrc
echo "${pwd}" | sudo -S ln -sf /Users/lab_plc/progs/spiderweb/spider/bin/spider /usr/local/bin/spider

