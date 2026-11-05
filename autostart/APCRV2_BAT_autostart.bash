#!/bin/bash

# Define the original script path
APCRV2_BAT_bash_script="$HOME/APCRV2_BAT_TEST_ZIG/APCRV2_BAT_Test_Bench.bash"


dos2unix $HOME/*TEST_ZIG*/*.bash 2>/dev/null || true
dos2unix $HOME/*Test_Zig*/*.bash 2>/dev/null || true
dos2unix $HOME/*.bash 2>/dev/null || true

# Define the website or server to ping
target="google.com"

echo "Checking internet connection..."
# Define an array of GPIO pins
pins=(7 25 8)
# Loop through the pins and configure each one
for pin in "${pins[@]}"; do
    # Check if the pin is already exported
    if [ ! -e "/sys/class/gpio/gpio$pin" ]; then
        echo "$pin" | sudo tee /sys/class/gpio/export >/dev/null 2>&1
    fi
    sync
    # Set the direction and turn the pin on
    echo "out" | sudo tee /sys/class/gpio/gpio$pin/direction >/dev/null 2>&1 && sync
    echo "1" | sudo tee /sys/class/gpio/gpio$pin/value >/dev/null 2>&1 && sync
done

while ! ping -c 1 -W 2 "$target" &> /dev/null; do
  echo "Internet connection is down. Retrying..."
    # Turn all the pins off
    for pin in "${pins[@]}"; do
        echo "0" | sudo tee /sys/class/gpio/gpio$pin/value >/dev/null 2>&1
    done
    sync
    sleep 0.2
    # Turn all the pins on
    for pin in "${pins[@]}"; do
        echo "1" | sudo tee /sys/class/gpio/gpio$pin/value >/dev/null 2>&1
    done
    sync
    sleep 0.2
done
# for pin in "${pins[@]}"; do
#     echo "0" | sudo tee /sys/class/gpio/gpio$pin/value >/dev/null 2>&1
# done
echo "Internet connection is now working."

for file in ./*_autostart.bash; do
    # Skip APCRV2_BAT_autostart.bash
    if [ "$(basename "$file")" != "APCRV2_BAT_autostart.bash" ]; then
        echo "deleting $file"
        rm $file
        # Put your commands here
    fi
done
for file in ./*TEST_ZIG*; do
    # Skip APCRV2_BAT_autostart.bash
    if [ "$(basename "$file")" != "APCRV2_BAT_TEST_ZIG" ]; then
        echo "deleting $file"
        rm -rf $file
        # Put your commands here
    fi
done
for file in ./.config/autostart/*; do
    # Skip APCRV2_BAT_autostart.bash
    if [ "$(basename "$file")" != "APCRV2_BAT_Test_Bench_Run.desktop" ]; then
        echo "deleting $file"
        rm -f $file 2>/dev/null || true
        # Put your commands here
    fi
done
# Check if the original script file exists and has a non-zero size
if [ -f "$HOME/.ssh/APCRV2_BAT_SSH_KEY" ]; then
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/APCRV2_BAT_SSH_KEY
if [ -s "$APCRV2_BAT_bash_script" ]; then
    # Run the original script
    echo "Running the original script..."
    cd $HOME/APCRV2_BAT_TEST_ZIG
    # git fetch origin
    # # git reset --hard origin/master
    # git reset --hard origin/New_Features
    # Shallow update: this repo carries a lot of historical firmware zips
    # and the jig only needs the current snapshot, so fetch just that.
    BR=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
    if [ -z "$BR" ] || [ "$BR" = "HEAD" ]; then BR=main; fi
    git fetch --depth=1 origin "$BR" && git reset --hard FETCH_HEAD
    sync
    chmod +x "$HOME/APCRV2_BAT_TEST_ZIG/APCRV2_BAT_Test_Bench.bash"
    chmod +x "$HOME/APCRV2_BAT_TEST_ZIG/APCRV2_BAT_autostart.bash"
    chmod +x "$HOME/APCRV2_BAT_TEST_ZIG/downloadPRDApp.bash"
    chmod +x "$HOME/APCRV2_BAT_TEST_ZIG/arm/bin/adownload"

    # lxterminal -e "bash $APCRV2_BAT_bash_script"
    $APCRV2_BAT_bash_script
else
    ssh -T git@github.com
    cd $HOME
    rm -rf ~/APCRV2_BAT_TEST_ZIG
    git clone --depth 1 git@github.com:Jaydeep2990/APCRV2_BAT_TEST_ZIG.git
    sync
    chmod +x "$HOME/APCRV2_BAT_TEST_ZIG/APCRV2_BAT_Test_Bench.bash"
    chmod +x "$HOME/APCRV2_BAT_TEST_ZIG/APCRV2_BAT_autostart.bash"
    chmod +x "$HOME/APCRV2_BAT_TEST_ZIG/downloadPRDApp.bash"
    chmod +x "$HOME/APCRV2_BAT_TEST_ZIG/arm/bin/adownload"

    echo "Running the original script..."
    #lxterminal -e "bash $APCRV2_BAT_bash_script"
    $APCRV2_BAT_bash_script
fi
else 
read -p "SSH_KEY not Found!!!!!"
fi