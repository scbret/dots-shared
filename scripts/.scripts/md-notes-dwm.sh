#!/usr/bin/env sh

folder=/home/steve/repos/linux/mdnotes/
#folder=/home/steve/repos/zk-notes/notes/

newnote () { \
	name="$(echo "" | dmenu -sb "#a3be8c" -nf "#d8dee9" -p "Enter a name: " <&- )"
	setsid -f "st" -e nvim $folder$name".md" >/dev/null 2>&1
}

selected () { \
	choice=$(echo -e "New\n$(ls -t1 $folder)" | dmenu -l 12 -i -p "Choose note or create new: ")
	case $choice in
		New) newnote ;;
		*md) setsid -f "st" -e nvim "$folder$choice" >/dev/null 2>&1 ;;
		*) exit ;;
	esac
}

selected
