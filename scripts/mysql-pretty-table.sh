#! /bin/bash

if [[ $(cat ~/.bashrc | grep -c ALIASMYSQL) == 1 ]]; then
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

if [[ $(cat ~/.lesskey | grep -c ALIASMYSQL) == 1 ]]; then
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
