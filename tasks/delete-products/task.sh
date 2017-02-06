#!/bin/bash

om -t https://$OPS_MAN_HOST -k -u $OPS_MAN_USER -p $OPS_MAN_PWD delete-installation
