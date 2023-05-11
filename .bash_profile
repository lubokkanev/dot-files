. ~/.bashrc

eval export PATH="/Users/lkanev/.jenv/shims:${PATH}"
export JENV_SHELL=bash
export JENV_LOADED=1
unset JAVA_HOME
unset JDK_HOME
source '/usr/local/Cellar/jenv/0.5.6/libexec/libexec/../completions/jenv.bash'
jenv rehash 2>/dev/null
jenv refresh-plugins
jenv() {
  type typeset &> /dev/null && typeset command
  command="$1"
  if [ "$#" -gt 0 ]; then
    shift
  fi

  case "$command" in
  enable-plugin|rehash|shell|shell-options)
    eval `jenv "sh-$command" "$@"`;;
  *)
    command jenv "$command" "$@";;
  esac
}
