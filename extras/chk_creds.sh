
echo -e "\nChecking env for GOVC variables...\n"
if [ -z $GOVC_USERNAME ]; then read -p "GOVC_USERNAME: " GOVC_USERNAME; export GOVC_USERNAME; fi
if [ -z $GOVC_PASSWORD ]; then read -sp "GOVC_PASSWORD: " GOVC_PASSWORD; export GOVC_PASSWORD; fi
if [ -z $GOVC_URL ]; then read -p "GOVC_URL: " GOVC_URL; export GOVC_URL; fi
if [ -z $GOVC_INSECURE ]; then read -p "GOVC_INSECURE: " GOVC_INSECURE; export GOVC_INSECURE; fi
