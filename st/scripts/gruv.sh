#!/bin/sh
#
# Usage: Source Me
# AUTHOR: Malik BEN KIRANE (MIT Licence)
#
# FIXED There is a bug killing st terminal with font utilities
#
# For user documentation README.md

# TODO * support gnu-like options
# e.g. --config -c options

# TODO Update this to where you choose to install
# or pass GRUV_XRESOURCES by environment
if [ -z "$GRUV_XRESOURCES" ]; then
  repo="/home/void/hot"
else
  repo="$GRUV_XRESOURCES"
fi

# where xresources and the 256 colors script are located

# xrdb wrapper
xrdb() {
    command xrdb $@
    killall -USR1 st
}

# for the `gruvbox` namespace`
gruvbox_choose_xresources() {
    # $1 theme variant (required)
    # $2 contrast variant (optional)
    # namespace: `gruvbox_`
    local light_theme="/gruvbox_light.xresources"
    local dark_theme="/gruvbox_dark.xresources"
    local choose
    case $1 in
        light) choose="$light_theme" ;;
        dark) choose="$dark_theme" ;;
        *) return 1 ;;
    esac
    case $2 in
        soft) choose="${choose%.xresources}-soft.xresources" ;;
        medium|med) choose="${choose%.xresources}-medium.xresources" ;;
        hard) choose="${choose%.xresources}-hard.xresources" ;;
    esac

    echo $choose
    return 0
}

gruvbox_choose_vimopts() {
    # $1 theme vairant (required)
    # $2 contrast variant (optional)
    local opts
    case $1 in
        light|dark) opts="set background=$1" ;;
        *) return 1 ;;
    esac
    case $2 in
        soft|medium|hard) opts="$opts\nlet g:gruvbox_contrast_$1='$2'" ;;
        *) opts="$opts\nlet g:gruvbox_contrast_$1='medium'";;
    esac
    opts="$opts\nsilent !sh $repo/gruvbox256.sh"
    opts="$opts\ncolo gruvbox"

    echo $opts
    return 0
}


gruvbox_automate() {
    # namesapce: `gruvbox_
    local xresources="$repo$(gruvbox_choose_xresources $1 $2)"
    xrdb -override $xresources
    echo '" .gruvvimrc'
    gruvbox_choose_vimopts $1 $2
}

# gruv utility
gruv() {
    # gruv utility
    if [ -n "$1" ]; then
        gruvbox_automate $1 $2 | tee ~/.grvim > /dev/null
        return 0
    fi
    return 1
}


# font utilities
# --------------

font_defaults() {
    local defaults
    local fontname
    local fontsize
    if defaults=$(command xrdb -query | grep st.font); then
        fontname=$(echo $defaults | cut -d':' -f2 | sed 's/^\s\+//')
        echo $fontname
        if echo $defaults | grep size > /dev/null; then
            fontsize=$(echo $defaults | sed 's/.*=//')
            echo $fontsize
        fi
    fi
}


# font name utility
fn() {
    local arg=$@
    if [ "$arg" ]; then
        local fdefaults=$(font_defaults)
        local fs
        if [ $(echo $fdefaults | wc -l) -eq 2 ]; then
            fs=":$(echo $fdefaults | (read line; read line; echo size=$line))"
        fi
        echo "st.font: $@$fs" | xrdb -override
        return
    else
        font_defaults | head -n 1
    fi
    return 1
}

# is_numeric helper
is_numeric() {
    echo $1 | grep "^[0-9][0-9]\?"
    return $?
}

# font size utility
font_default_size() {
    local fs
    if [ $(font_defaults | wc -l) -gt 1 ]; then
        fs=$(font_defaults | tail -n 1)
    # FIXME MAYBE this is never the case.  There could not be font
    # size echoed alone by `font_defaults` because there is always
    # at least font name printed by xrdb API.
    elif font_defaults | is_numeric; then
        fs
    else
        return 1
    fi
    echo "Actual Font Size is $fs"
    return 0
}

fs() {
    if [ "$2" ]; then
        echo " > Give one argument only (font size)"
        font_default_size
        return
    elif echo $1 | grep -v "^[0-9][0-9]\?" > /dev/null; then
        echo "> Give only font size"
        font_default_size
        return 
    fi
    local arg=$@
    if [ "$arg" ]; then
        local fdefaults=$(font_defaults)
        local fn
        if [ $(echo $fdefaults | wc -l) -gt 0 ]; then
            fn="$(echo $fdefaults | (read line; echo $line))"
        fi
        echo "st.font: ${fn}:size=$1" | xrdb -override
        return 0
    fi
    return 1
}
