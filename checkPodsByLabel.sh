#!/usr/bin/env bash

#########################################################
#       ./checkPodsByLabel.sh				#
#                                                       #
#   Shell check script for kubernetes cluster  pods     #
#   based on labels. Given a namespace and a deployment #
#   label, this script will return all pods in "ready"  #
#   state (ready as readiness probe ok)			#
#   Author:  Alexandru Ersenie                          #
#                                                       #
#########################################################

type jq >/dev/null 2>&1 || { echo >&2 "CRITICAL: The jq utility is required for this script to run."; exit 2; }

function usage {
cat <<EOF
Usage:
  ./curl.sh [-t <TARGETSERVER> -a <AUTH_FILE>] [-n <NAMESPACE>] [-s <STAB_THRESHOLD>] [-w <WARN_THRESHOLD>] [-c <CRIT_THRESHOLD]

Options:
  -t <TARGETSERVER>	    # The endpoint for your Kubernetes API
  -a <AUTH_FILE>	    # Required if a <TARGETSERVER> API is specified
  -n <NAMESPACE>	    # Namespace to check, for example, "area09"
  -s <STAB_THRESHOLD>   # Stable threshold for number of pods running
  -w <WARN_THRESHOLD>	# Warning threshold for number of pods running
  -c <CRIT_THRESHOLD>	# Critical threshold for number of pods running
  -l <POD_LABEL>		# Search for pods of a specific label
  -h			# Show usage / help
  -v			# Show verbose output
EOF
exit 2
}

# Get arguments from command line, such as master url, auth file, thresholds, namespace, pod label
function init()
{
	while getopts ":t:a:w:c:n:l:s:h" OPTIONS; do
        case "${OPTIONS}" in
                t) TARGET=${OPTARG} ;;
                a) AUTHENTICATION_FILE="${OPTARG}" ;;
                w) WARN_THRESHOLD=${OPTARG} ;;
                c) CRIT_THRESHOLD=${OPTARG} ;;
                n) PODS_NS=${OPTARG} ;;
                l) PODS_LABEL="${OPTARG}" ;;
                s) STAB_THRESHOLD=${OPTARG} ;;
                h) usage ;;
                *) usage ;;
        esac
	done
}

# Prints out the type of notification and the exit code
function returnResult ()
{
	message="Pod type: $PODS_LABEL\t Expected: $STAB_THRESHOLD \t Got: $count"
	printf "Return Message: $1 \t $message \t Exit Code: $2\n"
	exit $2
}

# Checks the retrieved number of objects against the set thresholds
function checkThresholds()
{
	if [ $count -gt $CRIT_THRESHOLD ] && [ $count -lt $STAB_THRESHOLD ]; then
            returnResult Warning 1
	elif [ $count -lt $WARN_THRESHOLD ]; then
	    returnResult Critical 2
        elif [ $count -ge $STAB_THRESHOLD ]; then
	   returnResult Ok 0
	fi
}

# Authenticate by setting the header from the given token file
function authenticate()
{
	export HEADER=`cat $AUTHENTICATION_FILE`
}

# Check kubernetes api health or exit
function preflight()
{
	# Perform a request on the healthz entrypoint to check if cluster api is reachable
	curl   -s -k -o /dev/null  --header "Authorization: Bearer $HEADER" https://$TARGET:6443/healthz
	result=$?

	# If cluster is not available exit program
	if [ $result != 0 ]; then
		echo "Preflight check failed; KubeAPI cannot be accessed; curl returned code $result"
		exit $result
	fi
}

# Main function doing the logic
function main ()
{
	# If no arguments provided, print out usage help
	if [ $# -le 0 ] ; then
	 usage fi
	 exit 0
	fi

	# Get arguments from command line
	init $@
	
	# Authenticate using the token provided
	authenticate

	# Perform preflight check to see if api is reachable
        preflight

	# Retrieve the number of pods in running mode by selecting all pods with condition type "Ready", and filtering the pods where type Ready is true
	count=`curl -sS "--insecure" --header "Authorization: Bearer $HEADER"  https://$TARGET:6443/api/v1/namespaces/$PODS_NS/pods | jq -r   '.items[] | select(.metadata.labels."app.kubernetes.io/name"=="'$PODS_LABEL'") | .status.conditions[] | select(.type=="Ready" and .status=="True") | .status ' | wc -l | awk  '{print $1}'`
	
	# Compare the number of pods retrieved with the defined thresholds
	checkThresholds

}

main $@
