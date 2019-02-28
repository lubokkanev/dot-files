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
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto -n'
    alias fgrep='fgrep --color=auto -n'
    alias egrep='egrep --color=auto -n'
fi

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
shopt -s dirspell
shopt -s histverify # let's you verify before using '!!'
stty -ixon # let's you do ^s to go back in the "reverse-search"

# functions and aliases
    function ssh {
        local cmd="${2:-exec \$SHELL -i}"
        local pkey="$(cat ~/.ssh/id_rsa.pub)"

        command ssh -t "${1}" "
            keys_file=\"\$(grep AuthorizedKeysFile /etc/ssh/sshd_config 2>/dev/null | sed 's,.*\s\+\(.*\),\1,g' | sed s,%u,\$USER,g)\"
            [ -f \"\${keys_file}\" ] || keys_file=~/\"\${keys_file}\"
            [ -f \"\${keys_file}\" ] || keys_file=~/.ssh/authorized_keys

            if [ ! -f \"\${keys_file}\" ]; then
                mkdir -p \"\$(dirname \${keys_file})\" && chmod 740 \"\$(dirname \${keys_file})\"
                touch \"\${keys_file}\"
            fi

            if ! grep \"${pkey}\" \"\${keys_file}\" > /dev/null 2>&1; then
                echo ${pkey} >> \"\${keys_file}\" 2>/dev/null
                chmod 600 \"\${keys_file}\"
                cp \"\${keys_file}\" \"\${keys_file}2\"
            fi

            ${cmd}
        "
    }

    alias less='less -M -N -i'
    alias les='/usr/share/vim/vim*/macros/less.sh'
    alias tmux='tmux -2'
    alias ll='ls -AlnhF'

    # git
        alias gitp='git pull --rebase'
        alias gitpp='gitp && git push'
        alias gitc='git add . &&  git commit -am'
        alias gitca='git commit -a --amend --no-edit'
        alias gitcach='gitca && gitch'

        function gitmr { # git master rebase
            # set -f changes the file listing format
            set -f &&
                for branch in $(git branch); do
                    if [ "${branch}" != "*" ]; then
                        if ! git rebase master "${branch}"; then
                            break;
                        fi;
                    fi;
                done &&

                git checkout master &&
            set +f
        }

        function gitdh { # git diff head
            echo "Printing diff of HEAD~${1:-1}..." &&
            git diff HEAD~${1:-1} ${2}
        }

        function gitsh { # git show head
            echo "Showing HEAD~${1:-0}"
            git show HEAD~${1:-0}
        }

        function gitcb { # git create branch
            echo "Creating branch '${1}' from '${2:-master}'..." &&
            git checkout -b "${1}" ${2} &&
            echo "Creating a commit from the new changes..." &&
            git commit --allow-empty -am "${1}"
        }

        function gitmcb { # git create branch from master
            gitcb "${1}" master
        }

        function gitch { # git checkout
            echo "Switching to branch '${1:-master}'..." &&
            git checkout "${1:-master}"
        }

        function gitsb { # git submit branch
            local branch="${1}"
            if [ -z "${branch}" ]; then
                branch="$(parse_git_branch)"
            fi

            [ "${branch}" != master ] &&
            git checkout master &&
            echo "Replaying on top of 'master'..." &&
            git rebase "${branch}" master &&
            echo "Removing branch '${branch}'..." &&
            git branch -d "${branch}" &&
            echo "Replaying on top of all branches..." &&
            gitmr &&
            git remote get-url origin > /dev/null 2>&1 &&
            echo "Pull-pushing on remote..." &&
            gitpp
        }

        function gitbd { # git branch diff
            echo "Showing diff between branch '${1:-master}' and branch '${2:-$(parse_git_branch)}'..." &&
            git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr)%Creset' --abbrev-commit --date=relative ${1:-master}..${2:-$(parse_git_branch)}
        }

    # p4
        function p4ch { # p4 change
            if [ -n "${1}" ]; then
                echo "Opening all files for edit on changelist '${1}'..." &&
                p4 edit -c "${1}" ./... > /dev/null &&
                echo "Reverting all non-changed files..." &&
                p4 revert -a > /dev/null
            else
                echo "Opening all files for edit on the default changelist..." &&
                p4 edit ./... > /dev/null &&
                echo "Reverting all non-changed files..." &&
                p4 revert -a > /dev/null &&
                echo "Putting the edited files in a new changelist..." &&
                p4 change
            fi
        }

        function p4d { # p4 changelist diff
            echo "Showing diff of changelist '${1}'..." &&
            p4 opened -c "${1}" | sed -e 's/#.*//' | p4 -x - diff
        }

        function p4chs { # p4 changes
            user=$(p4 info | head -n1 | sed 's,User name: \(.*\),\1,')
            echo "Showing ${user}'s pending changes on this client..." &&
            p4 changes -u "${user}" -s pending ${1} | grep $(p4 -Ztag -F %clientName% info) --color=none
        }

        function p4pp { # p4 pull push
            echo "Syncing with p4..." &&
            [ $(p4 sync ./... 2>&1 | wc -l) == 1 ] &&
            echo "No changes. Submitting changelist '${1}' to p4..." &&
            p4 submit -c "${1}"
        }

    # mixed
        function g4sb { # p4 and git - submit branch and changelist
            p4pp &&
            echo "Submitting in git..." &&
            gitsb
        }

        function g4mcb { # p4 and git - master create branch and changelist
            gitmcb "${1}" &&
            p4ch
        }

export JAVA_HOME="/usr"
export EDITOR=vim
export P4CONFIG=.p4config

[ -r ~/.additionalrc ] && source ~/.additionalrc
[ -r ~/git-completion.sh ] && source ~/git-completion.sh
