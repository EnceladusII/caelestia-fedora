function fish_greeting
    set -l LOGO ~/.config/fastfetch/saturn.txt
    set -l PAD 2

    if test -f $LOGO
        fastfetch --logo $LOGO --logo-padding $PAD
    else
        fastfetch
    end
end
