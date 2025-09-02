function fish_greeting
    # Fichier ASCII (Saturne)
    set -l LOGO ~/.config/fastfetch/saturn.txt
    set -l PAD 3

    # Si pas de logo, simple fallback
    if not test -f $LOGO
        fastfetch
        return
    end

    # Récupère la sortie fastfetch SANS logo dans un fichier temporaire
    set -l tmp (mktemp)
    fastfetch --logo none > $tmp

    # Charge les lignes du logo
    set -l logo_lines
    while read -l line
        set -a logo_lines $line
    end < $LOGO

    # Charge les lignes de fastfetch
    set -l ff_lines
    while read -l line
        set -a ff_lines $line
    end < $tmp
    rm -f $tmp

    # Largeur max du logo
    set -l max 0
    for l in $logo_lines
        set -l n (string length -- $l)
        if test $n -gt $max
            set max $n
        end
    end

    # Nombre total de lignes à afficher (colonne gauche/droite)
    set -l n1 (count $logo_lines)
    set -l n2 (count $ff_lines)
    if test $n1 -gt $n2
        set -l total $n1
    else
        set -l total $n2
    end

    # Couleur du logo = couleur "commande" du thème (fallback jaune)
    set -l LOGOCOL $fish_color_command
    test -z "$LOGOCOL"; and set LOGOCOL yellow

    # Impression côte à côte
    for i in (seq $total)
        set -l L ''
        set -l R ''
        if test $i -le $n1
            set L $logo_lines[$i]
        end
        if test $i -le $n2
            set R $ff_lines[$i]
        end

        set -l llen (string length -- $L)
        set -l gap (math $max + $PAD - $llen)
        if test $gap -lt 1
            set gap 1
        end
        set -l pad (string repeat -n $gap ' ')

        set_color $LOGOCOL
        echo -n $L
        set_color normal
        echo -n $pad
        echo $R
    end
end
