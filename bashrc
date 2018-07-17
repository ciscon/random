HISTSIZE=1000
HISTFILESIZE=2000
export EDITOR=vim

set -o vi
set -o physical

alias chromium="nice chromium"
alias ls='ls -p --color=auto'
alias grep='grep --color=always'
alias fgrep='fgrep --color=always'
alias egrep='egrep --color=always'
alias dpms_off='xset s off;xset -dpms'
alias dpms_on='xset s on;xset +dpms'

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
export PATH=$PATH:/opt/bin:/sbin:/usr/sbin:$HOME/.cabal/bin

if [ -e ~/.git-prompt.sh ];then
  export GIT_PS1_SHOWCOLORHINTS=1
  . ~/.git-prompt.sh
else
  function __git_ps1(){
    return 0
  }
fi

#console doesn't support solid backgrounds
if [[ ${TERM} != "linux" ]];then
  PS1='`if [ $? -eq 0 ];then echo "\[\033[48;5;8;38;5;0m\]$?";else echo "\[\033[48;5;8;38;5;1m\]$?";fi`'
  #PS1='\[\033[48;5;8;38;5;0m\]$?'
else
  PS1='\[\033[90m\]$?'
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

if [[ ${EUID} == 0 ]]; then
  PROMPT='#'
  USERCOLOR='\[\033[31m\]'
else
  PROMPT='%'
  USERCOLOR='\[\033[32m\]'
fi
  PS1+='\[\033[00m\] \[\033[1m\]|\[\033[0m\] '${USERCOLOR}'\u\[\033[00m\]@\h $(__git_ps1 "\[\033[1m\]|\[\033[0m\] \[\033[31m\](%s) \[\033[0m\]")\[\033[1m\]|\[\033[0m\] \[\033[01;34m\]$(trimpath) \n\[\e[0;33m\]'$PROMPT' \[\033[0m\]'

#titlebar
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac


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
fi

alias alsa_output_info="cat /proc/asound/card*/pcm0p/sub0/hw_params"
shopt -s checkwinsize

alias aptget-distupgrade="apt-get -y --force-yes -o Dpkg::Options::=\"--force-confdef\" -o Dpkg::Options::=\"--force-confold\" dist-upgrade"

alias rm-over-30='read -p "delete older than 30 days? [Ny]: " answer;if [ "$answer" == "y" ];then find  -maxdepth 1 -mtime +30 -exec rm -r {} \;;echo "done.";else echo "exiting.";fi'

alias yum_chroot='sudo yum -c /home/git/dev_build2/sitscape_chroot/conf/yum/yum.conf --installroot=/home/git/dev_build2/sitscape_chroot/target --nogpgcheck --releasever=25'

alias atom-freetype='LD_PRELOAD=/opt/libfreetypeold/libfreetype.so atom'

alias rsync2222="rsync -e 'ssh -p 2222'"
