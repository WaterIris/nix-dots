# Check if blueman is running
if pgrep "blueman" > /dev/null
then
    # If running, kill it
    pkill "blueman"
else
    # If not running, start it
    blueman-manager &
fi
