#!/bin/bash

BACK_TITLE='Quarkus starter Terminal Edition'

# using the streams api to get the platform versions available
QUARKUS_PLATFORM_METADATA=$(curl -s -H 'Accept: application/json' https://code.quarkus.io/api/streams)
QUARKUS_EXTENSIONS_METADATA=$(curl -s -H 'Accept: application/json' https://code.quarkus.io/api/extensions?platformOnly=true)

BUILD_TOOL='MAVEN'
JAVA_VERSION='11'
# use the first version tagged recommended as the default
QUARKUS_PLATFORM_VERSION=$(echo $QUARKUS_PLATFORM_METADATA | jq -r '.[] | select(.recommended) | .platformVersion')
GROUP_ID='com.example'
ARTIFACT_ID='quarkus-app'
VERSION='1.0-SNAPSHOT'
DESCRIPTION='Quarkus app'
# TODO: use the starter code / no code option for something
# shellcheck disable=SC2034
STARTER_CODE='true'
DEPENDENCIES=""

function artifact_settings () {
	while true
	do
		ACTION=$(dialog --stdout --backtitle "$BACK_TITLE" --no-cancel --inputmenu "Artifact settings" 0 0 10 "Group id:" "$GROUP_ID" "Artifact id:" "$ARTIFACT_ID" "Version:" "$VERSION" "Description:" "$DESCRIPTION")
		
		# not renaming, so OK was selected. gtf back to the menu
        # shellcheck disable=SC2143,SC2046
		if [ -z $(echo $ACTION | grep RENAMED) ]
		then
			break
		fi

        # shellcheck disable=SC2001
		SELECTIONS=$(echo ${ACTION:8} | sed 's/: /:+/g')
		SELECTED_TYPE=$(echo $SELECTIONS | cut -d + -f1)
		SELECTED_VALUE=$(echo $SELECTIONS | cut -d + -f2)
	    case $SELECTED_TYPE in
			"Group id:")
				GROUP_ID=$SELECTED_VALUE
				;;
			"Artifact id:")
				ARTIFACT_ID=$SELECTED_VALUE
				;;
            "Version:")
                VERSION=$SELECTED_VALUE
                ;;
			"Description:")
				DESCRIPTION=$SELECTED_VALUE
		esac
	done
	
}

function _transform_choices_to_dialog_radio_options() {
    # TODO: is recommended-type choices something that can be used multiple times? or is it just a quarkus platform thing? Maybe move it somewhere else if the latter
	CHOICES=$1
	CURRENT_SELECTION=$2
	echo -e "$CHOICES" | sed 'n;s/$/ off/' | sed '{N;s/\n/ /;}' | sed 's/true/Recommended/' | sed 's/false/-/' | sed -E "s/(\"$CURRENT_SELECTION\" .*) off/\1 on/" | tr '\n' ' '
}

function change_build_tool() {
    # TODO: any way we can show just the name and not the key here?
	BUILD_TOOL_SELECTIONS='"MAVEN"\n"Maven"\n"GRADLE"\n"Gradle"\n"GRADLE_KOTLIN_DSL"\n"Gradle with Kotlin DSL"'
	RADIO_OPTIONS=$(_transform_choices_to_dialog_radio_options "$BUILD_TOOL_SELECTIONS" "$BUILD_TOOL")
	BUILD_TOOL=$(eval "dialog --stdout --backtitle \"$BACK_TITLE\" --radiolist 'Select build tool' 0 0 0 $RADIO_OPTIONS")
}

function change_java_version() {
	JAVA_VERSION_SELECTIONS='"11"\n"Java 11"\n"17"\n"Java 17"'
	RADIO_OPTIONS=$(_transform_choices_to_dialog_radio_options "$JAVA_VERSION_SELECTIONS" "$JAVA_VERSION")
	JAVA_VERSION=$(eval "dialog --stdout --backtitle \"$BACK_TITLE\" --radiolist 'Select build tool' 0 0 0 $RADIO_OPTIONS")
}

function change_quarkus_platform_version() {
	QUARKUS_PLATFORM_VERSION_SELECTIONS=$(echo $QUARKUS_PLATFORM_METADATA | jq '.[] | .platformVersion, .recommended')
	RADIO_OPTIONS=$(_transform_choices_to_dialog_radio_options "$QUARKUS_PLATFORM_VERSION_SELECTIONS" "$QUARKUS_PLATFORM_VERSION")
	QUARKUS_PLATFORM_VERSION=$(eval "dialog --stdout --backtitle \"$BACK_TITLE\" --radiolist 'Select Quarkus Platform version' 0 0 0 $RADIO_OPTIONS")
}

function dependency_management () {
	# get all the possible selections, default to not selected
	DEPENDENCY_LIST=$(echo $QUARKUS_EXTENSIONS_METADATA | jq 'map(.id, .name, .description)[]' | sed '{N;N;s/\n/#/g;}' | sed -E 's/(".+")#(".+")#(".+")/\1 \2 off \3/')
    
	# turn our currently selected dependencies on
	for SELECTED_DEPENDENCY in $(echo "$DEPENDENCIES" | tr ',' '\n')
	do
	    DEPENDENCY_LIST=$(echo "$DEPENDENCY_LIST" | sed -E "s/(\"$SELECTED_DEPENDENCY\" .*) off/\1 on/")
	done

	# make it into a format that dialog works with (without newlines)
	DEPENDENCY_LIST=$(echo $DEPENDENCY_LIST | tr '\n' ' ')
    
	DEPENDENCIES=$(eval "dialog --stdout --backtitle \"$BACK_TITLE\" --item-help --checklist \"Choose dependencies\" 0 0 0 $DEPENDENCY_LIST" | sed 's/ /,/g')
}

while true
do
	CHOICE=$(dialog --stdout --backtitle "$BACK_TITLE" --title "Select option" --menu "Artifact information:\nGroup id:                 $GROUP_ID\nArtifact id:              $ARTIFACT_ID\n\nBuild tool:               $BUILD_TOOL\nQuarkus Platform version: $QUARKUS_PLATFORM_VERSION\nJava version:             $JAVA_VERSION\n" 0 0 0 "a" "Artifact settings" "b" "Change build tool" "q" "Change Quarkus Platform version" "j" "Change Java version" "d" "Manage dependencies" "c" "Create project")

    # shellcheck disable=SC2181
	if [ $? -ne 0 ]
	then 
		echo "Cancel selected, exiting..."
		exit 1
	fi
	
	case $CHOICE in
		"a")
			artifact_settings
			;;
		"b")
			change_build_tool
			;;
		"q")
			change_quarkus_platform_version
			;;
		"j")
			change_java_version
			;;
		"d")
			dependency_management
			;;
		"c")
            # fetch correct information based upon the human readable keys
            QUARKUS_PLATFORM_VERSION_KEY=$(echo "$QUARKUS_PLATFORM_METADATA" | jq ".[] | select(.platformVersion == \"$QUARKUS_PLATFORM_VERSION\") | .key")
            DEPENDENCIES_JSON=$([ -z $DEPENDENCIES ] || echo "$DEPENDENCIES" | tr ',' ' ' | sed -E 's/([a-z.:-]+)/"\1"/g' | tr ' ' ',')
            
            # download the app
			curl -s -X POST https://code.quarkus.io/api/download \
                 -H "Content-Type: application/json" \
                 -H "accept: */*" \
                 -d "{\"streamKey\": $QUARKUS_PLATFORM_VERSION_KEY, \"groupId\": \"$GROUP_ID\", \"artifactId\": \"$ARTIFACT_ID\", \"version\": \"$VERSION\", \"buildTool\": \"$BUILD_TOOL\", \"javaVersion\": \"$JAVA_VERSION\", \"extensions\": [$DEPENDENCIES_JSON]}" -o temp.zip
			unzip -q temp.zip
            rm temp.zip
			echo "Quarkus project now in $ARTIFACT_ID directory... Happy Hacking! :)"
			exit 0
			;;
	esac
done
