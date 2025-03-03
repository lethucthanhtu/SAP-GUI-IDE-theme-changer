#!/bin/bash

# ABAP Theme directory
lv_src="$APPDATA/SAP/SAP GUI/ABAP Editor/abap_spec.xml"

# File filter convention
lv_theme_dir="./themes"
lv_file=("$lv_theme_dir"/*_theme.xml)

# Check if there are matching lv_file
if [ ${#lv_file[@]} -eq 0 ]; 
then
    echo "No theme XML file found."
    exit 1
fi

# Display lv_file with a numeric index
echo "================"
echo "Available Themes:"

for i in "${!lv_file[@]}"; 
do
    # Extract just the filename and remove "_theme.xml"
    theme_name=$(basename "${lv_file[i]}" | sed 's/_theme.xml//g' | tr '_' ' ')
    
    echo "$((i+1)). $theme_name theme"
done

echo "----------------"
echo "0. Exit program"
echo "================"

# Input validation loop
lv_loop=true
while $lv_loop;
do
    read -p "Enter the number of the theme you want to select: " lv_choice

    # Validate input
    if [[ $((lv_choice)) != $lv_choice ]] || [ "$lv_choice" -gt "${#lv_file[@]}" ] || [ "$lv_choice" -lt 0 ];
    then
	echo "Not a valid number"
    else
        lv_loop=false
    fi
done

case $lv_choice in
    0)
        exit 1
        ;;
    *)
        lv_selected="${lv_file[$((lv_choice-1))]}"
        echo $lv_selected 
        ;;
esac

# TODO
# Save previous theme
# cp "$lv_src" "$lv_theme_dir/previous_theme.xml"

# Override theme
cp "$lv_selected" "$lv_src"

# Check if `cp` succeeded
if [ $? -ne 0 ]; 
then
    echo "Error: Change theme failed!"
else
    echo "Change theme to $lv_selected successfully!"
    echo "Please restart SAP GUI for change to take effect."
fi

# Wait for user to exit
read -p "Press any key to exit."