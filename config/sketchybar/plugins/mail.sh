#!/bin/bash

source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/icons.sh"

SOCKET="$HOME/Library/Caches/matcha/daemon.sock"

# One short connection: the daemon only sends notifications while no client is connected.
COUNT=$(/usr/bin/python3 - "$SOCKET" 2>/dev/null <<'EOF'
import json, socket, sys

s = socket.socket(socket.AF_UNIX)
s.settimeout(10)
s.connect(sys.argv[1])
f = s.makefile("rw")

def call(id, method, params=None):
    request = {"id": id, "method": method}
    if params:
        request["params"] = params
    f.write(json.dumps(request) + "\n")
    f.flush()
    for line in f:
        msg = json.loads(line)
        if msg.get("id") == id:
            return msg.get("result") or []

accounts = call(1, "GetAccounts")
print(sum(
    folder.get("Unread") or 0
    for i, account in enumerate(accounts, 2)
    for folder in call(i, "FetchFolders", {"account_id": account["id"]})
    if (folder.get("Name") or "").upper() == "INBOX"
))
s.close()
EOF
)

if [ -z "$COUNT" ]; then
	sketchybar --set "$NAME" icon=$MAIL label="-" label.drawing=on icon.color=$LABEL_COLOR
elif [ "$COUNT" -eq 0 ]; then
	sketchybar --set "$NAME" icon=$MAIL label.drawing=off icon.color=$LABEL_COLOR
else
	sketchybar --set "$NAME" icon=$MAIL label="$COUNT" label.drawing=on icon.color=$BLUE
fi
