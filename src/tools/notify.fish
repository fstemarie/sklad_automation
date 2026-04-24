
function notify \
    -d "Send a notification through ntfy.sh" \
    -a title message

    echo -ne $message | curl -T- \
        -H "title: $title" \
        -H "priority: low" \
        https://ntfy.sh/falarie.francois.automation
end
