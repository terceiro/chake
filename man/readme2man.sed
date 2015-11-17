1a :doctype: manpage

/^## Install/,/^[^#]/ d
/^## Contributing/,$ d

s/^##\(.*\)/## \U\1/
