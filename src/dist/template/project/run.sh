#!/bin/bash

declare -r script_dir=`cd "$( dirname "$0" )" && pwd`
cd $script_dir

source params.sh

declare emulatorDataDir=emulator-data

declare runningDays=0
declare runningHours=1
declare processesCount=5
declare hostnamePrefix="hostname-"
declare serversCount=5
declare appsCount=2
declare deploymentsCount=1
declare dryRun="false"
declare processHeapSize=10m
declare intervalMillis=60000
declare extraJVMArgs=""
declare sleepSeconds=0
declare appType="Undefined"
declare framesCount=10

function parse_command_line()
{
	params_add "processes-count" "pc" "$processesCount" "processesCount" "expect_value" \
			"Number of processes to run"
			
	params_add "process-heap-size" "hs" "$processHeapSize" "processHeapSize" "expect_value" \
			"The heap size of every Java process (both min and max)"

	params_add "interval-millis" "im" "$intervalMillis" "intervalMillis" "expect_value" \
			"Interval between events (millis)"

	params_add "servers-count" "sc" "$serversCount" "serversCount" "expect_value" \
			"Number of servers"

	params_add "apps-count" "ac" "$appsCount" "appsCount" "expect_value" \
			"Number of apps"

	params_add "deployments-count" "dc" "$deploymentsCount" "deploymentsCount" "expect_value" \
			"Number of deployments"

	params_add "hostname-prefix" "host" "$hostnamePrefix" "hostnamePrefix" "expect_value" \
			"A prefix to append to all server names"

	params_add "running-days" "days" "$runningDays" "runningDays" "expect_value" \
			"The number of days this app should be running"

	params_add "running-hour" "hours" "$runningHours" "runningHours" "expect_value" \
			"The number of hours this app should be running"

	params_add "jvm-args" "jvm" "$extraJVMArgs" "extraJVMArgs" "expect_value" \
			"JVM arguments to be passed to the application"

	params_add "dry" "d" "$dryRun" "dryRun" "boolean" \
			"Print commands to console, instead of actually running the apps"

	params_add "sleep-seconds" "ss" "$sleepSeconds" "sleepSeconds" "expect_value" \
			"Seconds to wait before starting a new app"

	if ! params_parse_command_line $@; then
		params_usage "Bullshifier run usage:"
		exit 0
	fi
}

function load_config()
{
	if [ -r "APP_TYPE" ]; then
		appType=$(cat APP_TYPE)
	fi
	
	if [ -r "FRAMES_COUNT" ]; then
		framesCount=$(cat FRAMES_COUNT)
	fi
}

function get_deployment_name()
{
	local appName=$1
	local appDataDir=$2
	local deploymentSeed="0"
	
	if [ -r "$appDataDir/DEPLOYMENT_SEED" ]; then
		deploymentSeed=$(cat $appDataDir/DEPLOYMENT_SEED)
	fi
	
	echo "`hostname`-$appName-$deploymentSeed"
}

function run_bullshifiers()
{
	parse_command_line $@
	load_config
	
	local millisInHour=3600000
	
	if [ "$intervalMillis" -gt "$millisInHour" ]; then
		echo "Interval millis max reached: $$intervalMillis (max: $millisInHour)"
		return 1
	fi
	
	let exceptionCount="$millisInHour/$intervalMillis"
	let runningCount="($runningDays*24)+($runningHours%24)"
	
	for ((i=1;i<=$processesCount;i++)); do
		local serverIndex=$(($i%$serversCount))
		local serverName="${hostnamePrefix}$serverIndex"
		
		local appIndex=$(($i%$appsCount))
		local appName="$appType-$appIndex"
		
		local appDataDir="$emulatorDataDir/$appName"
		mkdir -p "$appDataDir"
		
		local deploymentIndex=$(($i%$deploymentsCount))
		local deploymentName=$(get_deployment_name $appName $appDataDir)
		
		echo "serverName=$serverName"
		echo "appName=$appName"
		echo "deploymentName=$deploymentName"
		echo "serverName=$intervalMillis"
		echo "runningCount=$runningCount"
		echo "exceptionCount=$exceptionCount"
		echo "intervalMillis=$intervalMillis"
		echo "processHeapSize=$processHeapSize"
		echo "extraJVMArgs=$extraJVMArgs"
		
		local nameParams="-Dtakipi.server.name=$serverName -Dtakipi.name=$appName -Dtakipi.deployment.name=$deploymentName"
		local javaHeapSize="-Xmx$processHeapSize -Xms$processHeapSize"
		local jarName="$script_dir/build/libs/${appType}.jar"
		local appPlan="-rc $runningCount -ec $exceptionCount -im $intervalMillis"
		local appConfig="-st -hs -wm 0 -sp -fc $framesCount"
		local command="$JAVA_HOME/bin/java $nameParams $javaHeapSize -jar $jarName $appPlan $appConfig -aa $appDataDir"
		
		if [ "$dryRun" == "false" ]; then
			# nohup $command &
			sleep $sleepSeconds
		else
			echo "nohup $command &"
			echo "sleep $sleepSeconds"
		fi
	done
}

run_bullshifiers $@

# 	deploymentName="deployment-$deploymentName"
	

	
# 	echo "Running agent number $i"
# 	date
# 	echo java -Dtakipi.server.name="$serverName" -Dtakipi.name="$appName" -Dtakipi.deployment.name="$deploymentName" 			-Xmx10m -Xms10m -cp $script_dir/build/libs/black.jar helpers.Main 			-ec 1440 -im $interval_between_exceptions -rc 36500000 -wm 0 -st -hs -sp -fc 50..51 -aa "$deploymentName"
# 	echo ""
	
# 	nohup java -Dtakipi.server.name="$serverName" -Dtakipi.name="$appName" -Dtakipi.deployment.name="$deploymentName" 		 -Xmx10m -Xms10m -cp $script_dir/build/libs/black.jar helpers.Main 		-ec 1440 -im $interval_between_exceptions -rc 36500000 -wm 0 -st -hs -sp -fc 50..51 -aa "$deploymentName" &
			
# 	sleep $interval_millis
# done
