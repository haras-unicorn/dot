function run -d "Start a job and disown it"
  $argv 2> /dev/null &
  disown $last_pid
end