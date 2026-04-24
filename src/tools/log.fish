# @fish-lsp-disable 4004

function info --description 'Log the info to a file and to the screen' -a message
    # Create the log file if it doesn't exist
    test -z "$log"; and set -gx log /dev/null
    not test -e "$log"; and touch "$log"
    set_color normal
    echo "[INFO] 🔹 $message" | tee -a $log
    logger -p user.info -t (status basename) "[INFO] $message"
    return 0
end

function warning --description 'Log the warning to a file and to the screen' -a message logger
    # Create the log file if it doesn't exist
    test -z "$log"; and set -gx log /dev/null
    not test -e "$log"; and touch "$log"
    set -U __WARNINGS__
    set_color bryellow
    echo "[WARNING] ⚠️ $message" | tee -a $log
    set_color normal
    logger -p user.warning -t (status basename) "[WARNING] $message"
    return 0
end

function error --description 'Log the error to a file and the logger' -a message logger
    # Create the log file if it doesn't exist
    test -z "$log"; and set -gx log /dev/null
    not test -e "$log"; and touch "$log"
    set_color brred
    echo "[ERROR] ❌ $message" | tee -a $log
    set_color normal
    logger -p user.error -t (status basename) "[ERROR] $message"
    return 0
end

function success --description 'Log the info to a file and to the screen' -a message logger
    # Create the log file if it doesn't exist
    test -z "$log"; and set -gx log /dev/null
    not test -e "$log"; and touch "$log"
    set_color brgreen
    echo "[SUCCESS] ✅ $message" | tee -a $log
    set_color normal
    logger -p user.info -t (status basename) "[SUCCESS] $message"
    return 0
end
