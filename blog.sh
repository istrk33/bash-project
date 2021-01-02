#!/bin/bash

###################################################################
# - blog.sh                                                       #
# - Utility:                                                      #
#    This script allows you to manage the modification            #
#    and deletion of markdown files or to convert them            #
#    to html format                                               #
# - Usage:                                                        #
#    Edit a markdown file : ./blog.sh edit [PAGE]                 #
#    Delete a markdown file : ./blog.sh delete [PAGE]             #
#    List all markdown files : ./blog.sh list                     #
#    Build Html and pdf files : ./blog.sh build                   #
#    View the site : ./blog.sh view [pdf]                         #
# - Autors: Bogdan DIMCHEV <bogdan.dimchev@etu.u-bordeaux.fr>     #
#           Ilker SOYTURK <ilker.soyturk@etu.u-bordeau.fr>        #
# - Updated the: 16/12/2019                                       #
###################################################################

set -o errexit  # Exit if command failed.
set -o pipefail # Exit if pipe failed.
set -o nounset  # Exit if variable not set.
# Remove the initial space and instead use '\n'.
IFS=$'\n\t'

# The purpose of this function is to
# edit markdown files with some editors
function edit() {
    #testing if the environment variable $EDITOR exist
    if test "$EDITOR"; then
        $EDITOR markdown/"$*"
        #testing /usr/bin/editor
    elif test /usr/bin/editor; then
        /usr/bin/editor markdown/"$*"
    else
        #testing other editors
        if test /usr/bin/code; then
            /usr/bin/code markdown/"$*"
        elif test /usr/bin/pluma; then
            /usr/bin/pluma markdown/"$*"
        elif test /bin/nano; then
            /bin/nano markdown/"$*"
        fi
    fi
}

# The purpose of this function is to list all markdown
# files in the markdown/ directory if they exist
function list() {
    var=$(find markdown/ -name "*.md" | wc -l)
    if test "$var" -ne 0; then
        echo "Here are the markdown files present :"
        find markdown/ -name "*.md" -printf "%f\n"
    else
        echo "There is not markdown files." 2>&1
        exit 1
    fi
}

# The purpose of this function is to delete a markdown
# file in the markdown/ directory if there is some
# markdown file
function delete() {
    echo "Are you sure to want to delete  $* ?(y/n)"
    read -r answer
    if test "$(echo "$answer" | tr '[:upper:]' '[:lower:]')" = "y"; then
        rm markdown/"$*"
        echo "$* deleted"
    else
        echo "Deletion cancelled" 2>&1
    fi
}

# The purpose of this function is to delete all old
# files of the web directory and the index.md file
function resetBuild() {
    rm -rf web/*

    if [ -f markdown/index.md ]; then
        rm markdown/index.md
    fi

    #remove pictures from the script directory
    for images in $(file -i -- *glob* | grep ":.*image" | cut -d":" -f 1); do
        rm "$images"
    done
}

# The purpose of this function is to convert all .md files
# from the markdown/ directory to html file in the web directory
# and converting all markdown files from the source directory
# to one pdf file
function build() {
    #delete all old files concerning the build
    resetBuild
    echo "Reset completed successfully..."

    #copy all pictures in the web directory and in the project directory
    for picture in $(file -i markdown/* | grep ":.*image" | cut -d":" -f 1); do
        picName=$(echo "$picture" | cut -d"/" -f 2)
        cp "$picture" web/"$picName"
        cp "$picture" "$picName"
    done
    echo "All pictures are copied successfully..."

    #converting all markdown files to html files
    markdownFiles=$(find -name "*.md" -printf "%f\n")
    for mdFile in $markdownFiles; do
        removeExtension=$(echo "$mdFile" | cut -d"." -f 1)
        pandoc markdown/"$mdFile" -f markdown -t html -s -o web/"$removeExtension.html"
    done
    echo "Generating html files completed successfully..."

    #generating the pdf file with all markdowns in
    pandoc markdown/*.md -o web/blog.pdf
    echo "Generating pdf file completed successfully..."

    #generating the index file
    echo "Contenu actualisé le $(date | cut -d"," -f 1) à $(date | cut -d"," -f 2 | cut -d"(" -f 1) par $USER sur $HOSTNAME  " >markdown/index.md
    htmlFiles=$(find -name "*.html" -printf "%f\n")
    for fileHtml in $htmlFiles; do
        removeExtension=$(echo "$fileHtml" | cut -d"." -f 1)
        echo "[$removeExtension](../web/$fileHtml)  " >>markdown/index.md
    done
    #the pdf file link in the index
    echo "[blog.pdf](../web/blog.pdf)  " >>markdown/index.md
    echo "Generating index file completed successfully..."
    echo "Build FINISH."
}

# The purpose of this function is to convert the index.md file
# to html, and viewing it from a web browser (if we don't put parameters).
# If there is the "pdf" parameter, it open blog.pdf file
function view() {
    if test "$@" = "pdf"; then
        xpdf web/blog.pdf 2>/dev/null
    else
        echo "Unvalid argument" 2>&1
    fi
}

# The purpose of this function is display all
# usages of the script to the user
function usage() {
    echo "The list of commands is edit, delete, list, build
- Edit a file : ./blog.sh edit [PAGE]
- Delete a file : ./blog.sh delete [PAGE]
- List all files : ./blog.sh list
- Generate HTML/PDF : ./blog.sh build
- View site : ./blog.sh view [pdf]"
}

# The purpose of this function is to be
# the main, which call all others function
function main() {
    case "$1" in
    edit)
        if test $# -eq 2; then
            edit "$2"
        else
            list
            echo "Choose a markdown :"
            read -r fileName
            edit "$fileName"
        fi
        ;;
    delete)
        if test $# -eq 2; then
            delete "$2"
        else
            list
            echo "Choose a markdown :"
            read -r fileName
            delete "$fileName"
        fi
        ;;
    list)
        list
        ;;
    build)
        build
        ;;
    view)
        if [ -f markdown/index.md ]; then
            if test $# -eq 2; then
                view "$(echo "$2" | tr '[:upper:]' '[:lower:]')"
            else
                pandoc markdown/index.md -f markdown -t html -s -o web/index.html
                xdg-open web/index.html
            fi
        else
            echo " Build before viewing" 2>&1
        fi
        ;;
    *)
        usage
        ;;
    esac
}

# The purpose of this part is to be the main part
case "$#" in
0)
    echo "[ERROR] 1 action is expected 
Usage : ./blog.sh COMMAND [PARAMETER]
Try './blog.sh usage' to see different usages of the script." 2>&1
    ;;
1)

    main "$(echo "$1" | tr '[:upper:]' '[:lower:]')"
    ;;
2)
    # we don't touch $2 variable because of the name of file
    # it can be uppercase
    main "$(echo "$1" | tr '[:upper:]' '[:lower:]')" "$2"
    ;;
esac
