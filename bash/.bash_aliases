#alias git='~/bin/hub'

function set_tab_title() {
	echo -en "\033]0;$1\a"
}

alias kom='komodo-edit'

alias rcload='source ~/.bashrc'
alias rcedit='(gedit ~/.bashrc &)'
alias rcaedit='(gedit ~/.bash_aliases &)'
alias rcpedit='(gedit ~/.bash_PS1 &)'

alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
fnd() {
	find . -iwholename 2>&1 "$@" |
	grep -Ev "^find: ‘.*’: Permission denied$"
}

alias cleanpyc='find . -iname "*.pyc" -exec rm {} \;'

alias gbr='git branch'
alias gst='git status'
alias gsl='git stash list'
alias gsmfe='git submodule foreach'
alias gcf='git diff-tree --no-commit-id --name-only -r'
alias grh='git reset HEAD'

function gitstashshow {
	git stash show stash@{$1}
}
alias gss='gitstashshow'
function gitstashapply {
	git stash apply stash@{$1}
}
alias gsa='gitstashapply'
function gitstashdrop {
	git stash drop stash@{$1}
}
alias gsdr='gitstashdrop'

gdt() {
	(git difftool --dir-diff "$@" &)
}

alias YOLO#='git push --force'
alias SWAG#='git commit -a --amend -C HEAD'

#Match letters in a list, eg. 'APC' will match 'APoCalypse'
function matchletters {
	grep "`
		echo "$1" |
		sed -r "s/(.)/\1.*/g"
	`"
}

stripcolors() {
	sed -r "s/\x1B\[([0-9!?]{1,2}(;[0-9]{1,2})?)?[m|K|l|p]|\x1B>//g"
}

function gitcheckoutabbreviation {
	#If it is about going back to previous branch then simply checkout
	if [ "$1" == "-" ]
	then
		git checkout "$@"
		return
	fi
	
	#If it is about files then simply checkout
	if [ "$1" == "--" ]
	then
		git checkout "$@"
		return
	fi
	
	#Find a match in local branches
	local branches=`
		git branch |
		matchletters "$1"
	`
	
	if [ `echo "$branches" | wc -w` == "0" ]
	then
		#Find a match in remote branches
		branches=`
			git branch -a |
			sed "s/  remotes\/origin\///" |
			matchletters "$1"
		`
	fi
	
	if [ `echo "$branches" | wc -w` == "0" ]
	then
		#Find an exact match in tags
		branches=`
			git tag |
			grep -e "^$1$"
		`
	fi
	
	branches=`
		echo "$branches" |
		sed -r "s/^\W*(\w+)/\1/"
	`
	
	if [ `echo "$branches" | wc -w` == "1" ]
	then
		#If we found exactly one then check out
		git checkout "$branches"
	else
		if [ `echo "$branches" | grep "^$1$"` ]
		then
			#If it is an exact match, but others have it as a
			#substring then check out
			git checkout "$1"
		elif [ `echo "$branches" | wc -w` == "0" ]
		then
			echo "No local or remote branches or tags matched"
		else
			#Show the available branches
			echo "$branches"
		fi
	fi
}
alias gco='gitcheckoutabbreviation'

#All changed/added files visible by git
function gitallfiles {
	git status | 
	grep -P "^#\t" | 
	sed -r "s/^#\t(.*:\s*)?//"
}
alias gall='gitallfiles'
function gitaddallfiles {
	git add `gitallfiles`
}

function gitaddabbreviation {
	local files=`
		gitallfiles |
		grep "$1"
	`
	git add $files
	echo "$files"
}
alias ga='gitaddabbreviation'

alias pretty_logs='python -u ~/python/pretty_logs.py'

function gitbasedir {
	local gitdir=`
		pwd | 
		sed -r "s#(git/[^/]*/).*#\1#"
	`
	if [[ "$gitdir" == *git/* ]]
	then
		echo $gitdir
	fi	
}

gitfoldername() {
	local gbd=`gitbasedir`
	
	if [ -n "$gbd" ]
	then
		gbd=${gbd#*git/}"/"
		echo ${gbd%%/*}
	fi
}

function gitnewbranch {
	git checkout -b "$1" &&
	git push origin "$1" &&
	git branch -u "origin/$1"
}
alias gnb='gitnewbranch'

alias gsno='git show --name-only'
alias gdno='git diff --name-only'
alias grh='git reset HEAD'

#Git log of a specific author (or everybody if none specified)
function gitof()
{
	if [ -z "$1" ]
	then
		git log --pretty=format:"%Cgreen%h%Creset %Cblue%an%Creset %s" --abbrev-commit
	else
		git log --pretty=format:"%Cgreen%h%Creset %s" --abbrev-commit --author="$1"
	fi
}
mygit ()
{
	if [ -z "$1" ]
	then
		git log --author=Costas --pretty=oneline
	else
		git log --author=Costas --pretty=oneline |
		grep "$@"
	fi
}

function gitcoms() {
	git blame $@ | #Get the blame
	nicesummarygitcommits
}

#Display the commits in a piece of code, ordered by chronological order, most recent first
function nicesummarygitcommits()
{
	sed -r "s/^(........).*/\1/" | #Extract the commit hash
	sort | #Sort
	uniq | #and get a unique list of hashes
	summarygitcommits | #And display the hashes
	sort -r | #Sort by date, time
	sed -r "s/ [[:digit:]]{2}:[[:digit:]]{2}:[[:digit:]]{2} .?[[:digit:]]{4}//" #Hide the time
}

#Display a list of commits that are present in the specified commit, but the current one
function cherry()
{
	git cherry "$@" |
	awk '{print $2}' |
	xargs -n 1 git log --pretty=oneline --abbrev-commit -n 1
}

#Display the commits commit summary for a list of commit
function summarygitcommits()
{
	xargs -L1 sh -c '
	{
		echo `
			git log -1 --pretty=format:"%ai %Cgreen%h%Creset %Cblue%an%Creset %s" --date=short $0
		`;
	}' #Echo the date, time, hash, commiter and message for each commit
}

#Show the brance of submodules
function gitsubmodulebranch()
{
	cd `gitbasedir`
	
	{
		git branch;
		git submodule foreach git branch;
	} | #Show branch info of project and submodules
	grep -E "(\\*|Entering)" | #Keep submodule name and branch
	sed "s/\\* /\t\t\t/" | #Pad branch
	sed -r "s/Entering '(.*)'/\1/" #Keep submodule name only
	
	cd - > /dev/null
}
alias gsmbr='gitsubmodulebranch'

#Pull all submodules
function gitsubmodulepull()
{
	cd `gitbasedir`
	
	{
		git pull 2>&1;
		git submodule foreach git pull 2>&1;
	} | #Pull project and submodules
	#Keep submodule name and change info
	egrep "(Entering|Already up-to-date| .* files? changed, |Please, commit|Aborting)" | 
	sed -r "s/^(Already| |Please, commit)/\t\t\t\1/" | #Pad change info
	sed -r "s/Entering '(.*)'/\1/" #Keep submodule name only
	
	cd - > /dev/null
}
alias gsmp='gitsubmodulepull'

#Checkout the same branch on all submodules
function gitsubmodulecheckout()
{
	cd `gitbasedir`
	
	{
		git checkout $1 2>&1;
		git submodule foreach git checkout $1 2>&1;
	} | #Checkout project and submodules
	#Keep submodule name and change info
	egrep "(Entering|Switched|Already|Please, commit|Aborting)" | 
	#Pad change info
	sed -r "s/(Switched|Already|Please, commit).* '(.*)'/\t\t\t\2/" | 
	sed -r "s/Entering '(.*)'/\1/" #Keep submodule name only
	
	cd - > /dev/null
}
alias gsmco='gitsubmodulecheckout'

unmin_css() {
	sed -re 's/([{};,])/\1\n/g' "$@"
}

git_min_css_diff() {
	local git_file="$1"
	local difftool="$2"
	if [ -z "$difftool" ]
	then
		difftool="meld"
	fi
	
	local temp_original=`mktemp`
	local temp_new=`mktemp`
	
	git show "HEAD:$git_file" | unmin_css > temp_original
	unmin_css "$git_file" > temp_new
	
	$difftool temp_original temp_new
	
	rm temp_original temp_new
}

gitfinddiff() {
	local iter=0
	local found=0
	
	#If the skip/after-commit is empty, or we said 'all', then don't skip anything
	if [ -z "$2" ] || [ "$2" == "all" ]
	then
		found=1
	fi
	
	git log --pretty=format:"%h" |
	while read -r commit_ref
	do
		#If need to skip more
		if [ $found == 0 ]
		then
			#If we skipped enough lines
			if [ "$iter" -ge "$2" ] 2>&0
			then
				echo "Skipped $iter commits"
				found=1
			else
				#If we found the commit to skip
				if [ ${#PWD} -ge 7 ] && ( [[ "$commit_ref" == "$2"* ]] || [[ "$2" == "$commit_ref"* ]] )
				then
					echo "Skipped after commit $commit_ref"
					found=1
				fi
			fi
		else
			if git show "$commit_ref" | grep -e "^[+-].*$1" > /dev/null;
			then
				echo "Found after $iter, at $(git log --pretty=format:"%Cgreen%h%Creset %Cblue%an%Creset %s" -n 1 $commit_ref)"
				#Stop
				if [ "$2" != "all" ] && [ "$3" != "all" ]
				then
					break
				fi
			fi
		fi
		iter=$((iter+1))
	done
}
alias gfd='gitfinddiff'

gitfindfile() {
	local iter=0
	local found=0
	
	#If the skip/after-commit is empty, or we said 'all', then don't skip anything
	if [ -z "$2" ] || [ "$2" == "all" ]
	then
		found=1
	fi
	
	git log --pretty=format:"%h" |
	while read -r commit_ref
	do
		#If need to skip more
		if [ $found == 0 ]
		then
			#If we skipped enough lines
			if [ "$iter" -ge "$2" ] 2>&0
			then
				echo "Skipped $iter commits"
				found=1
			else
				#If we found the commit to skip
				if [ ${#PWD} -ge 7 ] && ( [[ "$commit_ref" == "$2"* ]] || [[ "$2" == "$commit_ref"* ]] )
				then
					echo "Skipped after commit $commit_ref"
					found=1
				fi
			fi
		else
			if git diff-tree --no-commit-id --name-only -r "$commit_ref" | grep -e "$1" > /dev/null;
			then
				echo "Found after $iter, at $(git log --pretty=format:"%Cgreen%h%Creset %Cblue%an%Creset %s" -n 1 $commit_ref)"
				#Stop
				if [ "$2" != "all" ] && [ "$3" != "all" ]
				then
					break
				fi
			fi
		fi
		iter=$((iter+1))
	done
}
alias gff='gitfindfile'

ggrep()
{
	git grep -ni "$@" | sed "s/\t+/\t/g" -r | more
}

#Nice grep: group by filename, trim whitespace, highlight a phrase
#$1 is the phrase to highlight, $2 should be 'i' for case-insenstive
function nicegrep()
{
	#Coloring constants
	local tpi=$(tput init)
	local tpn=$(tput setaf 2)
	local tpf=$(tput setaf 5)
	local tpo=$(tput setaf 1)
	local tpbp=$(tput setab 3)
	local tpbh=$(tput setab 4)
	local tpbj=$(tput setab 1)
	local tpbc=$(tput setab 2)
	local tpbs=$(tput setab 6)
	
	local i=0
	local args=()
	local pfile=""
	local tpbfile=""
	local outp
	
	#we use two color codes * 9 chars each
	local maxcols=$((COLUMNS + 18))
	
	#Break the input into 3 lines: file, line number, contents
	sed -r "s/^([^:]*)[:\-](\w+)[:\-]\t*/\1\n\2\n/" |
	while read -r line
	do
		if [ "$line" == "--" ]
		then
			echo "--"
		elif [ "${line:0:12}" != "Binary file " ]
		then
			args[i]=$line
			i=$((i+1))
			
			if [ $i -eq 3 ]	#Every 3 lines we have a grep match
			then
				i=0
				if [ "$pfile" != "${args[0]}" ] #Group by file
				then
					pfile="${args[0]}"
					
					#Background color per file type
					if [[ "$pfile" == *.py ]]
					then
						tpbfile=$tpbp
					elif [[ "$pfile" == *.html ]]
					then
						tpbfile=$tpbh
					elif [[ "$pfile" == *.js ]]
					then
						tpbfile=$tpbj
					elif [[ "$pfile" == *.css ]]
					then
						tpbfile=$tpbc
					elif [[ "$pfile" == *.sql ]]
					then
						tpbfile=$tpbs
					elif [[ "$pfile" == *.pkb ]]
					then
						tpbfile=$tpbs
					elif [[ "$pfile" == *.pks ]]
					then
						tpbfile=$tpbs
					else
						tpbfile=""
					fi
					
					echo "$tpbfile $tpi$tpf$pfile$tpi"
				fi
				outp="$tpbfile :${args[1]}	$tpi${args[2]}"
				if [ ${#outp} -gt $maxcols ] #Truncate to screen
				then
					outp=${outp:0:$maxcols}
				fi
				if [ -n "$1" ] #Highlight a provided phrase
				then
					#Escape unescaped / in search term
					local search_term=`echo "$1" | sed "s/\(^\|[^\\]\)\\//\1\\\\\\\\\//g"`
					outp=`echo "$outp" | sed "s/\($search_term\)/$tpo\1$tpi/g$2"`
				fi
				echo "$outp"
			fi
		fi
	done
	
	echo -n "$tpi"
}
alias ng='nicegrep'

#Gather files from nicegrep
nicegrepfiles() {
	egrep "^[^:]+[\\w\\.]+[^:]+$"
}
alias ngfiles='nicegrepfiles'

#Nice git grep
nicegitgrep() {
	local searchterm=""

	if [[ "$1" =~ ^-[ABC]$ ]]
	then
		if [[ "$3" =~ ^-[ABC]$ ]]
		then
			if [[ "$5" =~ ^-[ABC]$ ]]
			then
				searchterm="$7"
			else
				searchterm="$5"
			fi
		else
			searchterm="$3"
		fi
	else
		searchterm="$1"
	fi

	git grep -ni "$@" | 
	ng "$searchterm" "i"
}
alias ngg='nicegitgrep'
nggd() {
	nicegitgrep "$@" |
	nicegrepfiles
}
nggt() {
	nggd "$@" |
	filelisttree
}

#Nice git grep case sensitive
function nicegitgrepcasesens() {
	git grep -n "$@" | 
	ng "$1"
}
alias nggs='nicegitgrepcasesens'
nggsd() {
	nicegitgrepcasesens "$@" |
	nicegrepfiles
}
nggst() {
	nggd "$@" |
	filelisttree
}

#Nice grep
function nicenormalgrep() {
	grep -nir "$@" --binary-files=without-match | 
	ng "$1" "i"
}
alias ngrep='nicenormalgrep'

#Nice grep case sensitive
function nicenormalgrepcasesens() {
	grep -nr "$@" --binary-files=without-match | 
	ng "$1"
}
alias ngreps='nicenormalgrepcasesens'

#Nice grep show onyl files
function nicegrepfilesonly() {
	grep -r "^[^ ]" --color=never
}
alias ngfo='nicegrepfilesonly'

function replace() {
	find ./ -type f | xargs -L1 sh -c '
	{
		sed -iu "r/$1/$2/g"
	}
	'
}

filetree() {
	local first=${1%%/*}
	local rest=${1#$first/}
	local indent="$2"

	if [ -n "$first" ]
	then
		if [ "$1" != "$rest" ] && [ "$rest" != "$1/" ] && [ -n "$rest" ]
		then
			echo "$indent$first/"
		else
			echo "$indent$first"
		fi
	fi
	if [ "$1" != "$rest" ] && [ "$rest" != "$1/" ] && [ -n "$rest" ]
	then
		filetree "$rest" "$indent  "
	fi
}

twofilestree() {
	local lastcommon=""
	local last1="$1"
	local last2="$2"
	local first1=""
	local first2=""
	local rest1="$1"
	local rest2="$2"
	local indent=""
	
	while [ "$first1" = "$first2" ]
	do
		lastcommon="$lastcommon/$first1"
		last1="$rest1"
		last2="$rest2"
		first1=${rest1%%/*}
		first2=${rest2%%/*}
		rest1=${rest1#$first1/}
		rest2=${rest2#$first2/}
		indent="$indent  "
	done
	
	lastcommon=${lastcommon#//}
	lastcommon=${lastcommon#/}
	indent=${indent#  }
	filetree "$lastcommon"
	echo "$indent>$last1"
	echo "$indent>$last2"
}

filelisttree() {
	local prevfile=""
	
	while read -r thisfile
	do
		local colorstart=`
			echo "$thisfile" |
			sed -r "s/^((\x1B\[([0-9!?]{1,2}(;[0-9]{1,2})?)?[m|K|l|p]|\x1B>| )*).*/\1/"
		`
		local colorend=`
			echo "$thisfile" |
			sed -r "s/^((\x1B\[([0-9!?]{1,2}(;[0-9]{1,2})?)?[m|K|l|p]|\x1B>| )*)[^\x1B]*//"
		`
		thisfile=`
			echo "$thisfile" |
			stripcolors
		`
		thisfile=${thisfile# }
		local lastcommon=""
		local last1="$prevfile"
		local last2="$thisfile"
		local first1=""
		local first2=""
		local rest1="$prevfile"
		local rest2="$thisfile"
		local indent=""
	
		while [ "$first1" = "$first2" ]
		do
			lastcommon="$lastcommon/$first1"
			last1="$rest1"
			last2="$rest2"
			first1=${rest1%%/*}
			first2=${rest2%%/*}
			rest1=${rest1#$first1/}
			rest2=${rest2#$first2/}
			indent="  $indent"
		done
	
		lastcommon=${lastcommon#//}
		lastcommon=${lastcommon#/}
		indent=${indent#  }
		#filetree "$lastcommon"
		if [ "${last2%/*}" != "${last2##*/}" ]
		then
			filetree "${last2%/*}/$colorstart${last2##*/}$colorend" "$indent"
		else
			echo "$indent$colorstart$last2$colorend"
		fi
		
		prevfile="$thisfile"
	done
}

function manage_py() {
	fnd "*/manage.py" |
	head -n 1
}

function run_django_server() {
	local host="0.0.0.0"
	local port="$1"
	if [ -z "$port" ]
	then
		port="8000"
	fi
	
	`manage_py` runserver_plus "$host:$port" --traceback
}
alias server='run_django_server'

function run_django_shell_plus() {
	`manage_py` shell_plus
}
alias plus='run_django_shell_plus'

django_template_names() {
	echo "$1"
	
	local filename="$1"
	while [[ "$filename" == */* ]]
	do
		filename="${filename#*/}"
		if [ -n "$filename" ]
		then
			echo "$filename"
		fi
	done
}

django_template_in_html() {
	ggrep -e "{%\s*\(include\|extends\)\s*\('\|\"\)$1\.html" | #Grep for HTML
	sed -r "s/.*\{%\s*(include|extends)\s*('|\")((\w+\/)*?\w+)\.html.*?/\3/" #Keep source template name
}

django_template_in_python() {
	ggrep -e "\('\|\"\|\s\)$1\.html" -- "*.py" | #Grep for HTML
	sed -r "s/.*('|\"|\s)((\w+\/)*?\w+)\.html.*?/\2/" #Keep source template name
}

django_html_with_template() {
	ggrep -e "{%\s*\(include\|extends\)\s*\('\|\"\)$1\.html" | #Grep for HTML
	sed -r "s/((\w|[-_.])+\/)*templates\/(((\w|[-_.])+\/)*?(\w|[-_.])+)\.html:.*?/\3/" #Keep calling template name
}

django_python_with_template() {
	ggrep -e "\('\|\"\|\s\)$1\.html" -- "*.py" | #Grep for HTML
	sed -r "s/^((((\w|[-_.])+\/)*?(\w|[-_.])+))\.py:(.*?):.*?/\1.py#\6/" #Keep calling python name
}

django_template_path() {
 	#Coloring constants
	local tpi=`tput init`
	local tph=`tput setaf 4`
	local tpp=`tput setaf 3`
	
	if [ "$2" = "" ]
	then
		echo "Template ancestors path for $1: "
		
		{
			django_template_in_html "[[:alnum:]_/-]*$1" &&
			django_template_in_python "[[:alnum:]_/-]*$1"
		} |
		sort | #Sort
		uniq | #and keep unique list
		while read -r line;
		do

			django_template_path "$line" " "
		done
	else
		#Output template name
		if [ "$2" == " " ]
		then
			echo "*$tph$1.html$tpi"
		else
			echo "$2$tph$1.html$tpi"
		fi
	
		django_html_with_template "$1" |
		sort | #Sort
		uniq | #and keep unique list
		while read -r line;
		do
			#Check if the tempalte is recursively included
			if [[ "$3;$1;" == *";$line;"* ]]
			then
				echo "$tph$2 $line.html$tpi is recursive"
			else
				#Go a level deeper
				django_template_path "$line" "-$2" "$3;$1;"
			fi
		done
	
		django_python_with_template "$1" |
		sort | #Sort
		uniq | #and keep unique list
		while read -r line;
		do
			echo "-$2$tpp$line$tpi"
		done
		
		echo -n "$tpi"
	fi
}
alias djpath='django_template_path'

tst() {
	{
		echo 'a' 'b' &&
		echo 'c' 'd' 'e' 'i' &&
		echo 'f g' 'h'
	} |
	while read -r line1 line2 line3;
	do
		echo "$line1 - $line2 - $line3"
	done
}

remove_color() {
	perl -pe 's/\e\[(\d+|!|\?\d+;\d+)[a-z]|\e>//g'
}
