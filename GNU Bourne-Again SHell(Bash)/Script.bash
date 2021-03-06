#!/usr/bin/env bash
#shellcheck disable=SC2034
# The above line will be obselute after Ubuntu's provided version of ShellCheck <0.4.6 EoL'd, refer https://github.com/koalaman/shellcheck/wiki/Ignore for more info.

## Metadata about This Program
### Program's name, by default it is determined in runtime according to the filename, set this variable to override the autodetection, default: ${RUNTIME_SCRIPT_FILENAME}(optional)
declare -r META_PROGRAM_NAME_OVERRIDE=""

### Program's identifier, program's name with character limitation exposed by platform(optional)
declare -r META_PROGRAM_IDENTIFIER=""

### Program's description, default(optional)
declare -r META_PROGRAM_DESCRIPTION=""

### Intellectual property license applied to this program(optional)
declare -r META_PROGRAM_LICENSE=""

### Whether program should pause and expect user pressing enter when program ended, which is useful when executing scripts in GUI, or in an environment where terminal won't pause when script is ended
### 0: Don't pause(default)
### 1: Pause
### This parameter is overridable, in case of command-line options like --interactive and --no-interactive
declare -i META_PROGRAM_PAUSE_BEFORE_EXIT="0"

### Years since any fraction of copyright material is activated, indicates the year when copyright protection will be outdated(optional)
declare -r META_PROGRAM_COPYRIGHT_ACTIVATED_SINCE=""

### Human-readable name of application(optional)
declare -r META_APPLICATION_NAME=""

### Application's identifier, application's name with limitation posed by other software, default(not implemented): unnamed-application
declare -r META_APPLICATION_IDENTIFIER=""

### Developers' name of application(optional)
declare -r META_APPLICATION_DEVELOPER_NAME=""

### Application's official site URL(optional)
declare -r META_APPLICATION_SITE_URL=""

### Application's issue tracker, if there's any(optional)
declare -r META_APPLICATION_ISSUE_TRACKER_URL=""

### An action to let user get help from developer or other sources when error occurred
declare -r META_APPLICATION_SEEKING_HELP_OPTION="contact developer"

### The Software Directory Configuration this software uses, refer below section for more info
declare META_SOFTWARE_INSTALL_STYLE="SHC"

### These are the dependencies that the script foundation needs, and needs to be checked IMMEDIATELY
declare -r META_RUNTIME_DEPENDENCIES_DESCRIPTION_GNU_COREUTILS="GNU Coreutils"
declare -Ar META_RUNTIME_DEPENDENCIES_CRITICAL=(
	["basename"]="${META_RUNTIME_DEPENDENCIES_DESCRIPTION_GNU_COREUTILS}"
	["realpath"]="${META_RUNTIME_DEPENDENCIES_DESCRIPTION_GNU_COREUTILS}"
)

### These are the dependencies that are used later and also checked later
declare -Ar META_RUNTIME_DEPENDENCIES=()

## Common constant definitions
declare -ir COMMON_RESULT_SUCCESS=0
declare -ir COMMON_RESULT_FAILURE=1
declare -ir COMMON_BOOLEAN_TRUE=0
declare -ir COMMON_BOOLEAN_FALSE=1

## Notes
### realpath's commandline option, `--strip` will be replaced in favor of `--no-symlinks` after April 2019(Ubuntu 14.04's Support EOL)

## Makes debuggers' life easier - Unofficial Bash Strict Mode
## http://redsymbol.net/articles/unofficial-bash-strict-mode/
### Exit immediately if a pipeline, which may consist of a single simple command, a list, or a compound command returns a non-zero status.  The shell does not exit if the command that fails is part of the command list immediately following a `while' or `until' keyword, part of the test in an `if' statement, part of any command executed in a `&&' or `||' list except the command following the final `&&' or `||', any command in a pipeline but the last, or if the command's return status is being inverted with `!'.  If a compound command other than a subshell returns a non-zero status because a command failed while `-e' was being ignored, the shell does not exit.  A trap on `ERR', if set, is executed before the shell exits.
set -o errexit

### Treat unset variables and parameters other than the special parameters `@' or `*' as an error when performing parameter expansion.  An error message will be written to the standard error, and a non-interactive shell will exit.
set -o nounset

### If set, any trap on `ERR' is inherited by shell functions, command substitutions, and commands executed in a subshell environment.  The `ERR' trap is normally not inherited in such cases.
set -o errtrace

### If set, the return value of a pipeline is the value of the last (rightmost) command to exit with a non-zero status, or zero if all commands in the pipeline exit successfully.  This option is disabled by default.
set -o pipefail

## Trap functions
### Trigger trap if program prematurely exited due to an error, collect all information useful to debug
meta_trap_errexit(){
	# No need to debug abort script
	set +o xtrace

	local -ir line_error_location=${1}; shift # The line number that triggers the error
	local -r failing_command="${1}"; shift # The failing command
	local -ir failing_command_return_status=${1} # The failing command's return value

	printf "ERROR: %s has encountered an error and is ending prematurely, %s for support.\n" "${META_PROGRAM_NAME_OVERRIDE:-This program}" "${META_APPLICATION_SEEKING_HELP_OPTION}" 1>&2

	printf "\n" # Separate paragraphs

	printf "Technical information:\n"
	printf "\n" # Separate list title and items
	printf "	* The error happens at line %s\n" "${line_error_location}"
	printf "	* The failing command is \"%s\"\n" "${failing_command}"
	printf "	* Failing command's return status is %s\n" "${failing_command_return_status}"
	printf "	* Intepreter info: GNU Bash v%s on %s platform\n" "${BASH_VERSION}" "${MACHTYPE}"
	printf "\n" # Separate list and further content

	printf "Goodbye.\n"
	return "${COMMON_RESULT_SUCCESS}"
}
readonly -f meta_trap_errexit
# Variable is expanded when trap triggered, not now
#shellcheck disable=SC2016
declare -r TRAP_ERREXIT_ARG='meta_trap_errexit ${LINENO} "${BASH_COMMAND}" ${?}'
# We separate the arguments to TRAP_ERREXIT_ARG, so it should be expand here
#shellcheck disable=SC2064
trap "${TRAP_ERREXIT_ARG}" ERR

### Trap - Introduce itself everytime
meta_printApplicationInfoBeforeNormalExit(){
	# No need to debug this area, keep output simple
	set +o xtrace

	# Only print the line if:
	#
	# * There's info to be print
	# * Pausing program is desired(META_PROGRAM_PAUSE_BEFORE_EXIT=1)
	#
	# ...cause it's kinda stupid for a trailing line at and-of-program-output
	if [ -n "${META_APPLICATION_NAME}" ] || [ -n "${META_APPLICATION_DEVELOPER_NAME}" ] || [ -n "${META_APPLICATION_SITE_URL}" ] || [ -n "${META_PROGRAM_LICENSE}" ] || [ "${META_PROGRAM_PAUSE_BEFORE_EXIT}" -eq 1 ]; then
		printf -- "------------------------------------\n"
	fi
	if [ -n "${META_APPLICATION_NAME}" ]; then
		printf "%s\n" "${META_APPLICATION_NAME}"
	fi
	if [ -n "${META_APPLICATION_DEVELOPER_NAME}" ]; then
		printf "%s et. al." "${META_APPLICATION_DEVELOPER_NAME}"
		if [ -n "${META_PROGRAM_COPYRIGHT_ACTIVATED_SINCE}" ]; then
			printf " " # Separator with ${META_PROGRAM_COPYRIGHT_ACTIVATED_SINCE}
		else
			printf "\n"
		fi
	fi
	if [ -n "${META_PROGRAM_COPYRIGHT_ACTIVATED_SINCE}" ]; then
		printf "© %s\n" "${META_PROGRAM_COPYRIGHT_ACTIVATED_SINCE}"
	fi
	if [ -n "${META_APPLICATION_SITE_URL}" ]; then
		printf "Official Website: %s\n" "${META_APPLICATION_SITE_URL}"
	fi
	if [ -n "${META_PROGRAM_LICENSE}" ]; then
		printf "Intellectual Property License: %s\n" "${META_PROGRAM_LICENSE}"
	fi
	if [ "${META_PROGRAM_PAUSE_BEFORE_EXIT}" -eq 1 ]; then
		local enter_holder

		printf "Press ENTER to quit the program.\n"
		read -r enter_holder
	fi
	return "${COMMON_RESULT_SUCCESS}"
}
declare -fr meta_printApplicationInfoBeforeNormalExit
trap 'meta_printApplicationInfoBeforeNormalExit' EXIT

## Workarounds
### Temporarily disable errexit
meta_workaround_errexit_setup() {
	if [ ${#} -ne 1 ]; then
		printf "ERROR: %s: Wrong function argument quantity!\n" "${FUNCNAME[0]}" 1>&2
		return "${COMMON_RESULT_FAILURE}"
	fi
	local option=${1} # on: enable errexit; off: disable errexit

	if [ "${option}" == "on" ]; then
		set -o errexit
		# We separate the arguments to TRAP_ERREXIT_ARG, so it should be expand here
#shellcheck disable=SC2064
		trap "${TRAP_ERREXIT_ARG}" ERR
	elif [ "${option}" == "off" ]; then
		set +o errexit
		trap - ERR
	else
		printf "ERROR: %s: Wrong function argument format!\n" "${FUNCNAME[0]}" 1>&2
		return "${COMMON_RESULT_FAILURE}"
	fi
	return "${COMMON_RESULT_SUCCESS}"
}
declare -fr meta_workaround_errexit_setup

## Runtime Dependencies Checking
## shell - Check if a program exists from a Bash script - Stack Overflow
## http://stackoverflow.com/questions/592620/check-if-a-program-exists-from-a-bash-script
meta_checkRuntimeDependencies() {
	local -n array_ref="${1}"

	if [ "${#array_ref[@]}" -eq 0 ]; then
		return "${COMMON_RESULT_SUCCESS}"
	else
		declare -i exit_status

		for a_command in "${!array_ref[@]}"; do

			meta_workaround_errexit_setup off
			command -v "${a_command}" >/dev/null 2>&1
			exit_status="${?}"
			meta_workaround_errexit_setup on
			if [ ${exit_status} -ne 0 ]; then
				printf "ERROR: Command \"%s\" not found, program cannot continue like this.\n" "${a_command}" 1>&2
				printf "ERROR: Please make sure %s is installed and it's executable path is in your operating system's executable search path.\n" "${META_RUNTIME_DEPENDENCIES["${a_command}"]}" >&2
				printf "Goodbye.\n"
				exit "${COMMON_RESULT_FAILURE}"
			fi
		done
		unset exit_status
		return "${COMMON_RESULT_SUCCESS}"
	fi
}
declare -fr meta_checkRuntimeDependencies
meta_checkRuntimeDependencies META_RUNTIME_DEPENDENCIES_CRITICAL
meta_checkRuntimeDependencies META_RUNTIME_DEPENDENCIES

## Info acquired from runtime environment
## Defensive Bash Programming - not-overridable primitive definitions
## http://www.kfirlavi.com/blog/2012/11/14/defensive-bash-programming/
### Script's filename(default: auto-detect, unset if not available)
declare RUNTIME_SCRIPT_FILENAME

### Script's resident directory(default: auto-detect, unset if not available)
declare RUNTIME_SCRIPT_DIRECTORY

### Script's absolute path(location + filename)(default: auto-detect, unset if not available)
declare RUNTIME_SCRIPT_PATH_ABSOLUTE

### Script's relative path(to current working directory)(default: auto-detect, unset if not available)
declare RUNTIME_SCRIPT_PATH_RELATIVE

### Runtime environment's executable search path priority set
declare -a RUNTIME_PATH_DIRECTORIES
IFS=':' read -r -a RUNTIME_PATH_DIRECTORIES <<< "${PATH}" || true # Without this `read` will return 1
readonly RUNTIME_PATH_DIRECTORIES

### The guessed user input base command (without the arguments), this is handy when showing help, where the proper base command can be displayed(default: auto-detect, unset if not available)
### If ${RUNTIME_SCRIPT_DIRECTORY} is in ${RUNTIME_PATH_DIRECTORIES}, this would be ${RUNTIME_SCRIPT_FILENAME}, if not this would be ./${RUNTIME_SCRIPT_PATH_RELATIVE}
declare RUNTIME_COMMAND_BASE

### Collect command-line arguments
declare -ir RUNTIME_COMMANDLINE_ARGUMENT_QUANTITY="${#}"
if [ "${RUNTIME_COMMANDLINE_ARGUMENT_QUANTITY}" -ne 0 ]; then
	declare -a RUNTIME_COMMANDLINE_ARGUMENT_LIST
	RUNTIME_COMMANDLINE_ARGUMENT_LIST=("${@:1}")
	readonly RUNTIME_COMMANDLINE_ARGUMENT_LIST
fi

### Auto-detection algorithm
if [ ! -v BASH_SOURCE ]; then
	# S.H.C. isn't possible(probably from stdin), force F.H.S.
	META_SOFTWARE_INSTALL_STYLE=FHS

	unset RUNTIME_SCRIPT_FILENAME RUNTIME_SCRIPT_DIRECTORY RUNTIME_SCRIPT_PATH_ABSOLUTE RUNTIME_SCRIPT_PATH_RELATIVE
else
	# BashFAQ/How do I determine the location of my script? I want to read some config files from the same place. - Greg's Wiki
	# http://mywiki.wooledge.org/BashFAQ/028
	RUNTIME_SCRIPT_FILENAME="$(basename "${BASH_SOURCE[0]}")"
	readonly RUNTIME_SCRIPT_FILENAME
	# FIXME: Currently we can't acquire the correct path if the script is located in a symlinked directory and we run the script using relative path, we can only acquire the resolved path(--no-symlinks won't fix this)
	# This is due to ${BASH_SOURCE[0]} only gets relative path when running relatively, and relative path is already resolved.
	RUNTIME_SCRIPT_DIRECTORY="$(dirname "$(realpath --strip "${BASH_SOURCE[0]}")")"
	readonly RUNTIME_SCRIPT_DIRECTORY
	RUNTIME_SCRIPT_PATH_ABSOLUTE="${RUNTIME_SCRIPT_DIRECTORY}/${RUNTIME_SCRIPT_FILENAME}"
	readonly RUNTIME_SCRIPT_PATH_ABSOLUTE
	RUNTIME_SCRIPT_PATH_RELATIVE="$(realpath --relative-to="${PWD}" --strip "${RUNTIME_SCRIPT_PATH_ABSOLUTE}")"
	readonly RUNTIME_SCRIPT_PATH_RELATIVE

	declare pathdir
	for pathdir in "${RUNTIME_PATH_DIRECTORIES[@]}"; do
		resolved_pathdir="$(realpath "${pathdir}")"

		# If resolved path isn't the same path (id. est. symbolic links), also check the resolved path
		if [ "${pathdir}" != "${resolved_pathdir}" ]; then
			if [ "${RUNTIME_SCRIPT_DIRECTORY}" == "${resolved_pathdir}" ]; then
				RUNTIME_COMMAND_BASE="${RUNTIME_SCRIPT_FILENAME}"
				break
			fi
		fi
		unset resolved_pathdir

		if [ "${RUNTIME_SCRIPT_DIRECTORY}" == "${pathdir}" ]; then
			RUNTIME_COMMAND_BASE="${RUNTIME_SCRIPT_FILENAME}"
			break
		fi
	done
	unset pathdir
	readonly RUNTIME_COMMAND_BASE="${RUNTIME_COMMAND_BASE:-${RUNTIME_SCRIPT_PATH_RELATIVE}}"
fi

## Software Directories Configuration(S.D.C.)
## This section defines and determines the directories used by the software
### Directory to find executables(default: autodetermined, unset if not available)
declare SDC_EXECUTABLE_DIR

### Directory to find libraries(default: autodetermined, unset if not available)
declare SDC_EXECUTABLE_DIR

### Directory contain shared resources(default: autodetermined, unset if not available)
declare SDC_SHARED_RES_DIR

### Directory contain internationalization(I18N) data(default: autodetermined, unset if not available)
declare SDC_I18N_DATA_DIR

### Direcotory contain software settings(default: autodetermined, unset if not available)
declare SDC_SETTINGS_DIR

### Directory contain temporory files created by program(default: autodetermined, unset if not available)
declare SDC_TEMP_DIR

case "${META_SOFTWARE_INSTALL_STYLE}" in
	FHS)
		# Filesystem Hierarchy Standard(F.H.S.) configuration paths
		# http://refspecs.linuxfoundation.org/FHS_3.0/fhs
		## Software installation directory prefix, should be overridable by configure/install script
		declare -r FHS_PREFIX_DIR="/usr/local"

		readonly SDC_EXECUTABLE_DIR="${FHS_PREFIX_DIR}/bin"
		readonly SDC_LIBRARY_DIR="${FHS_PREFIX_DIR}/lib"
		readonly SDC_SHARED_RES_DIR="${FHS_PREFIX_DIR}/share/${META_APPLICATION_IDENTIFIER}"
		readonly SDC_I18N_DATA_DIR="${FHS_PREFIX_DIR}/share/locale"
		readonly SDC_SETTINGS_DIR="/etc/${META_APPLICATION_IDENTIFIER}"
		readonly SDC_TEMP_DIR="/tmp/${META_APPLICATION_IDENTIFIER}"
		;;
	SHC)
		# Self-contained Hierarchy Configuration(S.H.C.) paths
		# This is the convention when F.H.S. is not possible(not a F.H.S. compliant UNIX-like system) or not desired, everything is put under package's DIR(and for runtime-generated files, in user's directory) instead.
		## Software installation directory prefix, should be overridable by configure/install script
		#shellcheck source=SOFTWARE_INSTALLATION_PREFIX_DIR.source.bash
		source "${RUNTIME_SCRIPT_DIRECTORY}/SOFTWARE_INSTALLATION_PREFIX_DIR.source.bash" || true
		SHC_PREFIX_DIR="$(realpath --strip "${RUNTIME_SCRIPT_DIRECTORY}/${SOFTWARE_INSTALLATION_PREFIX_DIR:-.}")" # By default we expect that the software installation directory prefix is same directory as script
		readonly SHC_PREFIX_DIR

		#shellcheck source=SOFTWARE_DIRECTORY_CONFIGURATION.source.bash
		source "${SHC_PREFIX_DIR}/SOFTWARE_DIRECTORY_CONFIGURATION.source.bash" || true
		if [ -z "${SDC_EXECUTABLE_DIR}" ]; then
			unset SDC_EXECUTABLE_DIR
		fi
		if [ -z "${SDC_LIBRARY_DIR}" ]; then
			unset SDC_LIBRARY_DIR
		fi
		if [ -z "${SDC_SHARED_RES_DIR}" ]; then
			unset SDC_SHARED_RES_DIR
		fi
		if [ -z "${SDC_I18N_DATA_DIR}" ]; then
			unset SDC_I18N_DATA_DIR
		fi
		if [ -z "${SDC_SETTINGS_DIR}" ]; then
			unset SDC_SETTINGS_DIR
		fi
		if [ -z "${SDC_TEMP_DIR}" ]; then
			unset SDC_TEMP_DIR
		fi
		;;
	STANDALONE)
		# Standalone Configuration
		# This program don't rely on any directories, make no attempt defining them
		unset SDC_EXECUTABLE_DIR SDC_LIBRARY_DIR SDC_SHARED_RES_DIR SDC_I18N_DATA_DIR SDC_SETTINGS_DIR SDC_TEMP_DIR
		;;
	*)
		unset SDC_EXECUTABLE_DIR SDC_LIBRARY_DIR SDC_SHARED_RES_DIR SDC_I18N_DATA_DIR SDC_SETTINGS_DIR SDC_TEMP_DIR
		printf "Error: Unknown software directories configuration, program can not continue.\n" 1>&2
		exit 1
		;;
esac

## Program's Commandline Options Definitions
declare -r COMMANDLINE_OPTION_DISPLAY_HELP_LONG="--help"
declare -r COMMANDLINE_OPTION_DISPLAY_HELP_SHORT="-h"
declare -r COMMANDLINE_OPTION_DISPLAY_HELP_DESCRIPTION="Display help message"

declare -r COMMANDLINE_OPTION_ENABLE_DEBUGGING_LONG="--debug"
declare -r COMMANDLINE_OPTION_ENABLE_DEBUGGING_SHORT="-d"
declare -r COMMANDLINE_OPTION_ENABLE_DEBUGGING_DESCRIPTION="Enable debug mode"

## Program Configuration Variables
declare -i global_just_show_help="${COMMON_BOOLEAN_FALSE}"
declare -i global_enable_debugging="${COMMON_BOOLEAN_FALSE}"

## Drop first element from array and shift remaining elements 1 element backward
meta_util_array_shift(){
	local -n array_ref=${1}

	# Check input validity
	# When -v test is used against a nameref, the name is tested
	if [ ${#array_ref[@]} -eq 0 ]; then
		printf "ERROR: array is empty!\n" 1>&2
		return "${COMMON_RESULT_FAILURE}"
	fi

	# Unset the 1st element
	unset "array_ref[0]"

	# Repack array if element still available in array
	if [ ${#array_ref[@]} -ne 0 ]; then
		array_ref=("${array_ref[@]}")
	fi

	return "${COMMON_RESULT_SUCCESS}"
}
declare -fr meta_util_array_shift

## Understand what argument is in the command, and set the global variables accordingly.
meta_processCommandlineArguments() {
	if [ "${RUNTIME_COMMANDLINE_ARGUMENT_QUANTITY}" -eq 0 ]; then
		return "${COMMON_RESULT_SUCCESS}"
	else
		local -a arguments=("${RUNTIME_COMMANDLINE_ARGUMENT_LIST[@]}")

		while :; do
			# BREAK if no arguments left
			if [ ! -v arguments ]; then
				break
			else
				case "${arguments[0]}" in
					"${COMMANDLINE_OPTION_DISPLAY_HELP_LONG}"|"${COMMANDLINE_OPTION_DISPLAY_HELP_SHORT}")
						global_just_show_help="${COMMON_BOOLEAN_TRUE}"
						;;
					"${COMMANDLINE_OPTION_ENABLE_DEBUGGING_LONG}"|"${COMMANDLINE_OPTION_ENABLE_DEBUGGING_SHORT}")
						global_enable_debugging="${COMMON_BOOLEAN_TRUE}"
						;;
					*)
						printf "ERROR: Unknown command-line argument \"%s\"\n" "${arguments[0]}" >&2
						return ${COMMON_RESULT_FAILURE}
						;;
				esac
				meta_util_array_shift arguments
			fi
		done
	fi

	return "${COMMON_RESULT_SUCCESS}"
}
declare -fr meta_processCommandlineArguments

## Print single segment of commandline option help
meta_util_printSingleCommandlineOptionHelp(){
	if [ "${#}" -ne 3 ] && [ "${#}" -ne 4 ]; then
		printf "ERROR: %s: Wrong parameter quantity!\n" 1>&2
		return "${COMMON_RESULT_FAILURE}"
	fi

	local description="${1}"; shift # Option description
	local long_option="${1}"; shift # The long version of option
	local short_option="${1}" # The short version of option
	readonly description long_option short_option

	if [ "${#}" -eq 4 ]; then
		shift
		local current_value="${1}" # Current value of option, if option has value
		readonly current_value
	fi

	printf "### %s / %s ###\n" "${long_option}" "${short_option}"
	printf "%s\n" "${description}"

	if [ "${#}" -eq 4 ]; then
		printf "Current value: %s\n" "${current_value}"
	fi

	printf "\n" # Separate with next option(or next heading)
	return "${COMMON_RESULT_SUCCESS}"
}
declare -fr meta_util_printSingleCommandlineOptionHelp

## Print help message whenever:
##   * User requests it
##   * An command syntax error has detected
meta_printHelpMessage(){
	if [ -n "${META_PROGRAM_NAME_OVERRIDE}" ]; then
		printf "# %s #\n" "${META_PROGRAM_NAME_OVERRIDE}"
	else
		printf "# %s #\n" "${RUNTIME_COMMAND_BASE}"
	fi

	if [ -n "${META_PROGRAM_DESCRIPTION}" ]; then
		printf "%s\n" "${META_PROGRAM_DESCRIPTION}"
		printf "\n"
	fi

	printf "## Usage ##\n"
	printf "\t%s <commandline options>\n" "${RUNTIME_COMMAND_BASE}"
	printf "\n"
	printf "## Command-line Options ##\n"
	meta_util_printSingleCommandlineOptionHelp "${COMMANDLINE_OPTION_DISPLAY_HELP_DESCRIPTION}" "${COMMANDLINE_OPTION_DISPLAY_HELP_LONG}" "${COMMANDLINE_OPTION_DISPLAY_HELP_SHORT}"
	meta_util_printSingleCommandlineOptionHelp "${COMMANDLINE_OPTION_ENABLE_DEBUGGING_DESCRIPTION}" "${COMMANDLINE_OPTION_ENABLE_DEBUGGING_LONG}" "${COMMANDLINE_OPTION_ENABLE_DEBUGGING_SHORT}"
	return "${COMMON_RESULT_SUCCESS}"
}
declare -fr meta_printHelpMessage

## Defensive Bash Programming - init function, program's entry point
## http://www.kfirlavi.com/blog/2012/11/14/defensive-bash-programming/
init() {
	meta_processCommandlineArguments
	if [ "${?}" -eq "${COMMON_RESULT_FAILURE}" ]; then
		meta_printHelpMessage
		exit "${COMMON_RESULT_FAILURE}"
	fi

	# Secure configuration variables by marking them readonly
	readonly \
		global_just_show_help\
		global_enable_debugging

	if [ "${global_enable_debugging}" -eq "${COMMON_BOOLEAN_TRUE}" ]; then
		set -o xtrace
	fi
	if [ "${global_just_show_help}" -eq "${COMMON_BOOLEAN_TRUE}" ]; then
		meta_printHelpMessage
		exit "${COMMON_RESULT_SUCCESS}"
	fi

	exit "${COMMON_RESULT_SUCCESS}"
}
declare -fr init
init
