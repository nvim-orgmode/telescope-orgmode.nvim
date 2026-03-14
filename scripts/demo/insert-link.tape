Output out/insert-link.webm

Set Shell "bash"
Set FontSize 14
Set Width 1200
Set Height 900
Set Padding 10
Set Theme "TokyoNight"

Hide
Type "nvim --clean -u scripts/demo/init.lua scripts/test-fixture/notes/work.org"
Enter
Sleep 5s
Show

# Go to end of file and open a new line
Type "Go"
Sleep 0.5s

# Type some context
Type "See also: "
Escape
Sleep 0.5s

# Open insert link picker
Type " li"
Sleep 3s

# Search for a headline from another file
Type "dentist"
Sleep 3s

# Select to insert link
Enter
Sleep 1s

# Confirm link text prompt
Enter
Sleep 3s

# Follow the link we just inserted
Type " oo"
Sleep 3s

Hide
Type ":q!"
Enter
Sleep 0.5s
