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

To create a future task, use habitica interface to create a ToDo and add `[create_on:2021-05-26]` in the description. Then run habitica-tasks binary, it will temporarily move the task as a daily starting on the create date. If you re-run the script on the `create_on` date, the daily will be removed and original ToDo will be created again. (If you don't run the script, the todo will appear anyway, so you can't loose your task).

Tip: run `habitica-tasks` with a timer on your computer/server.

## Late Tasks

For "dailies" having a low frequency (less than once per week), a followup "LATE" task will be created to allow to make it right. Points/streak are already lost but at least you have an opportunity to do your task. If you don't want to do it anyway, just delete the `[LATE]` task.
If a task is not suitable for this feature, just add `task-type:no-followup` tag to the daily.

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

# Contribute

Contributions are welcomed!

- To contribute a new feature, make sure to create an issue first to describe the feature.
- To contribute a nontrivial bugfix, make sure to create an issue first.

This repository does not have any tests, I'm mostly using for my own usage and I'm not afraid to debug the program once in a while.
