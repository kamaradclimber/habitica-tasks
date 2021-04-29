# Habitica::Tasks

This gem helps to automatize some task patterns in habitica. It starts by scratching my own itch with future tasks.

## Configuration

Create a file `$HOME/.config/habitica-tasks/config.yml` and populate with at least:
```
user_id: xxx-xxx-xxx-xxx-xxxx
api_token: xxx-xxx-xxx-xxx-xxxx
```

## Rate limiting

⚠ Rate limiting is not implemented correctly by our underlying gem so this program can fail with "RestError" if it starts doing a lot of action (like creating many tasks at once). Just wait for 1 minute and resume.

## Future tasks

Some tasks cannot be started before a given time. It's tempting to create them in advance but since we cannot work on them, they'll artificially change color (giving more XP for no good reason).

To create a future task, use habitica interface to create a ToDo and add `[create_on:2021-05-26]` in the description. Then run habitica-tasks binary, it will delete the task (😱) and recreate it when you'll re-run the habitica-tasks binary on (or after) the planned creation date.

Tip: run `habitica-tasks` with a timer on your computer/server.

## Jira tasks

This will synchronize tasks from JIRA assigned to you. It will try to guess the complexity based on Story Point if they are set.
To use this you'll need to add a few fields in your config.yml:

```
jira:
  username: '...'
  password: '...'
  site: 'htps://...'
```
(note: all options supported by https://github.com/sumoheavy/jira-ruby can be passed there)
