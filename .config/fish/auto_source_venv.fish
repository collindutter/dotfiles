if test -e "$VIRTUAL_ENV"; and test -f "$VIRTUAL_ENV/bin/activate.fish"
  . (dirname (poetry run which python))/activate.fish
end 
