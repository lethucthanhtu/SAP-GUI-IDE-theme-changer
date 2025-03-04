#!/bin/bash

# ABAP Theme directory
SOURCE_DIR="$APPDATA/SAP/SAP GUI/ABAP Editor/abap_spec.xml"

# Theme directory
THEMES_DIR="./themes"

# Files postfix
FILES_POSTFIX="theme.xml"

# File filter convention
FILES=($THEMES_DIR/*$FILES_POSTFIX)

# File length
FILES_LENGTH=${#FILES[@]}

# File offset
FILES_OFFSET=3

# Format theme name
FORMAT_NAME () {
    echo $(basename "$1" | sed "s/$FILES_POSTFIX//g" | tr '_' ' ')
}

# Format file name
FORMAT_FILE () {
    # Get the new filename with spaces replaced by underscores
    local NEW_FILE=$(echo "$1" | tr ' ' '_')

    # Rename the FILE if the new name is different
    if [[ "$1" != "$NEW_FILE" ]];
    then
        mv "$1" "$NEW_FILE"
    fi
}

# Format files
FORMAT_FILES () {
    for FILE in $THEMES_DIR/*;
    do
        FORMAT_FILE "$FILE"
    done
}

CHANGE_THEME () {
    # Overwrite theme
    cp "$1" "$SOURCE_DIR"

    # Check if `cp` succeeded
    if [ $? -ne 0 ];
    then
        echo "Error: Change theme failed!"
    else
        echo "Change theme to "$(FORMAT_NAME "$SELECTED_FILE")" successfully!"
        echo "Please restart SAP GUI for change to take effect."
    fi
}

SAVE_THEME () {
    # Default theme name
    local THEME_NAME

    read -p "Name your theme to save. Leave blank for 'previous_theme.xml': " THEME_NAME

    # -z for checking empty string
    if [ -z "$THEME_NAME" ];
    then
        THEME_NAME="previous"
    fi

    THEME_NAME=$(echo "$THEME_NAME $FILES_POSTFIX" | tr ' ' '_' )

    # Copy current theme to themes directory
    cp "$SOURCE_DIR" "$THEMES_DIR/$THEME_NAME"

    # Check if `cp` succeeded
    if [ $? -ne 0 ];
    then
        echo "Error: Save theme failed!"
    else
        echo "Save theme "$THEME_NAME" successfully!"
    fi
}

# Format files
FORMAT_FILES

# Check if there are matching FILES
if [ $((FILES_LENGTH)) == 0 ];
then
    echo "No theme XML file found."
    exit 1
fi

# Input validation loop
LOOP=true
while $LOOP;
do
    # Display FILES with a numeric index
    echo "======================="
    echo "[0] Exit program"
    echo "[1] Save current theme"
    echo "[2] Format theme names"
    echo "-----------------------"
    echo "Available themes:"

    for i in ${!FILES[@]};
    do
        # Display formatted theme name
        THEME_NAME=$(FORMAT_NAME "${FILES[$i]}")
        echo "["$((i+$FILES_OFFSET))"] $THEME_NAME theme"
    done

    echo "======================="

    read -p "Enter your option: " CHOICE

    # Validate input
    if  [[ $((CHOICE)) != $CHOICE ]] ||
        [ $CHOICE -gt $((FILES_LENGTH + FILES_OFFSET)) ] ||
        [ $CHOICE -lt 0 ];
    then
        clear
        echo "Not a valid input. Please try again."
    else
        LOOP=false
    fi
done

case $CHOICE in
    0)
        exit 1
        ;;
    1)
        SAVE_THEME
        FORMAT_FILES
        ;;
    2)
        FORMAT_FILES
        echo "Format theme names successfully!"
        ;;
    *)
        SELECTED_FILE=${FILES[$((CHOICE-$FILES_OFFSET))]}
        CHANGE_THEME "$SELECTED_FILE"
        ;;
esac

# Wait for user to exit
read -p "Press any key to exit."