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

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
fi

alias ls='ls -G'
#alias dir='dir --color=auto'
#alias vdir='vdir --color=auto'

alias grep='grep --color=auto -n'
alias fgrep='fgrep --color=auto -n'
alias egrep='egrep --color=auto -n'

function parse_git_branch {
    echo $(git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/')
}

function git_branch_prompt {
    local branch=$(parse_git_branch)
    echo ${branch:+" (${branch})"}
}

function prompt_command {
    local exit_code="$?"

    local red='\[\e[0;31m\]'
    local green='\[\e[0;32m\]'
    local yellow='\[\e[1;33m\]'
    local purple='\[\e[0;35m\]'
    local blue='\[\e[0;36m\]'
    local white='\[\e[m\]'

    [ ${exit_code} -eq 0 ] && PS1="${green}" || PS1="${red}"
    PS1+="> ${yellow}\t${red}|${blue}\u${red}@${green}\h${red}:${purple}\W${yellow}\$(git_branch_prompt)${red}\$${white} "
}
PROMPT_COMMAND=prompt_command

bind Space:magic-space
shopt -s dirspell 2>/dev/null
shopt -s histverify # let's you verify before using '!!'
stty -ixon # let's you do ^s to go back in the "reverse-search"

# functions and aliases
function ssh {
    local cmd="${2:-exec \$SHELL -i}"
    local pub_key="$(cat ~/.ssh/id_rsa.pub)"

    command ssh -t "${1}" "
        keys_file=\"\$(grep AuthorizedKeysFile /etc/ssh/sshd_config 2>/dev/null | sed 's,.*\s\+\(.*\),\1,g' | sed s,%u,\$USER,g)\"
        [ -f \"\${keys_file}\" ] || keys_file=~/\"\${keys_file}\"
        [ -f \"\${keys_file}\" ] || keys_file=~/.ssh/authorized_keys

        if [ ! -f \"\${keys_file}\" ]; then
            mkdir -p \"\$(dirname \${keys_file})\" && chmod 740 \"\$(dirname \${keys_file})\"
            touch \"\${keys_file}\"
        fi

        if ! grep \"${pub_key}\" \"\${keys_file}\" > /dev/null 2>&1; then
            echo ${pub_key} >> \"\${keys_file}\" 2>/dev/null
            chmod 600 \"\${keys_file}\"
            cp \"\${keys_file}\" \"\${keys_file}2\"
        fi

        ${cmd}
    "
}

function getfs { # get functions :
    grep "^\s*function" ~/.bashrc |sed 's,^[0-9]\+:\s*function,,g'
}

function getvcfs { # get version control functions :
    getfs | tail -n +7
}

alias less='less -M -N -i'
alias les='/usr/share/vim/vim*/macros/less.sh'
alias tmux='tmux -2'
alias ll='ls -AlnhF'
alias cd='cd -P'

export JAVA_HOME="/usr"
export EDITOR=vim
export P4CONFIG=.p4config

[ -r ~/.vcrc ] && source ~/.vcrc
[ -r ~/.additionalrc ] && source ~/.additionalrc
[ -r /usr/share/bash-completion/completions/git ] && source /usr/share/bash-completion/completions/git
[ -r ~/.git-completion.sh ] && source ~/.git-completion.sh

tmux a 2>/dev/null || tmux new 2>/dev/null

