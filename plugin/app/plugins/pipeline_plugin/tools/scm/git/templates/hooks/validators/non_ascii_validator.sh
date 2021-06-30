#!/bin/bash

function encoding_validate(){
  LC_CTYPE=C $validator_dir/non-ascii-validator.py $file_name
}
