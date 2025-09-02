function fish_greeting
    set -l LOGO ~/.config/fastfetch/saturn.txt

    if test -f $LOGO
        cat $LOGO
        echo
    end

    fastfetch
end
