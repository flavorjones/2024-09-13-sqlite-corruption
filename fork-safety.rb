#! /usr/bin/env ruby

require_relative "config/environment"

# Number of children each generation will fork.
# 10 reproduces reliably on my machine.
NCHILD = 10

# scenario 1: reproduce the issue
# this will cause I/O exceptions and eventually corrupt the database
WAIT_FOR_CHILDREN = false

# # scenario 2: parents wait for children to exit before they themselves exit
# # this will NOT corrupt the database
# WAIT_FOR_CHILDREN = true

def integrity_check
  SQLite3::Database.open("storage/development.sqlite3") do |db|
    result = db.execute("pragma integrity_check;")
    pp result
    exit 1 if result != [["ok"]]
  end
end

LETTERS = ('a'..'z').to_a
def do_some_work c = 1
  # give the db a reasonable corpus
  50.times { Post.create title: LETTERS.sample(8).join } if Post.count < 50

  10.times do
    putc c.to_s
    Post.create title: LETTERS.sample(8).join
    begin
      Post.all.sample.update(title: LETTERS.sample(8).join)
      Post.all.sample.delete
    rescue ActiveRecord::RecordNotFound
    end
  end
end

def do_grandchild
  do_some_work 2
  exit 0
end

def do_child
  do_some_work 1
  NCHILD.times { Process.fork { do_grandchild } }
  NCHILD.times { Process.waitpid } if WAIT_FOR_CHILDREN
  exit 0
end

integrity_check

do_some_work 0
NCHILD.times { Process.fork { do_child } }
NCHILD.times { Process.waitpid } if WAIT_FOR_CHILDREN

exit 0
