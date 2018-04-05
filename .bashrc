set -x
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

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if false && ! shopt -oq posix; then # currently disabled
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

function git_branch_prompt() {
    local branch=$(parse_git_branch)
    echo ${branch:+" (${branch})"}
}

prompt_command() {
    local exit_code="$?"
    PS1=""

    local red='\[\e[0;31m\]'
    local green='\[\e[0;32m\]'
    local yellow='\[\e[1;33m\]'
    local purple='\[\e[0;35m\]'

    [ ${exit_code} -eq 0 ] && PS1+="${green}" || PS1+="${red}"

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
            local branch=${1}
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
