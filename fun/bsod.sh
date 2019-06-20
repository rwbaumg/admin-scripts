#!/bin/bash
# For more BSoDs check http://ro.wikipedia.org/wiki/Blue_Screen_of_Death/Simulare
echo -ne "\033[1;37m" #white text
echo -ne "\033[44m"   #blue bg
echo -ne "\033[0;0H"  #Start of screen
echo -ne "\033[2J"    #cls

echo
echo
echo

echo -e "                                 \033[0;34m\033[47mWindows\033[0;1m"
echo -ne "\033[1;37m" #white text
echo -ne "\033[44m"   #blue bg
echo -e "   A fatal exception OE has occured at 0028:C0011E36 in VXD VMM(01) +\033[44m\033[K"
echo "   00010E36. The current application will be terminated.
   *  Press any key to terminate the current application
   *  Press CTRL+ALT+DEL again to restart your computer. You will
      lose any unsaved information in all applications.
"
echo -e "                         Press any key to continue _\033[0;0m"

echo
echo
echo
echo -ne "\033[999B"
read -r
