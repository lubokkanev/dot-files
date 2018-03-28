# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
#force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
    # We have color support; assume it's compliant with Ecma-48
    # (ISO/IEC-6429). (Lack of such support is extremely rare, and such
    # a case would tend to support setf rather than setaf.)
        color_prompt=yes
    else
        color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# some more ls aliases
alias ll='ls -AlnhF'

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# user defined
function parse_git_branch() {
    echo $(git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/')
}

function parse_git_dirty {
    status=$(git status 2>&1 | tee)
    dirty=$(echo -n "${status}" 2> /dev/null | grep "modified:" &> /dev/null; echo "$?")
    untracked=$(echo -n "${status}" 2> /dev/null | grep "Untracked files" &> /dev/null; echo "$?")
    ahead=$(echo -n "${status}" 2> /dev/null | grep "Your branch is ahead of" &> /dev/null; echo "$?")
    newfile=$(echo -n "${status}" 2> /dev/null | grep "new file:" &> /dev/null; echo "$?")
    renamed=$(echo -n "${status}" 2> /dev/null | grep "renamed:" &> /dev/null; echo "$?")
    deleted=$(echo -n "${status}" 2> /dev/null | grep "deleted:" &> /dev/null; echo "$?")
    bits=''
    if [ "${renamed}" == "0" ]; then
        bits=">${bits}"
    fi
    if [ "${ahead}" == "0" ]; then
        bits="*${bits}"
    fi
    if [ "${newfile}" == "0" ]; then
        bits="+${bits}"
    fi
    if [ "${untracked}" == "0" ]; then
        bits="?${bits}"
    fi
    if [ "${deleted}" == "0" ]; then
        bits="X${bits}"
    fi
    if [ "${dirty}" == "0" ]; then
        bits="!${bits}"
    fi

    echo "${bits}"
}

function git_branch_prompt() {
    BRANCH=$(parse_git_branch)
    if [ "${BRANCH}" != "" ]; then
        #STAT=$(parse_git_dirty)
        echo " (${BRANCH}${STAT})"
    else
        echo ""
    fi
}

prompt_command() {
    local exit_code="$?"
    PS1=""

    local red='\[\e[0;31m\]'
    local green='\[\e[0;32m\]'
    local yellow='\[\e[1;33m\]'
    local blue='\[\e[1;34m\]'
    local purple='\[\e[0;35m\]'

    if [ ${exit_code} -eq 0 ]; then
        PS1+="${green}"
    else
        PS1+="${red}"
    fi

    PS1+="> ${yellow}\t${red}|\[\e[36m\]\u${red}@${green}\h${red}:${purple}\W${yellow}\$(git_branch_prompt)${red}\$\[\e[m\] "
}
PROMPT_COMMAND=prompt_command

bind Space:magic-space
shopt -s dirspell
shopt -s histverify # let's you verify before using '!!'
stty -ixon # let's you do ^s to go back in the "reverse-search"

alias less='less -M -N -i'
alias les='/usr/share/vim/vim*/macros/less.sh'
alias grep='grep --color=auto'
alias tmux='tmux -2'
alias ssh='TERM=xterm ssh'

alias gitp='git pull --rebase'
alias gitpp='gitp && git push'
alias gitc='git add . &&  git commit -am'
alias gitca='git commit -a --amend --no-edit'
alias gitmr='set -f && for branch in $(git branch); do if [ "${branch}" != "*" ]; then if ! git rebase master "${branch}"; then break; fi; fi; done && git checkout master && set +f'

# functions
    # git
        function gitcb() { # git create branch
            git checkout -b "${1}" ${2} &&
            git commit --allow-empty -am "${1}" 
        }

        function gitmcb() { # git create branch from master
            gitcb "${1}" master
        }

        function gitch() { # git checkout
            if [ -z ${1} ]; then
                git checkout master
            else
                git checkout ${1}
            fi
        }

        function gitcach() { # git commit amend, checkout
            gitca &&
            gitch "${1}"
        }

        function gitsb() { # git submit branch
            branch=${1}
            if [ -z "${branch}" ]; then
                branch=$(parse_git_branch)
            fi

            git checkout master && 
            git rebase ${branch} master && 
            git branch -d ${branch} && 
            gitmr && 
            git remote get-url origin > /dev/null 2>&1 && gitpp
        }

        function gitbd() { # git branch diff
            git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr)%Creset' --abbrev-commit --date=relative ${1}..${2}
        }


    # p4
        function p4d() { # p4 diff changelist
            p4 opened -c "${1}" | sed -e 's/#.*//' | p4 -x - diff
        }

        function p4ch() { # p4 change
            if [ -n "${1}" ]; then
                p4 edit -c "${1}" ./... > /dev/null &&
                p4 revert -a ./... > /dev/null
            else
                p4 edit ./... > /dev/null &&
                p4 revert -a ./... > /dev/null && 
                p4 change 
            fi
        }

        function p4chs() { # p4 changes
            p4 changes -u lkanev -s pending ./...
        }

export JAVA_HOME="/usr"
export EDITOR=vim
export P4CONFIG=.p4config

[ -r ~/.additionalrc ] && source ~/.additionalrc
[ -r ~/git-completion.sh ] && source ~/git-completion.sh

