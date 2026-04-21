-- Sets the font for all Terminal.app profiles to Maple Mono NF CN.
-- Usage: osascript terminal/set-font.applescript
--
-- Terminal.app stores profile settings in a binary plist with archived
-- NSFont blobs, which doesn't round-trip cleanly through a dotfiles repo.
-- Running this script after installing the font (brew bundle) is the
-- reliable way to apply it to every settings set.

set fontName to "MapleMono-NF-CN-Regular"
set fontSize to 13

tell application "Terminal"
	repeat with s in (settings sets)
		try
			set font name of s to fontName
			set font size of s to fontSize
		end try
	end repeat
end tell
