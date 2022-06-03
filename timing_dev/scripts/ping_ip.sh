# Check that you can ping the IP address.
# $1 IP Address

if ping -c 1 $1 &> /dev/null
then
    echo "Cannot ping $1. Connect the FPGA[0] ethernet on the rear of the carrier to Port 7 on the switch on the front."
    echo "Exiting."
    exit 1
else
  echo "Pinged IP $1."
fi
