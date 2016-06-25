#!/bin/bash

skyforge_replace_symlink_with_copy()
{
  link="$1"

  if [ ! -L "$abstarget" ]; then
    return
  fi

  dir=$(dirname "$link")
  reltarget=$(readlink "$link")
  if [[ $reltarget == /* ]]; then
      abstarget=.$reltarget
  else
      abstarget=$dir/$reltarget
  fi

  rm -f "$link"

  if [ -L "$abstarget" ]; then
    skyforge_replace_symlink_with_copy $abstarget
  fi

  cp -af "$abstarget" "$link" || {
      # on failure, restore the symlink
      rm -rfv "$link"
      ln -sfv "$reltarget" "$link"
  }
}

for link in `find . -type l`; do
  skyforge_replace_symlink_with_copy "$link"
done
