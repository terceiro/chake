# Capitalize section titles
s/^\(##\+\)\(.*\)/\1 \U\2/

# Turn fenced code blocks into 4-space indented blocks
/^```/,/```/ s/^/    /
/^    ```.*/ d
