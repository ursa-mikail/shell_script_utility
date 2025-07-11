# version: 2020-12-03_1300hr_44sec
#
number_of_levels_up="./"
#
# include configuration file (containing variables)
echo "< Sourcing include.sh >"
source $HOME"/scripts/parameters.sh"
#
source $HOME"/scripts/functions/developer_aid.sh"
source $HOME"/scripts/functions/cipher_utility.sh"
source $HOME"/scripts/functions/hash_utility.sh"
source $HOME"/scripts/functions/mac_utility.sh"  
source $HOME"/scripts/functions/signing_utility.sh"
source $HOME"/scripts/functions/keys.sh"
source $HOME"/scripts/functions/identity.sh"
source $HOME"/scripts/functions/passcode_utility.sh"
#
source $HOME"/scripts/functions/cert_utility.sh"
#
source $HOME"/scripts/functions/status_codes.sh"
source $HOME"/scripts/functions/text.sh"
source $HOME"/scripts/functions/text_batch.sh"
source $HOME"/scripts/functions/grep_utility.sh"
source $HOME"/scripts/functions/regex_utility.sh"
#
source $HOME"/scripts/functions/time.sh"
#
source $HOME"/scripts/functions/serial.sh"
source $HOME"/scripts/functions/view.sh"
#
source $HOME"/scripts/functions/environment_setting.sh"
source $HOME"/scripts/functions/display.sh"
#
source $HOME"/scripts/functions/shell_setting.sh"
#
source $HOME"/scripts/functions/data_convert.sh"
source $HOME"/scripts/functions/data_structure_utility.sh"
source $HOME"/scripts/functions/random_naive.sh"
#
source $HOME"/scripts/functions/files_n_folders.sh"
source $HOME"/scripts/functions/folders_and_files.sh"
#
#source $number_of_levels_up"miscellany_tests/test_cases.sh"
source $HOME"/scripts/functions/git_utility.sh"

# [utilities]
source $HOME"/scripts/utilities/text_formatter.sh"
source $HOME"/scripts/utilities/cipher_message_file_and_hash.sh"
source $HOME"/scripts/utilities/function_run_timer.sh"
source $HOME"/scripts/utilities/dev_shell.sh"
source $HOME"/scripts/utilities/batch_processor.sh"

source $HOME"/scripts/utilities/file_filter.sh"
#source $HOME"/scripts/utilities/main.sh"
#source $HOME"/scripts/utilities/main_functions.sh"
source $HOME"/scripts/utilities/yubi.sh"

echo ""
: <<'NOTE_BLOCK_AREA'

* for hidden files: `shift`-`command`-`.` to expose in folders.
This area is a block comment area. 

NOTE_BLOCK_AREA
echo ""	
