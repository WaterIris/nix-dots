# Check if network manager applet is running
if pgrep ".nm-connection" > /dev/null
then
    # If running, kill it
    pkill ".nm-connection"
else
    # If not running, start it
    nm-connection-editor &
fi
