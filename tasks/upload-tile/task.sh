#!/bin/bash

FILE_PATH=`find / -name *.pivotal`

om -t https://$OPS_MGR_HOST -u $OPS_MGR_USR -p $OPS_MGR_PWD -k upload-product -p $FILE_PATH
