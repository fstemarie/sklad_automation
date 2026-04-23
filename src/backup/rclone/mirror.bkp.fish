#! /usr/bin/env fish

set src "/l/backup/"
set dst "filelu:/backup/mirror/"

rclone sync -P "$src" "$dst"
