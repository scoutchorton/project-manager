#!/usr/bin/env bash 
#PROJECTMANAGER v1.3
#  Manage a programming projects folder automagically based on langauge and project. 
#  (c) 2020 scoutchorton

#
# Variables
#

#Command name
PROJECTS_COMMAND="proj"
alias $PROJECTS_COMMAND='__proj'

#
# Project manager
#

export PROJECTS_DIR="/home/$USER/Programming"
function __proj {
	#
	# Colors
	#
	
	#If terminal supports colors
	if [ -n "$(tput colors)" ]; then
		#Set colors
		#tput wasn't used for set the colors because the standard escape sequences are implemented in Bash, so might as well use the feature.
		_RESET="\e[0m"
		_PROMPT="\e[93m"
		_GOOD="\e[92m"
		_BAD_B="\e[1;91m"
		_BAD="$_RESET\e[91m"
	#If terminal doesn't support colors
	else
		#Set the variables to nothing
		_RESET=''
		_PROMPT=''
		_GOOD=''
		_BAD_B=''
		_BAD=''
	fi
	
	#
	# Help searching
	#

	#Search arguments for --help or -h
	if [ -n "$(echo $@ | sed '/-\<h\>\|--\<help\>/!d')" ]; then
		#Usage information to parse later
		usageArray=(\
		"$PROJECTS_COMMAND;Change to project folder." \
		"$PROJECTS_COMMAND -l|-ls;List the project folder files." \
		"$PROJECTS_COMMAND LANGUAGE;If LANGUAGE exists, change to the folder, otherwise prompt to create folder." \
		"$PROJECTS_COMMAND LANGUAGE [-l|-ls];List the contents of the folder for LANGUAGE." \
		"$PROJECTS_COMMAND LANGUAGE PROJECT;If PROJECT exists, change to the folder, otherwise prompt to create folder." \
		"$PROJECTS_COMMAND -h|--help;Display information about usage."
		)
		#Length of the longest command
		len=0
		
		#Header
		echo -e ""
		echo -e "Project Manager v1.3"
		echo -e "  Neatly and automagically manage programming projects by language from the command line."
		echo -e ""
		echo -e "Usage:"
		
		#Turn off IFS
		IFS=''
		#Loop through command list
		for cmd in ${usageArray[@]}; do
			lineLen="$(echo $cmd | cut -d ';' -f 1 | wc -m)"
			[ "$lineLen" -gt "$len" ] && len="$lineLen"
		done
		#Loop through command list
		for cmd in ${usageArray[@]}; do
			printf "  %-*s- %s\n" "$len" "$(echo -e "$(echo $cmd | cut -d ';' -f 1)")" "$(echo -e "$(echo $cmd | cut -d ';' -f 2)")"
		done
		#Revert IFS
		unset IFS
		
		#Copyright
		echo -e ""
		echo -e "(c) 2020 scoutchorton"
		echo -e ""
		return 0
	fi

	#
	# Main processing
	#
	
	#Branch on number of arguments
	case $# in
		#Zero arguments
		0)
			#Change to projects directory
			cd $PROJECTS_DIR 2> /dev/null || (1>&2 echo -e "${_BAD_B}ERR:${_BAD} Could not change into projects directory." && return 1)
			;;
		
		#One argument
		1)
			#Check if the argument is -l or -ls to list project directory
			if [ -n "$(echo "$1" | sed '/-l\|-ls/!d')" ]; then
				ls $PROJECTS_DIR
			#Manage language
			else
				#Get all folders immediately in project directory, remove path, remove empty lines, change spaces to dashes, add \| to the end of every line, remove newlines
				foldersRegex=$(find $PROJECTS_DIR/ -maxdepth 1 -type d,l | sed "s:$PROJECTS_DIR/::g;/^$/d;s: :-:g;s:^:^:g;s:\$:\$:g;s:$:\\\\|:g;\$s:..\$::" | tr -d "\n")
				#Check for existing folders, and also the argument is in the list of folders
				if [ -n "$foldersRegex" ] && [ -n "$(echo $1 | sed '/'$foldersRegex'/!d')" ]; then
					#Change into language folder
					cd $PROJECTS_DIR/$1 2> /dev/null || (1>&2 echo -e "${_BAD_B}ERR:${_BAD} Cannot change into $1." && return 1)
				#If folder does not exist
				else
					#Prompt to create folder
					echo -ne "Language ${1} not found. Create folder? [Y/n] ${_PROMPT}"
					read res && echo -ne "${_RESET}"
					#If the user's answer starts with n (case insenitive)
					if [ -n "$(echo $res | grep -oi '^n' )" ]; then
						#Take no action.
						echo -e "${_GOOD}No action taken." && echo -ne "${_RESET}"
					#If the user answered not n
					else
						#Make folder and change into it
						mkdir $PROJECTS_DIR/$1 2> /dev/null && cd $PROJECTS_DIR/$1 || (1>&2 echo -e "${_BAD_B}ERR:${_BAD} Cannot create directory for $1." && return 1)
					fi
				fi
			fi
			;;
		
		#Two arguments
		2)
			#Check if the argument is -l or -ls to list language
			if [ -n "$(echo $2 | sed '/-l\|-ls/!d')" ]; then
				#Check if language directory exists
				if [ -d $PROJECTS_DIR/$1 ]; then
					ls $PROJECTS_DIR/$1
				#Error if language doesn't exist
				else
					1>&2 echo -e "${_BAD_B}ERR:${_BAD} $1 is not a valid language." && return 1
				fi
			#Manage projects
			else
				#Again getting all folders in project directory
				foldersRegex=$(find $PROJECTS_DIR/ -maxdepth 1 -type d,l | sed "s:$PROJECTS_DIR/::g;/^$/d;s: :-:g;s:^:^:g;s:\$:\$:g;s:$:\\\\|:g;\$s:..\$::" | tr -d "\n")
				#Check for existing language folders, and also the argument iis in the list of folders
				if [ -n "$foldersRegex" ] && [ -n "$(echo $1 | sed '/'$foldersRegex'/!d')" ]; then
					#Similar to $foldersRegex but with the subdirectory that is confirmed to exist
					projectsRegex=$(find $PROJECTS_DIR/$1  -maxdepth 1  -type d,l | sed "s:$PROJECTS_DIR/$1/*::g;/^$/d;s: :-:g;s:^:^:g;s:\$:\$:g;s:$:\\\\|:g;\$s:..\$::" | tr -d "\n")
					#If projects exist and the project specified is in the list of project folders
					if [ -n "$projetsRegex" ] || [ -n "$(echo $2 | sed '/'$projectsRegex'/!d')" ]; then
						#Change to language folder
						cd $PROJECTS_DIR/$1/$2
					#If the project doesn't exist
					else
						#Prompt to create folder
						echo -ne "Project ${1}/${2} not found. Create project? [Y/n] ${_PROMPT}"
						read res && echo -ne "${_RESET}"
						#If the user's answer starts with n (case insenitive)
						if [ -n "$(echo $res | grep -oi '^n' )" ]; then
							#Take no action
							echo -e "${_GOOD}No action taken." && echo -ne "${_RESET}"
							#If the user answered not n
						else
							#Make project directory and change into it
							mkdir $PROJECTS_DIR/$1/$2 2> /dev/null && cd $PROJECTS_DIR/$1/$2 || (1>&2 echo -e "${_BAD_B}ERR:${_BAD} Connot create directory for $1/$2." && return 1)
							[ -d ../.template ] && cp -r ../.template/* ./
						fi
					fi
				#If language folder doesn't exist
				else
					#Attempt to create language folder by rerunning with just that language
					proj $1
					#If the user created the folder, retry to create the project
					[ -d $PROJECTS_DIR/$1 ] && proj $@
				fi
			fi
			;;

		#For any more than 2 arguments
		*)
			1>&2 echo -e "${_BAD_B}ERR:${_BAD} More arguments than expected. Run with the \`--help\` argument to see usage." && return 1
			;;
	esac
	return 0
}
#
# Tab completion manager
#
function __projects {
	#
	# $COMP_WORDS is an array of the args currently being processed. ${COMP_WORDS[0]} will be the executable, ${COMP_WORDS[1]} is the first argument, ${COMP_WORDS[2]} the second, etc.
	# The array elements are only created if they exist (ex: the index of 3 won't exist if there are only 2 arguments).
	# Since the first argument is always expected to be a language name, you can use ${COMP_WORDS[1]} to process the language specifically.
	#
	#Get names of language folders
	#local languages=$(find $PROJECTS_DIR/ -maxdepth 1 -type d,l | sed "s:$PROJECTS_DIR/::g;/^$/d;s: :-:g" | tr "\n" ' ') 2> /dev/null || return 1
	local languages=$(find $PROJECTS_DIR/ -maxdepth 1 -type d,l | sed "s:$PROJECTS_DIR/::g;s:^\..\+$::g;/^$/d" | tr "\n" ' ') 2> /dev/null || return 1
	#Gets the first word after the command
	local projNames=${COMP_WORDS[1]}

	#Check if language name only has one hit in projects list (none other matches), and also that the word is a finished language
	if [ -n "$(echo $languages | tr ' ' "\n" | sed -n "/^$projNames/p")" ] && [ "${#COMP_WORDS[@]}" == "3" ]; then
		#Get names of project folders within the language
		#local projects=$(find $PROJECTS_DIR/$projNames -maxdepth 1  -type d,l | sed "s:$PROJECTS_DIR/$projNames/*::g;/^$/d;s: :-:g" | tr "\n" ' ')
		local projects=$(find $PROJECTS_DIR/$projNames -maxdepth 1  -type d,l | sed "s:$PROJECTS_DIR/$projNames/*::g;s:^\..\+$::g;/^$/d" | tr "\n" ' ')
		#Get suggestions based on projects and the user's uncompleted word
		COMPREPLY=( $(compgen -W "$projects" -- "${COMP_WORDS[COMP_CWORD]}") )
		return 0
	#If the word isn't a complete language name
	else
		#Get suggestions based on the languages and the user's uncompleted word
		COMPREPLY=( $(compgen -W "$languages" -- "${COMP_WORDS[COMP_CWORD]}") )
		return 0
	fi
}

#Register function for processing tab completion 
complete -F __projects $PROJECTS_COMMAND
