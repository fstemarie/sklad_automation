function notify \
    -d "Send a notification through ntfy.sh" \
    -a title message

    echo -ne $message | curl -T- \
        -H "title: $title" \
        -H "priority: low" \
        -H "Authorization: Bearer tk_ljqjqthrs7oe8t6g0tkb6r50g3riz" \
        "https://ntfy.sh/falarie-francois-automation"
end
