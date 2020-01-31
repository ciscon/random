[[ $- != *i* ]] && return                                                                                                             

#set up term
tput colors >/dev/null 2>&1 || export TERM=rxvt-256color
tput colors >/dev/null 2>&1 || export TERM=xterm-256color
tput colors >/dev/null 2>&1 || export TERM=xterm



if [ "$TERM" != "linux" ]; then
    if [ -f /home/git/pureline/pureline ] && [ -f ~/.pureline.conf ];then
        source /home/git/pureline/pureline ~/.pureline.conf
    else

        PS1='`exit=$?;if [ $exit -eq 0 ];then echo "\[\033[48;5;237;38;5;2m\]$exit";else echo "\[\033[48;5;237;38;5;1m\]$exit";fi`'
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

else

    PS1='\[\033[90m\]$?'
    #PS1='\[\033[48;5;8;38;5;0m\]$?'


fi

#. /usr/share/powerline/bindings/bash/powerline.sh

HISTSIZE=1000
HISTFILESIZE=2000
export EDITOR=vim

set -o vi
set -o physical

bind -m vi-insert "\C-l":clear-screen

alias chromium="nice chromium"
alias ls='ls -p --color=auto'
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
export PATH=$HOME/bin:$PATH:/opt/bin:/sbin:/usr/sbin:$HOME/.cabal/bin:$HOME/.local/bin

function rsyncport() {
    port=$1
    otherargs=$(echo "${@:2}")

    if [ ! -z "$port" ] && [ ! -z "$otherargs" ];then
        rsync -e "ssh -p $port" $otherargs
    fi

    echo $port
    echo "$otherargs"
}




#
##trap 'previous_command=$this_command; this_command=$BASH_COMMAND' DEBUG
#
#writecmd () { 
#  perl -e 'ioctl STDOUT, 0x5412, $_ for split //, do{ chomp($_ = <>); $_ }' ; 
#}
#
#bind -x '"\001":"echo $previous_command|writecmd"'



#titlebar
#case "$TERM" in
#xterm*|rxvt*|st-*)
#    PS1="\[\e]0;\u@\h: \w\a\]$PS1"
#    ;;
#*)
#    ;;
#esac


dev=0
timeout 1 test -d /mnt/build/sitscape_chroot&&dev=1
if [ $dev -eq 1 ];then
    . /mnt/build/sitscape_chroot/conf/yum/yumreleaseversion.ini
    if ! which dnf 2>/dev/null 1>&2;then
        alias dnf="yum"
    fi
    if [ -d /SitscapeData/PROD/sitscape_chroot ];then
        chroot_dir="/SitscapeData/PROD/sitscape_chroot"
    else
        chroot_dir="/mnt/build/sitscape_chroot/target"
    fi

    alias yum_chroot="dnf --color=never -c /mnt/build/sitscape_chroot/conf/yum/yum.conf -y --installroot=${chroot_dir} --releasever=$releasever"
    alias dnf_chroot=yum_chroot
else
    alias yum_chroot='sudo yum -c /home/git/dev_build2/sitscape_chroot/conf/yum/yum.conf --installroot=/home/git/dev_build2/sitscape_chroot/target --nogpgcheck --releasever=25'
fi

alias alsa_output_info="cat /proc/asound/card*/pcm0p/sub0/hw_params"
shopt -s checkwinsize

alias aptget-distupgrade="apt-get -y --force-yes -o Dpkg::Options::=\"--force-confdef\" -o Dpkg::Options::=\"--force-confold\" dist-upgrade"

alias rm-over-30='find  -maxdepth 1 -mtime +30 -print0|xargs -0 -r -I% du -h "%"|sort -h;read -p "delete older than 30 days? [Ny]: " answer;if [ "$answer" == "y" ];then find  -maxdepth 1 -mtime +30 -exec rm -r {} \;;echo "done.";else echo "exiting.";fi'

alias atom-freetype='LD_PRELOAD=/opt/libfreetypeold/libfreetype.so atom'

alias rsync2222="rsync -e 'ssh -p 2222'"

alias apty="DEBIAN_FRONTEND=noninteractive apt -y --allow-downgrades --allow-remove-essential --allow-change-held-packages"

alias pbcopy='xsel --clipboard --input'
alias pbpaste='xsel --clipboard --output'

alias mplayer-novideo="mplayer -no-video "


#function surfFunc(){
#    /usr/bin/surf -mNPIgBp "${1:-http://www.google.com}"
#}
#surfFunc "$*"

# from the "xtitle(1)" man page - put info in window title
#update_title()
#{
#    [ "$TERM" != "linux" ]  && xtitle "[$$] ${USER}@${HOSTNAME}:$PWD"
#}
#
#cd()
#{
#    [[ -z "$*" ]] && builtin cd $HOME
#    [[ -n "$*" ]] && builtin cd "$*"
#    update_title
#}
#update_title




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
