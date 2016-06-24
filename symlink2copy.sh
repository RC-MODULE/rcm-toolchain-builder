#!/bin/bash
  for link in `find . -type l`; do
    dir=$(dirname "$link")
    reltarget=$(readlink "$link")
    if [[ "$reltarget" == "/*" ]]; then
        abstarget=.$reltarget
    else
        abstarget=$dir/$reltarget
    fi

    rm -f "$link"
    cp -af "$abstarget" "$link" || {
        # on failure, restore the symlink
        rm -rfv "$link"
        ln -sfv "$reltarget" "$link"
    }
  done
