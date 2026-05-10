#!/bin/bash
#if [ $5 = "ENG" ]; then 
#	sed -i "s/         LANG                                  = 'ENG';/\/       LANG                                  = 'ENG';/" vc.pas
#fi
	sed -i  "s/'$1'/'$2'/" vc.pas
cd build
sed -i  "s/'$3'/'$4'/" full.nsi
cd  ..
dcc32 -O+ -H+ -J- -I- tr4w.dpr
cd d:/newsrc/TR4W/build

./upx ../target/tr4w.exe --lzma
cd d:/"Program Files"/NSIS
./makensis.exe d:/newsrc/tr4w/build/full.nsi
cd d:/newsrc/tr4w/src


