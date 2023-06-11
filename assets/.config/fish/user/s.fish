function s
  switch $argv[(count $argv)]
    case '-*'

    case '*'
      if test -d $argv[(count $argv)]
        ls $argv
      else
        cat $argv
      end
      return
  end
end

complete -c s -n "test -f $argv[1]" -w "cat"
complete -c s -n "test -d $argv[1]" -w "ls"
