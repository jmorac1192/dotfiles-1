#!/bin/bash

# the basics
: ${HOME=~}
: ${LOGNAME=$(id -un)}
: ${UNAME=$(uname)}

# complete hostnames from this file
: ${HOSTFILE=~/.ssh/known_hosts}

# readline config
: ${INPUTRC=~/.inputrc}

# ----------------------------------------------------------------------
#  SHELL OPTIONS
# ----------------------------------------------------------------------

# bring in system bashrc
if [ -r /etc/bashrc ]; then
    . /etc/bashrc
fi

# notify of bg job completion immediately
set -o notify

# shell opts. see bash(1) for details
shopt -s cdspell                 >/dev/null 2>&1
shopt -s extglob                 >/dev/null 2>&1
shopt -s histappend              >/dev/null 2>&1
shopt -s hostcomplete            >/dev/null 2>&1
shopt -s interactive_comments    >/dev/null 2>&1
shopt -u mailwarn                >/dev/null 2>&1
shopt -s no_empty_cmd_completion >/dev/null 2>&1

# disable new mail check
unset MAILCHECK

# disable core dumps
ulimit -S -c 0

# default umask
umask 0022

# ----------------------------------------------------------------------
# PATH
# ----------------------------------------------------------------------

# We want all the sbins on PATH
PATH="$PATH:/usr/local/sbin:/usr/sbin:/sbin"

# Add more bindirs to front of PATH
for _path in /usr/local/bin $HOME/.local/bin $HOME/bin; do
    [ -d "$_path" ] || continue
    PATH="$_path:$PATH"
done

# ----------------------------------------------------------------------
# ENVIRONMENT CONFIGURATION
# ----------------------------------------------------------------------

# detect interactive shell
case "$-" in
    *i*) INTERACTIVE=yes ;;
    *)   unset INTERACTIVE ;;
esac

# detect login shell
case "$0" in
    -*) LOGIN=yes ;;
    *)  unset LOGIN ;;
esac

# enable en_US locale w/ utf-8 encodings if not already configured
: ${LANG:="en_US.UTF-8"}
: ${LANGUAGE:="en"}
: ${LC_CTYPE:="en_US.UTF-8"}
: ${LC_ALL:="en_US.UTF-8"}
export LANG LANGUAGE LC_CTYPE LC_ALL

# ignore backups, python bytecode, vim swap files
FIGNORE="~:#:.pyc:.swp:.swa"

# history stuff
HISTCONTROL=ignoreboth
HISTFILESIZE=100000
HISTSIZE=100000

# ----------------------------------------------------------------------
# PAGER / EDITOR
# ----------------------------------------------------------------------

# Use vim editor, fall back to vi
EDITOR=vi
if [ -n "$(command -v vim)" ]; then
    EDITOR=vim
fi
export EDITOR

# Use less pager, fall back to more
PAGER=more
MANPAGER="$PAGER"
if [ -n "$(command -v less)" ]; then
    PAGER="less -FiRSw"
    MANPAGER="less -FiRsw"
fi
export PAGER MANPAGER

# Configure ack paging
ACK_PAGER="$PAGER"
ACK_PAGER_COLOR="$PAGER"

# ----------------------------------------------------------------------
# PROMPT
# ----------------------------------------------------------------------

# Generate control sequence string. The \x01 and \x02 mark the text as
# non-printable so readline and terminals don't assume the chars occupy
# cells. The "\x1b[" part is the sequence introducer (CSI).
cseq() {
    printf "\x01\x1b[$1\x02"
}

if [ -n "$PS1" ]; then
    cdefaultfg=$(cseq 39m)
    cdefaultbg=$(cseq 49m)
    cthemefg=$(cseq 96m)
    cthemebg=$(cseq 106m)
    cblackfg=$(cseq 30m)
    cinverse=$(cseq 7m)
    cinverseoff=$(cseq 27m)
    arr1=$'\xee\x82\xb0'
    arr2="〉"
    cbold=$(cseq 1m)
    creset=$(cseq 0m)

    PS1="${cthemebg}${cblackfg}${cbold}\W${cdefaultbg}${cthemefg}${arr1}${creset} "
    PS2="$arr2 "
fi

# ----------------------------------------------------------------------
# BASH COMPLETION
# ----------------------------------------------------------------------

if [ -z "$BASH_COMPLETION" -a -n "$PS1" ]; then
    bash=${BASH_VERSION%.*}; bmajor=${bash%.*}; bminor=${bash#*.}
    if [ "$bmajor" -gt 1 ]; then
        # search for a bash_completion file to source
        for f in /usr/local/etc/bash_completion /etc/bash_completion; do
            if [ -f $f ]; then
                . $f
                break
            fi
        done
    fi
    unset bash bmajor bminor
fi

# override and disable tilde expansion
_expand() {
    return 0
}

# ----------------------------------------------------------------------
# LS AND DIRCOLORS
# ----------------------------------------------------------------------

# we always pass these to ls(1)
LS_COMMON="-hBG --color=auto"

# if the dircolors utility is available, set that up too
dircolors="$(type -P gdircolors dircolors | head -1)"
if [ -n "$dircolors" ]; then
    COLORS=/etc/DIR_COLORS
    test -e "/etc/DIR_COLORS.$TERM"   && COLORS="/etc/DIR_COLORS.$TERM"
    test -e "$HOME/.dircolors"        && COLORS="$HOME/.dircolors"
    test ! -e "$COLORS"               && COLORS=
    eval $($dircolors --sh $COLORS)
    unset COLORS
fi
unset dircolors

# setup the main ls alias if we've established common args
if [ -n "$LS_COMMON" ]; then
    alias ls="command ls $LS_COMMON"
fi

# -------------------------------------------------------------------
# USER SHELL ENVIRONMENT
# -------------------------------------------------------------------

# ~/.shenv is used as a machine specific ~/.bashrc
if [ -r ~/.shenv ]; then
    . ~/.shenv
fi

# -------------------------------------------------------------------
# MOTD / FORTUNE
# -------------------------------------------------------------------

if [ -n "$INTERACTIVE" -a -n "$LOGIN" ]; then
    uname -npsr
    uptime
fi

# vim: ts=4 sts=4 shiftwidth=4 expandtab
