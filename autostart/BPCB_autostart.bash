#!/bin/bash

# Define the original script path
BPCB_bash_script="$HOME/BPCB_TEST_ZIG/BPCB_Test_Bench.bash"

dos2unix $HOME/*TEST_ZIG*/*.bash
dos2unix $HOME/*Test_Zig*/*.bash
dos2unix $HOME/*.bash

chmod +x $HOME/*TEST_ZIG*/*.bash
chmod +x $HOME/*Test_Zig*/*.bash
chmod +x $HOME/*.bash

# Define the website or server to ping
target="google.com"

echo "Checking internet connection..."
# Define an array of GPIO pins
pins=(7 25 8)
# Loop through the pins and configure each one
for pin in "${pins[@]}"; do
    # Check if the pin is already exported
    if [ ! -e "/sys/class/gpio/gpio$pin" ]; then
        sudo echo "$pin" > /sys/class/gpio/export
    fi
    sync
    # Set the direction and turn the pin on
    sudo echo "out" > /sys/class/gpio/gpio$pin/direction && sync
    sudo echo "1" > /sys/class/gpio/gpio$pin/value && sync
done

while ! ping -c 1 -W 2 "$target" &> /dev/null; do
  echo "Internet connection is down. Retrying..."
    # Turn all the pins off
    for pin in "${pins[@]}"; do
        sudo echo "0" > /sys/class/gpio/gpio$pin/value
    done
    sync
    sleep 0.2
    # Turn all the pins on
    for pin in "${pins[@]}"; do
        sudo echo "1" > /sys/class/gpio/gpio$pin/value
    done
    sync
    sleep 0.2
done
# for pin in "${pins[@]}"; do
#     sudo echo "0" > /sys/class/gpio/gpio$pin/value
# done
echo "Internet connection is now working."

# Check if the original script file exists and has a non-zero size
# Load the deploy key into an agent BEFORE any git call. Without an
# agent, ssh-add fails with "Could not open a connection to your
# authentication agent", no key is ever offered, and the clone dies
# with "Permission denied (publickey)".
if [ -f "$HOME/.ssh/BPCB_SSH_KEY" ]; then
    # Name the key to git directly. This is what APB and ART1605FT do and
    # it is the part that does not depend on an agent existing - which it
    # does not when the script is run over a deployment SSH session.
    export GIT_SSH_COMMAND="ssh -i $HOME/.ssh/BPCB_SSH_KEY -o StrictHostKeyChecking=no -o BatchMode=yes"
    # The agent is still started so the plain `ssh -T git@github.com`
    # reachability check below has a key to offer.
    eval "$(ssh-agent -s)" >/dev/null 2>&1
    ssh-add ~/.ssh/BPCB_SSH_KEY >/dev/null 2>&1
fi
if [ -s "$BPCB_bash_script" ]; then
    # Run the original script
    echo "Running the original script..."
    cd $HOME/BPCB_TEST_ZIG
    # git fetch origin
    # # git reset --hard origin/master
    # git reset --hard origin/New_Features
    # Shallow update: this repo carries a lot of historical firmware zips
    # and the jig only needs the current snapshot, so fetch just that.
    BR=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
    if [ -z "$BR" ] || [ "$BR" = "HEAD" ]; then BR=main; fi
    git fetch --depth=1 origin "$BR" && git reset --hard FETCH_HEAD
    sync
    chmod +x ~/BPCB_TEST_ZIG/BPCB_Test_Bench.bash
    chmod +x ~/BPCB_TEST_ZIG/BPCB_autostart.bash
    # lxterminal -e "bash $BPCB_bash_script"
    $BPCB_bash_script
else
    ssh-add ~/.ssh/BPCB_SSH_KEY
    ssh -T git@github.com
    cd $HOME
    rm -rf ~/BPCB_TEST_ZIG
    git clone --depth 1 git@github.com:Jaydeep2990/BPCB_TEST_ZIG.git
    sync
    chmod +x ~/BPCB_TEST_ZIG/BPCB_Test_Bench.bash
    chmod +x ~/BPCB_TEST_ZIG/BPCB_autostart.bash
    echo "Running the original script..."
    #lxterminal -e "bash $BPCB_bash_script"
    $BPCB_bash_script
fi
