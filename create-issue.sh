#!/bin/bash
# Creates a fancy issue banner
# 
# The color of the characters printed on the console screen and their background color 
# can be controlled by ANSI escape sequences in this format...
#
# Escape [ style ; foreground ; background m
#
# These are the codes for style, foreground, and background...
#
# Style        Foreground     Background
# -----------------------------------------
#  NORMAL=0     FG_BLACK=30    BG_BLACK=40
#  BOLD=1       FG_RED=31      BG_RED=41
#  UNDERLINE=4  FG_GREEN=32    BG_GREEN=42
#  BLINK=5      FG_YELLOW=33   BG_YELLOW=43
#  REVERSE=7    FG_BLUE=34     BG_BLUE=44
#               FG_MAGENTA=35  BG_MAGENTA=45
#               FG_CYAN=36     BG_CYAN=46
#               FG_GRAY=37     BG_GRAY=47
#               FG_DEFAULT=39  BG_DEFAULT=49
# 
# NOTE: Not specifying a style, foreground, or background code in the
# escape sequence is the same as entering the normal or default value.
#
# Example to change the text color (foreground) to bold blue...
#
#    ^[[1;34m
#
# Example to change the text color to normal blue and change the background to cyan...
#
#    ^[[0;34;46m
#
# Example to revert back to the default style, text, and background...
#
#    ^[[0m
#
# agetty codes:
# ----------------------
# b   Insert the baudrate of the current line.
# d   Insert the current date.
# s   Insert the system name, the name of the operating system.
# l   Insert the name of the current tty line.
# m   Insert the architecture identifier of the machine, e.g., i686.
# n   Insert the nodename of the machine, also known as the hostname.
# o   Insert the domainname of the machine.
# r   Insert the release number of the kernel, e.g., 2.6.11.12.
# t   Insert the current time.
# u   Insert the number of current users logged in.
# U   Insert the string "1 user" or "<n> users" where <n> is the
#     number of current users logged in.
# v   Insert the version of the OS, e.g., the build-date etc.
# 
#####################################################################################

echo -e '\e[H\e[2J' > /etc/issue
echo -e '\e[1;33;40m' >> /etc/issue
echo '  ___       ___      __  ___            ___ ' >> /etc/issue
echo -e ' |  _|     / _ \\\    /_ |/ _ \\\  \e[1;31m\\s\e[1;33;40m   |_  |' >> /etc/issue
echo ' | |      | | | |_  _| | (_) |___        | |' >> /etc/issue
echo ' | |      | | | \\ \\/ / |\\__, / _ \\       | |' >> /etc/issue
echo ' | |      | |_| |>  <| |  / /  __/       | |' >> /etc/issue
echo ' | |_      \\___//_/\\_\\_| /_/ \\___|      _| |' >> /etc/issue
echo -e ' |___|  \e[1;32m\\r\e[1;33;40m  |___|' >> /etc/issue
echo -e '\e[0m' >> /etc/issue

#echo -e '\e[1;31mXen \e[1;32m\s \e[1;32m\\r' >> /etc/issue
echo -e '\e[1;39m\d \\t \e[1;39m::\e[1;39m \l' >> /etc/issue
echo '' >> /etc/issue

# fortune=$(/usr/games/fortune linux linuxcookie | /usr/games/cowsay -n)
# echo -e '\e[1;31m' + $fortune + '\e[0m' >> /etc/issue

echo -e '\e[1;31mWelcome \e[1;39mto \e[1;34m\\n' >> /etc/issue
echo -e '\e[0m' >> /etc/issue

# echo '' >> /etc/issue

######################################################################################
# echo -e '\e[1;34m  ___    ___      __  ___        ___ ' > /etc/issue
# echo ' |  _|  / _ \    /_ |/ _ \      |_  |' >> /etc/issue
# echo ' | |   | | | |_  _| | (_) |___    | |' >> /etc/issue
# echo ' | |   | | | \ \/ / |\__, / _ \   | |' >> /etc/issue
# echo ' | |   | |_| |>  <| |  / /  __/   | |' >> /etc/issue
# echo ' | |_   \___//_/\_\_| /_/ \___|  _| |' >> /etc/issue
# echo ' |___|                          |___|' >> /etc/issue
