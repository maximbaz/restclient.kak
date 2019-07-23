# restclient.kak

REST client for [kakoune](https://github.com/mawww/kakoune/), highly inspired by [restclient.el](https://github.com/pashky/restclient.el) for Emacs.

![screenshot](https://user-images.githubusercontent.com/1177900/61742286-0c51dc80-ad93-11e9-9b85-994957576f7f.png)

## Requirements

- [kitty](https://github.com/kovidgoyal/kitty) terminal to create a split window
- `python`
- `xclip` to copy request as cURL command

## Usage

Open a file with `.rest` extension, or just activate the module using `:set buffer filetype restclient`.

Write a query in kakoune in the following format:

```
# Query blocks must begin and end with ###
###

# GitHub API overview, with sending a custom header
GET https://api.github.com
User-Agent: kakoune

###

# Variables must begin with : symbol and can be referenced anywhere in any following block
:github = api.github.com
:api = feeds
:userAgent = User-Agent: kakoune

GET https://:github/:api
:userAgent

###

# Request body must go after an empty line
POST https://jira.atlassian.com/rest/api/2/search
Content-Type: application/json
:userAgent

{
    "jql": "project = HSP",
    "startAt": 0,
    "maxResults": 15,
    "fields": [
        "summary",
        "status",
        "assignee"
    ]
}

# Remember to close the final block with ###
###
```

Put cursor somewhere inside the block and execute `:restclient-execute`.

You can also copy the request as cURL command using `:restclient-copy-as-curl`.
