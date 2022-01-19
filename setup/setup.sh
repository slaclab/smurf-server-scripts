# Setup this server to run SMuRF software. Should be able to to set up
# brand new OS installations, and update older servers that have been
# set up before.

function get_server_type {
    if dmidecode | grep -Fq R440
    then
	echo "This is as Dell R440 server"
	dell_r440=1
    elif dmidecode | grep -Fq R330
    then
	echo "This is a Dell R330 server"
	dell_r330=1
    else
	exit 1
    fi

}
