#!/bin/bash
##
## Description: Configures RestComm
## Author: Henrique Rosa (henrique.rosa@telestax.com)
## Author: Pavel Slegr (pavel.slegr@telestax.com)
##

# VARIABLES
RESTCOMM_BIN=$RESTCOMM_HOME/bin
RESTCOMM_DARS=$RESTCOMM_HOME/standalone/configuration/dars
RESTCOMM_DEPLOY=$RESTCOMM_HOME/standalone/deployments/restcomm.war

## FUNCTIONS

## Description: Configures Java Options for Application Server
## Parameters : none
configJavaOpts() {
	FILE=$RESTCOMM_BIN/standalone.conf
	
	# Find total available memory on the instance
    TOTAL_MEM=$(free -m -t | grep 'Total:' | awk '{print $2}')
    # get 70 percent of available memory
    # need to use division by 1 for scale to be read
    CHUNK_MEM=$(echo "scale=0; ($TOTAL_MEM * 0.7)/1" | bc -l)
    # divide chunk memory into units of 64mb
    MULTIPLIER=$(echo "scale=0; $CHUNK_MEM/64" | bc -l)
    # use multiples of 64mb to know effective memory
    FINAL_MEM=$(echo "$MULTIPLIER * 64" | bc -l)
    MEM_UNIT='m'

    RESTCOMM_OPTS="-Xms$FINAL_MEM$MEM_UNIT -Xmx$FINAL_MEM$MEM_UNIT -XX:MaxPermSize=256m -Dorg.jboss.resolver.warning=true -Dsun.rmi.dgc.client.gcInterval=3600000 -Dsun.rmi.dgc.server.gcInterval=3600000"

	sed -e "/if \[ \"x\$JAVA_OPTS\" = \"x\" \]; then/ {
		N; s|JAVA_OPTS=.*|JAVA_OPTS=\"$RESTCOMM_OPTS\"|
	}" $FILE > $FILE.bak
	mv $FILE.bak $FILE
	echo "Configured JVM for RestComm: $RESTCOMM_OPTS"
}

## Description: Updates RestComm configuration file
## Parameters : 1.Private IP
## 		2.Public IP
configRestcomm() {
	FILE=$RESTCOMM_DEPLOY/WEB-INF/conf/restcomm.xml
	bind_address="$1"
	static_address="$2"
	outbound_proxy="$3"
	recording_address=$bind_address
	if [ -n "$static_address" ]; then
		recording_address=$static_address
	fi

	if [ "$ACTIVE_PROXY" == "true" ]; then
			sed -e "s|<local-address>.*<\/local-address>|<local-address>$bind_address<\/local-address>|" \
			-e "s|<remote-address>.*<\/remote-address>|<remote-address>$bind_address<\/remote-address>|" \
			-e "s|<\!--.*<external-ip>.*<\/external-ip>.*-->|<external-ip>$bind_address<\/external-ip>|" \
			-e "s|<external-ip>.*<\/external-ip>|<external-ip>$bind_address<\/external-ip>|" \
			-e "s|<external-address>.*<\/external-address>|<external-address>$PUBLIC_IP<\/external-address>|" \
			-e "s|<\!--.*<external-address>.*<\/external-address>.*-->|<external-address>$PUBLIC_IP<\/external-address>|" \
			-e "s|<prompts-uri>.*<\/prompts-uri>|<prompts-uri>http:\/\/$bind_address:8080\/restcomm\/audio<\/prompts-uri>|" \
			-e "s|<cache-uri>.*<\/cache-uri>|<cache-uri>http:\/\/$bind_address:8080\/restcomm\/cache<\/cache-uri>|" \
			-e "s|<normalize-numbers-for-outbound-calls>.*<\/normalize-numbers-for-outbound-calls>|<normalize-numbers-for-outbound-calls>true<\/normalize-numbers-for-outbound-calls>|" \
			-e "s|<recordings-uri>.*<\/recordings-uri>|<recordings-uri>http:\/\/$recording_address:8080\/restcomm\/recordings<\/recordings-uri>|" \
			-e "s|<error-dictionary-uri>.*<\/error-dictionary-uri>|<error-dictionary-uri>http:\/\/$bind_address:8080\/restcomm\/errors<\/error-dictionary-uri>|" \
			-e "s|<outbound-proxy-uri>.*<\/outbound-proxy-uri>|<outbound-proxy-uri>$outbound_proxy<\/outbound-proxy-uri>|"  $FILE > $FILE.bak;
	
	else 
		if [ -n "$static_address" ]; then 
			sed -e "s|<local-address>.*<\/local-address>|<local-address>$bind_address<\/local-address>|" \
			-e "s|<remote-address>.*<\/remote-address>|<remote-address>$bind_address<\/remote-address>|" \
			-e "s|<\!--.*<external-ip>.*<\/external-ip>.*-->|<external-ip>$static_address<\/external-ip>|" \
			-e "s|<external-ip>.*<\/external-ip>|<external-ip>$static_address<\/external-ip>|" \
			-e "s|<external-address>.*<\/external-address>|<external-address>$static_address<\/external-address>|" \
			-e "s|<\!--.*<external-address>.*<\/external-address>.*-->|<external-address>$static_address<\/external-address>|" \
			-e "s|<prompts-uri>.*<\/prompts-uri>|<prompts-uri>http:\/\/$static_address:8080\/restcomm\/audio<\/prompts-uri>|" \
			-e "s|<cache-uri>.*<\/cache-uri>|<cache-uri>http:\/\/$static_address:8080\/restcomm\/cache<\/cache-uri>|" \
			-e "s|<recordings-uri>.*<\/recordings-uri>|<recordings-uri>http:\/\/$recording_address:8080\/restcomm\/recordings<\/recordings-uri>|" \
			-e "s|<error-dictionary-uri>.*<\/error-dictionary-uri>|<error-dictionary-uri>http:\/\/$static_address:8080\/restcomm\/errors<\/error-dictionary-uri>|" \
			-e "s|<outbound-proxy-uri>.*<\/outbound-proxy-uri>|<outbound-proxy-uri>$outbound_proxy<\/outbound-proxy-uri>|"  $FILE > $FILE.bak;
		else
			sed -e "s|<local-address>.*<\/local-address>|<local-address>$bind_address<\/local-address>|" \
			-e "s|<remote-address>.*<\/remote-address>|<remote-address>$bind_address<\/remote-address>|" \
			-e 's|<external-ip>.*</external-ip>|<external-ip></external-ip>|' \
			-e 's|<external-address>.*</external-address>|<external-address></external-address>|' \
			-e "s|<prompts-uri>.*<\/prompts-uri>|<prompts-uri>http:\/\/$bind_address:8080\/restcomm\/audio<\/prompts-uri>|" \
			-e "s|<cache-uri>.*<\/cache-uri>|<cache-uri>http:\/\/$bind_address:8080\/restcomm\/cache<\/cache-uri>|" \
			-e "s|<recordings-uri>.*<\/recordings-uri>|<recordings-uri>http:\/\/$recording_address:8080\/restcomm\/recordings<\/recordings-uri>|" \
			-e "s|<error-dictionary-uri>.*<\/error-dictionary-uri>|<error-dictionary-uri>http:\/\/$bind_address:8080\/restcomm\/errors<\/error-dictionary-uri>|" \
			-e "s|<outbound-proxy-uri>.*<\/outbound-proxy-uri>|<outbound-proxy-uri>$outbound_proxy<\/outbound-proxy-uri>|"  $FILE > $FILE.bak;
		fi
	fi
	mv $FILE.bak $FILE
	echo 'Updated RestComm configuration'
}

## Description: Configures Voip Innovations Credentials
## Parameters : 1.Login
## 				2.Password
## 				3.Endpoint
configVoipInnovations() {
	FILE=$RESTCOMM_DEPLOY/WEB-INF/conf/restcomm.xml
	
	sed -e "/<voip-innovations>/ {
		N; s|<login>.*</login>|<login>$1</login>|
        N; s|<password>.*</password>|<password>$2</password>|
        N; s|<endpoint>.*</endpoint>|<endpoint>$3</endpoint>|
	}" $FILE > $FILE.bak
	
	mv $FILE.bak $FILE
	echo 'Configured Voip Innovation credentials'
}

## Description: Configures Fax Service Credentials
## Parameters : 1.Username
## 				2.Password
configFaxService() {
	FILE=$RESTCOMM_DEPLOY/WEB-INF/conf/restcomm.xml
	
	sed -e "/<fax-service.*>/ {
		N; s|<user>.*</user>|<user>$1</user>|
		N; s|<password>.*</password>|<password>$2</password>|
	}" $FILE > $FILE.bak
	
	mv $FILE.bak $FILE
	echo 'Configured Fax Service credentials'
}

## Description: Configures Sms Aggregator
## Parameters : 1.Outbound endpoint IP
## 
configSmsAggregator() {
	FILE=$RESTCOMM_DEPLOY/WEB-INF/conf/restcomm.xml
	
	sed -e "/<sms-aggregator.*>/ {
		N; s|<outbound-prefix>.*</outbound-prefix>|<outbound-prefix>#</outbound-prefix>|
		N; s|<outbound-endpoint>.*</outbound-endpoint>|<outbound-endpoint>$1:5060</outbound-endpoint>|
	}" $FILE > $FILE.bak
	
	mv $FILE.bak $FILE
	echo "Configured Sms Aggregator using OUTBOUND PROXY $1"
}

## Description: Configures Speech Recognizer
## Parameters : 1.iSpeech Key
configSpeechRecognizer() {
	FILE=$RESTCOMM_DEPLOY/WEB-INF/conf/restcomm.xml
	
	sed -e "/<speech-recognizer.*>/ {
		N; s|<api-key.*></api-key>|<api-key production=\"true\">$1</api-key>|
	}" $FILE > $FILE.bak
	
	mv $FILE.bak $FILE
	echo 'Configured the Speech Recognizer'
}

## Description: Configures available speech synthesizers
## Parameters : none
configSpeechSynthesizers() {
	configAcapela $ACAPELA_APPLICATION $ACAPELA_LOGIN $ACAPELA_PASSWORD
	configVoiceRSS $VOICERSS_KEY
}

## Description: Configures Acapela Speech Synthesizer
## Parameters : 1.Application Code
## 				2.Login
## 				3.Password
configAcapela() {
	FILE=$RESTCOMM_DEPLOY/WEB-INF/conf/restcomm.xml
	
	sed -e "/<speech-synthesizer class=\"org.mobicents.servlet.restcomm.tts.AcapelaSpeechSynthesizer\">/ {
		N
		N; s|<application>.*</application>|<application>$1</application>|
		N; s|<login>.*</login>|<login>$2</login>|
		N; s|<password>.*</password>|<password>$3</password>|
	}" $FILE > $FILE.bak
	
	mv $FILE.bak $FILE
	echo 'Configured Acapela Speech Synthesizer'
}

## Description: Configures VoiceRSS Speech Synthesizer
## Parameters : 1.API key
configVoiceRSS() {
	FILE=$RESTCOMM_DEPLOY/WEB-INF/conf/restcomm.xml
	
	sed -e "/<service-root>http:\/\/api.voicerss.org<\/service-root>/ {
		N; s|<apikey>.*</apikey>|<apikey>$1</apikey>|
	}" $FILE > $FILE.bak
	
	mv $FILE.bak $FILE
	echo 'Configured VoiceRSS Speech Synthesizer'
}

## Description: Updates Mobicents properties for RestComm
## Parameters : none
configMobicentsProperties() {
	FILE=$RESTCOMM_DARS/mobicents-dar.properties
	sed -e 's|^ALL=.*|ALL=("RestComm", "DAR\:From", "NEUTRAL", "", "NO_ROUTE", "0")|' $FILE > $FILE.bak
	mv $FILE.bak $FILE
	echo "Updated mobicents-dar properties"
}

## Description: Configures TeteStax Proxy
## Parameters : 1.Enabled
##              2.login
##              3.password
## 		4.Endpoint
## 		5.Proxy IP
configTelestaxProxy() {
	FILE=$RESTCOMM_DEPLOY/WEB-INF/conf/restcomm.xml
	enabled="$1"
	if [ "$enabled" == "true" ]; then
		sed -e "/<telestax-proxy>/ {
			N; s|<enabled>.*</enabled>|<enabled>$1</enabled>|
		N; s|<login>.*</login>|<login>$2</login>|
		N; s|<password>.*</password>|<password>$3</password>|
		N; s|<endpoint>.*</endpoint>|<endpoint>$4</endpoint>|
		N; s|<uri>.*</uri>|<uri>http:\/\/$5:2080</uri>|
		}" $FILE > $FILE.bak
	
		mv $FILE.bak $FILE
		echo 'Configured TeteStax Proxy'
	fi
}


## Description: Configures Media Server Manager
## Parameters : 1.Enabled
## 		2.private IP
## 		3.public IP

configMediaServerManager() {
	FILE=$RESTCOMM_DEPLOY/WEB-INF/conf/restcomm.xml
	enabled="$1"
	bind_address="$2"
	public_ip="$3"
	
	if [ "$enabled" == "true" ]; then
		sed -e "/<mgcp-server class=\"org.mobicents.servlet.restcomm.mgcp.MediaGateway\">/ {
			N
			N; s|<local-address>.*</local-address>|<local-address>$bind_address</local-address>|
			N; s|<local-port>.*</local-port>|<local-port>2727</local-port>|
			N; s|<remote-address>127.0.0.1</remote-address>|<remote-address>$bind_address</remote-address>|
			N; s|<remote-port>.*</remote-port>|<remote-port>2427</remote-port>|
			N; s|<response-timeout>.*</response-timeout>|<response-timeout>500</response-timeout>|
			N; s|<\!--.*<external-address>.*</external-address>.*-->|<external-address>$public_ip</external-address>|
		}" $FILE > $FILE.bak
	
		mv $FILE.bak $FILE
		echo 'Configured Media Server Manager'
	fi
}

# MAIN
echo 'Configuring RestComm...'
#configJavaOpts
configMobicentsProperties
configRestcomm "$BIND_ADDRESS" "$STATIC_ADDRESS" "$OUTBOUND_PROXY"
configVoipInnovations "$VI_LOGIN" "$VI_PASSWORD" "$VI_ENDPOINT"
configFaxService "$INTERFAX_USER" "$INTERFAX_PASSWORD"
configSmsAggregator "$OUTBOUND_PROXY"
configSpeechRecognizer "$ISPEECH_KEY"
configSpeechSynthesizers
configTelestaxProxy "$ACTIVE_PROXY" "$TP_LOGIN" "$TP_PASSWORD" "$INSTANCE_ID" "$PROXY_IP"
configMediaServerManager "$ACTIVE_PROXY" "$BIND_ADDRESS" "$PUBLIC_IP"
echo 'Configured RestComm!'
