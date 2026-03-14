Output out/refile.webm

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

# Go to end of file and add a personal task that ended up in work
Type "Go"
Sleep 0.3s
Type "* TODO Buy birthday present for Mom"
Escape
Sleep 2s

# Refile it to personal.org where it belongs
Type " r"
Sleep 1s
Ctrl+Space
Sleep 1s

# Search for destination in personal.org
Type "ipersonal"
Sleep 3s

# Confirm refile + dismiss prompt + clear screen
Hide
Enter
Sleep 3s
Enter
Sleep 2s
Type ":redraw!"
Enter
Show
Sleep 2s

# Verify: search all headlines for the refiled item
Type " fh"
Sleep 2s
Type "birthday"
Sleep 2s
Enter
Sleep 3s

Hide
Type ":q!"
Enter
Sleep 0.5s
