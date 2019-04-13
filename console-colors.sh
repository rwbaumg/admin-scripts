#!/bin/bash
# show each of the available console colors

#for code in {0..255}; do
#  echo -e "\e[38;05;${code}m $code: This is a test string."
#done

for clbg in {40..47} {100..107} 49 ; do

  for clfg in {30..37} {90..87} 39 ; do

    for attr in 0 1 2 4 5 7 ; do
      echo -n -e "\e[${attr};${clbg};${clfg}m ^[${attr};${clbg};${clfg}m \e[0m"
    done
    echo

  done

done

#echo -n -e "\e[4;1m Test \e[0m"
#echo -n -e "\e[0;101;31m Test \e[0m"
#echo -e "\e[4m Test \e[0m"
