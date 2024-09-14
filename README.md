# sqlite fork safety repro

This repo reproduces sqlite database corruption using only Active Record and process forking.

See https://github.com/rails/solid_queue/issues/324 for more context.

## What is this.

My hunch after reading the issue linked above and [How To Corrupt An SQLite Database File](https://www.sqlite.org/howtocorrupt.html) is that the corruption might have to do with process forking.

So that's where this repro came from. It easily reproduces at database corruption using nothing but active record and forking. Some caveats, though:

- I can only reproduce this on Linux. I'm not yet sure why, but it may be because of sqlite's specialized code for different operating systems.
- This may not be the only problem with sqlite corruption and may not actually even address some of the observations in this thread. (I'm mostly convinced that there are at least two separate issues being described in that issue.)

## Running the script

Here's how to run it:

```
while ./fork-safety.rb ; do echo again ; done
```

That script exits with nonzero status if the sqlite integrity check fails. When I run it, I see lots of exceptions ("disk I/O error") but those don't always result in corruption. However, running it in a loop reliably reproduces database corruption in a few seconds for me.

Note that corruption only happens when BOTH of these conditions are true:

- the parent has an _open_ sqlite connection when it forks,
- and the parent exits before the children have finished their work

So if the parent waits for the children to exit: no problem. (You can see this yourself if you set the value of `WAIT_FOR_CHILDREN` to `true` in the script.)

If the parent closes its connections before it forks: no problem. (You can see this by editing the script to only spawn 1 generation, and comment out the parent's `do_some_work` call.)

Please note that in this scenario the children are NOT using any database connections inherited from the parent process. Rails does the right thing and creates new connections in the children, which is what is instructed in https://www.sqlite.org/howtocorrupt.html, yet the problem still happens.

## Analysis

What's happening is that open connections and statements that are inherited by the child process are getting cleaned up (closed) by GC which affects the child's connections and may lead to corruption.

## Next steps

Update Rails sqlite3 adapter to close database connections before forking.
