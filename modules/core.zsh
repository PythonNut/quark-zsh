typeset -F SECONDS

function quark-error {
    echo error: $@ >> $ZDOTDIR/startup.log
}
