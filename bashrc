#!/bin/bash -l

[[ $- != *i* ]] && return

source $HOME/bin/razer-functions.sh

#record path into history
export PROMPT_COMMAND='hpwd=$(history 1); hpwd="${hpwd# *[0-9]*  }"; if [[ ${hpwd%% *} == "cd" ]]; then cwd=$OLDPWD; else cwd=$PWD; fi; hpwd="${hpwd% ### *} ### $cwd"; echo "$hpwd" >> ${HOME}/.historylong'
alias historylong='cat -v ${HOME}/.historylong'

if [ "$TERM" != "linux" ]; then

	PS1='$(exit=$?;if [ $exit -eq 0 ];then echo "\[\033[48;5;237;38;5;2m\]$exit";else echo "\[\033[48;5;237;38;5;1m\]$exit";fi)'
	if [[ ${EUID} == 0 ]]; then
		PROMPT='#'
		USERCOLOR='\[\033[31m\]'
	else
		PROMPT='%'
		USERCOLOR='\[\033[32m\]'
	fi

	function trimpath(){
		TERMWIDTH=$(tput cols)
		TERMWIDTH=${TERMWIDTH:-80}
		TERMWIDTH=$((TERMWIDTH*60/100))
		TRIMMED_PWD=${PWD: -$TERMWIDTH};
		TRIMMED_PWD=${TRIMMED_PWD:-$PWD}
		PREPEND=""
		if [ "$PWD" != "$TRIMMED_PWD" ];then
			PREPEND="..."
		fi
		echo -e "$PREPEND$TRIMMED_PWD"
	}

	PS1+='\[\033[00m\] \[\033[1m\]|\[\033[0m\] '${USERCOLOR}'\u\[\033[00m\]@\h \[\033[1m\]|\[\033[0m\] \[\033[01;34m\]$(trimpath) \n\[\e[0;33m\]'$PROMPT' \[\033[0m\]'

fi

HISTSIZE=10000
HISTFILESIZE=2000
export EDITOR=vim

set -P
set -o vi
set -o physical

shopt -s checkwinsize

bind -m vi-insert "\C-l":clear-screen

alias sync_to_dalek="rsync $HOME/ss/* dalek:/SitscapeData/SOURCE/. -a"
alias php_lint='find . -type f \( -iname "*.html" -o -iname "*.php" \) -print0|xargs -I% -r -0 -n1 -P$(nproc) php -l %'
alias chromium="nice chromium"
alias ls='ls -p --color=auto'
alias ll='ls -altrh'
alias grep='grep --color=always'
alias fgrep='fgrep --color=always'
alias egrep='egrep --color=always'
alias dpms_off='xset s off;xset -dpms'
alias dpms_on='xset s on;xset +dpms'
alias mplayer='mpv'

export LESSHISTFILE="-"
# color highlighting in less
export LESS_TERMCAP_mb=$'\E[01;31m'
export LESS_TERMCAP_md=$'\E[01;31m'
export LESS_TERMCAP_me=$'\E[0m'
export LESS_TERMCAP_se=$'\E[0m'
export LESS_TERMCAP_so=$'\E[01;44;33m'
export LESS_TERMCAP_ue=$'\E[0m'
export LESS_TERMCAP_us=$'\E[01;32m'
export LESS="Ri"

export HOME=~
if [ -f /etc/alpine-release ];then
	BINPATH="$HOME/bin-alpine"
else
	BINPATH="$HOME/bin"
fi
export PATH=$BINPATH:$PATH:/opt/bin:/sbin:/usr/sbin:$HOME/.cabal/bin:$HOME/.local/bin:$HOME/ericw-tools

function rsyncport() {
	port=$1
	otherargs=$(echo "${@:2}")

	if [ ! -z "$port" ] && [ ! -z "$otherargs" ];then
		rsync -e "ssh -p $port" $otherargs
	fi

	echo $port
	echo "$otherargs"
}

alias alsa_output_info="cat /proc/asound/card*/*/*/hw_params"
alias aptget-distupgrade="apt-get -y --force-yes -o Dpkg::Options::=\"--force-confdef\" -o Dpkg::Options::=\"--force-confold\" dist-upgrade"
alias rm-over-30='find  -maxdepth 1 -mtime +30 -print0|xargs -0 -r -I% du -h "%"|sort -h;read -p "delete older than 30 days? [Ny]: " answer;if [ "$answer" == "y" ];then find  -maxdepth 1 -mtime +30 -exec rm -r {} \;;echo "done.";else echo "exiting.";fi'
alias rm-over-120='find  -maxdepth 1 -mtime +120 -print0|xargs -0 -r -I% du -h "%"|sort -h;read -p "delete older than 120 days? [Ny]: " answer;if [ "$answer" == "y" ];then find  -maxdepth 1 -mtime +120 -exec rm -r {} \;;echo "done.";else echo "exiting.";fi'
alias atom-freetype='LD_PRELOAD=/opt/libfreetypeold/libfreetype.so atom'
alias rsync2222="rsync -e 'ssh -p 2222'"
alias apty="DEBIAN_FRONTEND=noninteractive apt -y --allow-downgrades --allow-remove-essential --allow-change-held-packages"
alias pbcopy='xsel --clipboard --input'
alias pbpaste='xsel --clipboard --output'
alias mplayer-novideo="mplayer -no-video "
alias amazonworkspaces-creds="vim $HOME/documents/sitscape/amazon/workspaces/creds.txt"


function title()
{
	# change the title of the current window or tab
	echo -ne "\033]0;$*\007"
}

function ssh()
{
	/usr/bin/ssh "$@"
	title "[$$] ${USER}@${HOSTNAME}:$PWD"
}

cd()
{
	[[ -z "$*" ]] && builtin cd $HOME
	[[ -n "$*" ]] && builtin cd "$*"
	title "[$$] ${USER}@${HOSTNAME}:$PWD"
}

function su()
{
	/bin/su "$@"
	# revert the window title after the su command
	title "[$$] ${USER}@${HOSTNAME}:$PWD"
}

function sudo() 
{   
	/usr/bin/sudo "$@"
	# revert the window title after the sudo command
	title "[$$] ${USER}@${HOSTNAME}:$PWD"
}  


#initial title
title "[$$] ${USER}@${HOSTNAME}:$PWD"

if [ -e "$HOME/.cargo/env" ];then
	. "$HOME/.cargo/env"
fi
