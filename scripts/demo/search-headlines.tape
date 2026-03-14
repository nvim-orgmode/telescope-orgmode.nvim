Output out/search-headlines.webm

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

# Open headline search
Type " fh"
Sleep 3s

# 1. Filter by title
Type "authentication"
Sleep 3s

# Clear and filter by TODO state
Escape
Type "diwa"
Type "WAITING"
Sleep 3s

# Clear and filter by tag
Escape
Type "diwa"
Type "learning"
Sleep 3s

# Jump to headline
Enter
Sleep 3s

# Reopen picker, switch to orgfiles mode
Type " ff"
Sleep 3s

# Filter for a specific file
Type "project"
Sleep 3s

# Jump to file
Enter
Sleep 3s

Hide
Type ":q!"
Enter
Sleep 0.5s
