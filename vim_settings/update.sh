# Update my_plugins and built-in plugins
printf "Updating built-in plugins...\n"
python update_plugins.py
printf "\nUpdating my_plugins...\n"
for i in my_plugins/*;do echo ${i:11}; cd $i;git pull;cd ../../;done
