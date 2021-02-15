#!/bin/bash
sed -i  "s/.TR4W_CURRENTVERSION_NUMBER.*/  TR4W_CURRENTVERSION_NUMBER            = $1 ;  /p" vc.pas
