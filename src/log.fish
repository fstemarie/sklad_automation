function log --description 'Log the info to a file and the logger' -a message
    info $message true
end

function info --description 'Log the info to a file and to the screen' -a message logger
    # Create the log file if it doesn't exist
    test ! -e "$log" && touch $log_file
    set_color normal
    echo "[INFO] 🔹 $message" | tee -a $log
    test -n "$logger"; and logger -t (status basename) "[INFO] $message"
    return 0
end

function warning --description 'Log the warning to a file and to the screen' -a message logger
    # Create the log file if it doesn't exist
    test ! -e "$log" && touch $log_file
    set_color bryellow
    echo "[WARNING] ⚠️ $message" | tee -a $log
    set_color normal
    test -n "$logger"; and logger -t (status basename) "[INFO] $message"
    return 0
end

function error --description 'Log the error to a file and the logger' -a message logger
    # Create the log file if it doesn't exist
    test ! -e "$log" && touch $log_file
    set_color brred
    echo "[ERROR] ❌ $message" | tee -a $log
    set_color normal
    test -n "$logger"; and logger -t (status basename) "[INFO] $message"
    return 0
end

function success --description 'Log the info to a file and to the screen' -a message logger
    # Create the log file if it doesn't exist
    test ! -e "$log" && touch $log_file
    set_color brgreen
    echo "[INFO] ✅ $message" | tee -a $log
    set_color normal
    test -n "$logger"; and logger -t (status basename) "[INFO] $message"
    return 0
end
