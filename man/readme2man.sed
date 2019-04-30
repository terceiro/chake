1a :doctype: manpage

/^## Install/,/^[^#]/ d
/^## Contributing/,$ d

s/^\(##\+\)\(.*\)/\1 \U\2/
