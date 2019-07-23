declare-option -docstring "Python code to convert block to curl command" str restclient_curlify '
import sys

lines = [l.strip() for l in sys.stdin.read().strip().split("\n")]

vars = {}
for line in lines:
    if line.startswith(":") and "=" in line:
        segments = [s.strip() for s in line.split("=", 1)]
        vars[segments[0]] = segments[1]

lines = [line for line in lines if not (line.startswith(":") and "=" in line)]
while len(lines[0]) == 0:
    lines.pop(0)

method, url = lines.pop(0).split(" ", 1)
result = "curl -Ssi -X{} ''{}'' ".format(method, url)

while len(lines) > 0:
    line = lines.pop(0)
    if len(line) == 0:
        break
    result += "-H ''{}'' ".format(line)

if len(lines) > 0:
    result += "-d ''{}''".format("".join([l.strip() for l in lines]))

for var, val in vars.items():
    result = result.replace(var, val)

print(result)
'

declare-option -docstring "Python code to prettify curl output" str restclient_prettify '
import sys
import json

lines = "\n".join(sys.stdin.read().strip().splitlines())
data = lines.split("\n\n", 1)
if len(data) > 1:
    try:
        print(json.dumps(json.loads(data[1]), indent=4, sort_keys=True), "\n")
    except:
        print(data[1])
print(data[0])
'

define-command restclient-execute %{
    nop %sh{
        mkdir -p /tmp/kak-restclient
        echo 'Loading...' > "/tmp/kak-restclient/${kak_session}.json"
    }

    try %{
        evaluate-commands -client kak-restclient-response edit!
    } catch %{
        nop %sh{
            kitty @ new-window --no-response --window-type os kak -c "${kak_session}" -e "
            rename-client kak-restclient-response
            edit /tmp/kak-restclient/${kak_session}.json
            "
            kitty @ focus-window --no-response --match id:"${KITTY_WINDOW_ID}"
        }
    }

    evaluate-commands -draft %{
        restclient-select-block

        nop %sh{
            (
                {
                    echo "${kak_selections}" \
                        | python -c "${kak_opt_restclient_curlify}" \
                        | sh \
                        | python -c "${kak_opt_restclient_prettify}"
                } >"/tmp/kak-restclient/${kak_session}.json.new" 2>&1
                mv "/tmp/kak-restclient/${kak_session}.json.new" "/tmp/kak-restclient/${kak_session}.json"
                echo 'evaluate-commands -client kak-restclient-response edit!' | kak -p "$kak_session"
                echo 'execute-keys -client kak-restclient-response gg' | kak -p "$kak_session"
            ) < /dev/null >/dev/null 2>&1 &
        }
    }
}

define-command restclient-copy-curl %{
    evaluate-commands -draft %{
        restclient-select-block

        nop %sh{
            (
                echo "${kak_selections}" \
                    | python -c "${kak_opt_restclient_curlify}" \
                    | xclip -selection clipboard -i
            ) < /dev/null >/dev/null 2>&1 &
        }
    }
}

define-command -hidden restclient-select-block %{
    try %{
        execute-keys -save-regs '' '<a-i>c###,###<ret><a-x><a-s><a-K>^#<ret><a-_>_Z<a-:><a-;>Gg<a-s><a-K>^#<ret><a-k>^:.*=<ret>'
        execute-keys '<a-z>a_'
    } catch %{
        execute-keys 'z'
    }
    execute-keys '<a-x>'
}
