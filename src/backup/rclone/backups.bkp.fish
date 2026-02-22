#! /usr/bin/env fish

set src "/d/sapphire/backup/"
set dst "filelu:/backup-mirror"

rclone sync "$src" "$dst"
