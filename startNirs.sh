#!/bin/bash
cd `dirname ${BASH_SOURCE[0]}`
#cat <<EOF | matlab -nodesktop -nojvm 
cat <<EOF | matlab -nodesktop 
if ( exist('initPaths') ) initPaths; else run ../utilities/initPaths; end;
buffer_nirs('localhost',1973,'stimEventRate',0,'queueEventRate',0);
quit;
EOF
