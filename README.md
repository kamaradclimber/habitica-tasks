# Habitica::Tasks

This gem helps to automatize some task patterns in habitica. It starts by scratching my own itch with future tasks.


## Future tasks

Some tasks cannot be started before a given time. It's tempting to create them in advance but since we cannot work on them, they'll artificially change color (giving more XP for no good reason).

To create a future task, use habitica interface to create a ToDo and add `[create_on:2021-05-26]` in the description. Then run habitica-tasks binary, it will delete the task (😱) and recreate it when you'll re-run the habitica-tasks binary on (or after) the planned creation date.

Tip: run `habitica-tasks` with a timer on your computer/server.
