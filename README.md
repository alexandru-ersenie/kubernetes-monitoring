# kubernets-monitoring
Monitoring Kubernetes items using Kubernetes API, Curl and JQ

## Check Pods by Label

### Description
Shell check script for kubernetes cluster  pods   based on labels.
Given a namespace and a deployment label, this script will return all pods in "ready"  state (ready as readiness probe ok)
It will get all pods from a namespace, filter the ones matching the label and retrieve only the ready ones my checking two conditions: type:Ready and status:True

### Usage

```
Usage:
  ./curl.sh [-t <TARGETSERVER> -a <AUTH_FILE>] [-n <NAMESPACE>] [-s <STAB_THRESHOLD>] [-w <WARN_THRESHOLD>] [-c <CRIT_THRESHOLD]

Options:
  -t <TARGETSERVER>     # The endpoint for your Kubernetes API
  -a <AUTH_FILE>        # Required if a <TARGETSERVER> API is specified
  -n <NAMESPACE>        # Namespace to check, for example, "area09"
  -s <STAB_THRESHOLD>   # Stable threshold for number of pods running
  -w <WARN_THRESHOLD>   # Warning threshold for number of pods running
  -c <CRIT_THRESHOLD>	# Critical threshold for number of pods running
  -l <POD_LABEL>		# Search for pods of a specific label
  -h			        # Show usage / help
  -v			        # Show verbose output
  ```
  ### Example
  
  Check all pods inside namespace **TESTNS** with the label **jms**
  Perform the check on target **kubeapi** and use the locally store token **nagios.token**
  - If number of pods found is 0 (-c 0) return CRITICAL
  - If number of pods found is 1 (-w 1) return WARNING
  - If number of pods found >  2 (-s 2) return OK
  
  
  ```
  sh curl.sh -a nagios.token -t kubeapi -n TESTNS -l jms -s 2 -w 1 -c 0
  ```
  
  This will return one of the following types of messages:
  ```
  Return Message: Ok 	 Pod type: jms	 Expected: 2 	 Got: 3 	 Exit Code: 0
  Return Message: Warning 	 Pod type: jms	 Expected: 2 	 Got: 1 	 Exit Code: 1
  Return Message: Critical 	 Pod type: jms	 Expected: 2 	 Got: 0 	 Exit Code: 2
  ```
