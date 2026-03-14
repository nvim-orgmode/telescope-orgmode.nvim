Output out/tag-search.webm

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

# Open tag search
Type " ft"
Sleep 3s

# Select "work" tag
Type "work"
Sleep 2s
Enter
Sleep 3s

# Now in headlines filtered by :work: tag
# Go back to tags with C-t
Ctrl+t
Sleep 3s

# Try a different tag
Escape
Type "diwa"
Type "personal"
Sleep 2s
Enter
Sleep 3s

# Navigate to a headline
Enter
Sleep 3s

Hide
Type ":q!"
Enter
Sleep 0.5s
