#!/bin/bash

set -eu

aws 

aws s3 cp "*.rpm" "s3://${STACK_CloudFormerRepositorioRPM}/rpms/"
