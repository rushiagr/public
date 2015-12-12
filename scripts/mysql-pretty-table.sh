#! /bin/sh

# Code to colour output copied from oh-my-zsh: https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh

# Use colors, but only if connected to a terminal, and that terminal
# supports them.
if which tput >/dev/null 2>&1; then
    ncolors=$(tput colors)
fi
if [ -t 1 ] && [ -n "$ncolors" ] && [ "$ncolors" -ge 8 ]; then
  RED="$(tput setaf 1)"
  GREEN="$(tput setaf 2)"
  YELLOW="$(tput setaf 3)"
  BLUE="$(tput setaf 4)"
  BOLD="$(tput bold)"
  NORMAL="$(tput sgr0)"
else
  RED=""
  GREEN=""
  YELLOW=""
  BLUE=""
  BOLD=""
  NORMAL=""
fi

if [ $(cat ~/.bashrc | grep -c ALIASMYSQL) -eq 1 ]; then
    # Alias already present
    exit 0
else
    cat >> ~/.bashrc <<EOF
# ALIASMYSQL
# Alias to make mysql tables more usable
alias mysql='mysql --pager="less --chop-long-lines --quit-if-one-screen --no-init"'
EOF
fi

# Create ~/.lesskey file if not already present
touch ~/.lesskey

if [ $(cat ~/.lesskey | grep -c ALIASMYSQL) -eq 1 ]; then
    # Alias already present
    exit 0
else
    cat >> ~/.lesskey <<EOF
# ALIASMYSQL
l noaction 10\e)
h noaction 10\e(
EOF
fi

lesskey

printf "${GREEN}You are all set to view MySQL tables the way you should :)${NORMAL}\n"
