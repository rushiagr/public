r@rushi:~/src/nova/nova$ iwgetid |  cut -d'"' -f 2
Rushi
r@rushi:~/src/nova/nova$ ifconfig | grep "^[a-zA-Z]\|bytes" | grep wlan0 -A 2 | tail -1 | cut -d':' -f2 | aw 1
12342342

Rx bytes in python
int(subprocess.check_output("ifconfig | grep '^[a-zA-Z]\|bytes' | grep wlan0 -A 2 | tail -1 | cut -d':' -f2 | awk '{print $1}'", shell=True).strip())
