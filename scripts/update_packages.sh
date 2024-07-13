#!/bin/bash

# Check for updates
pacman -Qu | grep -q "." > /dev/null

if [ $? != 0 ]; then
    echo "There is no updates."
else
    # Save previous state of packages (everything works)
    prev_pkgs=$(pacman -Qe)

    # Update packages; Redirect stderr to stdout
    sudo pacman -Syu 2>&1

    if [ $? == 0 ]; then
        # Update done
        echo $prev_pkgs > $HOME/.dotfiles/pkglist.txt

        # TODO Check it out. Does it work as expected?
        cd $HOME/.dotfiles && git diff pkglist.txt | grep -q "."

        if [ $? == 0 ]; then
            echo "Hey man, your ~/.dotfiles/pkglist.txt has been updated with the packages state (assumably working) BEFORE the update (by the way). You better git add, git commit, git push it ASAP (by the way)."
        else
            echo "No explicitly installed packages have been updated."
        fi
    fi
fi
