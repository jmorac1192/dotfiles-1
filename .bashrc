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

# we want the various sbins on the path along with /usr/local/bin
PATH="$PATH:/usr/local/sbin:/usr/sbin:/sbin"
PATH="/usr/local/bin:$PATH"

# put ~/bin first on PATH
if [ -d "$HOME/bin" ]; then
    PATH="$HOME/bin:$PATH"
fi

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

# EDITOR
if [ -n "$(command -v vim)" ]; then
    EDITOR=vim
else
    EDITOR=vi
fi
export EDITOR

# PAGER
if [ -n "$(command -v less)" ]; then
    PAGER="less -FirSwX"
    MANPAGER="less -FiRswX"
else
    PAGER=more
    MANPAGER="$PAGER"
fi
export PAGER MANPAGER

# ACK
ACK_PAGER="$PAGER"
ACK_PAGER_COLOR="$PAGER"

# ----------------------------------------------------------------------
# PROMPT
# ----------------------------------------------------------------------

RED="\[\033[0;31m\]"
BROWN="\[\033[0;33m\]"
GREY="\[\033[0;97m\]"
BLUE="\[\033[0;34m\]"
BLUE2="\[\033[0;94m\]"
GREEN="\[\033[0;92m\]"
PS_CLEAR="\[\033[0m\]"
SCREEN_ESC="\[\033k\033\134\]"

if [ "$LOGNAME" = "root" ]; then
    COLOR1="${RED}"
    COLOR2="${BROWN}"
    P="#"
elif [ "$UNAME" = "Linux" ]; then
    COLOR1="${BLUE2}"
    COLOR2="${GREEN}"
    P="\$"
else
    COLOR1="${BLUE}"
    COLOR2="${BROWN}"
    P="\$"
fi

prompt_simple() {
    unset PROMPT_COMMAND
    PS1="[\u@\h:\w]\$ "
    PS2="> "
}

prompt_compact() {
    unset PROMPT_COMMAND
    PS1="${COLOR1}${P}${PS_CLEAR} "
    PS2="> "
}

prompt_color() {
    PS1="${GREY}[${COLOR1}\u${GREY}@${COLOR2}\h${GREY}:${COLOR1}\W${GREY}]${COLOR2}$P${PS_CLEAR} "
    PS2="\[[33;1m\] \[[0m[1m\]> "
}

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
LS_COMMON="-hBG"

# if the dircolors utility is available, set that up too
dircolors="$(type -P gdircolors dircolors | head -1)"
if [ -n "$dircolors" ]; then
    COLORS=/etc/DIR_COLORS
    test -e "/etc/DIR_COLORS.$TERM"   && COLORS="/etc/DIR_COLORS.$TERM"
    test -e "$HOME/.dircolors"        && COLORS="$HOME/.dircolors"
    test ! -e "$COLORS"               && COLORS=
    eval `$dircolors --sh $COLORS`
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

# Use the color prompt by default when interactive
if [ -n "$PS1" ]; then
    prompt_color
fi

# -------------------------------------------------------------------
# MOTD / FORTUNE
# -------------------------------------------------------------------

if [ -n "$INTERACTIVE" -a -n "$LOGIN" ]; then
    uname -npsr
    uptime
fi

# vim: ts=4 sts=4 shiftwidth=4 expandtab
