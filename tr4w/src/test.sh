#!/bin/bash
#if [  -n "$5" ] ; then
#if [ "$5" == "ENG" ] ; then
awk   '(($1 =='LANG')&&($3 == "'ENG'")){$0 = "//"+$0}{print}' vc.pas > vc.out 
#echo "LANG='ENG';" | 
# sed  "s#^[[#space:]]\{9\}LANG *= *'ENG';.*#//&#" vc.pas > vc.out 
	sed "s:^\(\s*LANG\s*=\s*'ENG'\s*;\)://\1:" vc.pas > vc.out
#       sed -i "s/^LANG                                  = 'RUS'/\/\/       LANG                                  = 'RUS'/" vc.pas
#        sed -i "s/^LANG                                  = 'SER'/\/\/       LANG                                  = 'SER'/" vc.pas
#        sed -i "s/^LANG                                  = 'CZE'/\/\/       LANG                                  = 'CZE'/" vc.pas	
#	sed -i "s/^LANG                                  = 'ROM'/\/\/       LANG                                  = 'ROM'/" vc.pas
#        sed -i "s/^LANG                                  = 'CZE'/\/\/       LANG                                  = 'CZE'/" vc.pas
#fi
#fi

