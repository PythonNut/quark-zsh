typeset -F SECONDS

function quark-error {
    echo error: $@ >> $ZDOTDIR/startup.log
}

function quark-with-protected-return-code {
    local return=$?
    "$@"
    return $return
}
