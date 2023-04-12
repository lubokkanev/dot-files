# If not running interactively, don't do anything
#case $- in
#    *i*) ;;
#      *) return;;
#esac

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

complete -d cd
complete -d pushd
complete -W '$(jobs | cut -c 2- | tr " ]" _)' fg

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

    PS1="-----------------------------------------------------------\n\n"
    [ ${exit_code} -eq 0 ] && PS1+="${green}" || PS1+="${red}"
    PS1+="> ${yellow}\d \t${red}|${blue}\u${red}@${green}\h${red}:${purple}\W${yellow}\$(git_branch_prompt)${red}\$${white} "
}
if [[ $TERM_PROGRAM != "WarpTerminal" ]]; then
    PROMPT_COMMAND=prompt_command
fi

bind Space:magic-space
shopt -s dirspell 2>/dev/null
shopt -s histverify # let's you verify before using '!!'
stty -ixon # let's you do ^s to go back in the "reverse-search"

# functions and aliases
function ssh {
    local cmd="${2:-exec \$SHELL -i}"
    local pub_key="$(cat ~/.ssh/id_rsa.pub)"

    command ssh -o ConnectTimeout=1 -t "${1}" "
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

        if ! grep -q \"alias ll\" ~/.bashrc 2>/dev/null; then
            echo \"alias ll='ls -AlnhF'\" >> ~/.bashrc
        fi

        ${cmd}
    "
}

# completion from .ssh/config
function ssh_completion {
    local words=""
    while read line; do
        if [[ "${line}" == "Host "* ]]; then
            name=$(sed 's,^Host \([^\s]*\),\1,' <<< "${line}")
            words+=" $name"
        fi
    done < ~/.ssh/config

    local last_index=$((${#COMP_WORDS[@]} - 1))
    COMPREPLY=($(compgen -W "$words" "${COMP_WORDS[last_index]}"))
}
complete -F ssh_completion ssh sshpass fix-vr-ui hms-ssh hms-setup-new hms-restart hms-rpm-upgrade # no scp because it doesn't allow me to auto-complete the local destination

function getfs { # get functions :
    grep "^\s*function" ~/.bashrc |sed 's,^[0-9]\+:\s*function,,g'
}

function getvcfs { # get version control functions :
    grep "^\s*function" ~/.vcrc |sed 's,^[0-9]\+:\s*function,,g'
}

alias less='less -M -N -i'
alias les='/usr/share/vim/vim*/macros/less.sh'
alias tmux='tmux -2'
alias ll='ls -AlnhF'

export JAVA_HOME="/usr"
export EDITOR=vim
export P4CONFIG=.p4config
export IGNOREEOF=1

[ -r ~/.vcrc ] && source ~/.vcrc
[ -r ~/.additionalrc ] && source ~/.additionalrc
[ -r /usr/share/bash-completion/completions/git ] && source /usr/share/bash-completion/completions/git
[ -r ~/.git-completion.sh ] && source ~/.git-completion.sh

if [[ $TERM_PROGRAM != "WarpTerminal" ]]; then
    tmux a 2>/dev/null || tmux new 2>/dev/null
fi

