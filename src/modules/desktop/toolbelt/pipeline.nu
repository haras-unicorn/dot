let tools = $env.DOT_TOOLBELT_TOOLS

def "pipeline display" []: record -> string {
  let display = $in.display
  let note = $in.note

  let note_part = if ($note | is-empty) {
    ""
  } else {
    $" ($note)"
  }

  ($display + ":" + $note_part) | str trim
}

def "resolve" [from: string]: string -> record {
  let target = $in

  let results = $tools
    | get $from
    | transpose name data
    | where $it.data.display == $target or $target in $it.data.aliases

  if ($results | length) == 0 {
    $"($from) '($target)' not found" | ui error
    exit 1
  }

  $results | first --strict
}

def "mime extension" []: string -> string {
  python3 -c (
    "import mimetypes"
    + $"\nprint\(mimetypes.guess_extension\('($in)'\) or ''\)"
    + "\n"
  ) | str trim
}

let pipelines = $tools.pipelines | transpose name data

log "startup" $"($pipelines | length) pipelines available"

if ($pipelines | length) == 0 {
  "No pipelines available" | ui error
  exit 1
}

let choice = (
  $pipelines
    | each { get data | pipeline display }
    | common kando "Toolbelt" "Pick a toolbelt pipeline..."
    | str trim
)

if $choice == null {
  "No pipeline selected" | ui error
  exit 1
}

let selected = (
  $pipelines
    | where ($it.data | pipeline display) == $choice
    | first --strict
)

log "choice" $"pipeline ($selected.data.display)"

let source = $selected.data.source
  | resolve "sources"
log "resolve" $"source ($source.name) output=($source.data.output)"

let nodes = $selected.data.nodes
  | default []
  | each { resolve "nodes" }
for node in $nodes {
  log "resolve" $"node ($node.name) inputs=($node.data.inputs | str join ",") output=($node.data.output)"
}

let sink = $selected.data.sink
  | resolve "sinks"
log "resolve" $"sink ($sink.name) inputs=($sink.data.inputs | str join ",")"

let actions = ([ $source ] ++ $nodes ++ [ $sink ]) | enumerate

let mimes = $actions
  | each {
      let index = $in.index - 1
      if $index < 0 {
        return "none"
      }
      $actions
        | get -o $index
        | get -o item.data.output
        | default "unknown"
    }

let command = $actions
  | each { |x|
      let mime = $mimes | get $x.index
      if ($mime | is-empty) or $mime == "none" {
        ($"DOT_TOOLBELT_EXTENSION=\"\""
          + $" DOT_TOOLBELT_MIME=\"none\""
          + $" ($x.item.data.exe)")
      } else if $mime == "unknown" {
        ($"DOT_TOOLBELT_EXTENSION=\"\""
          + $" DOT_TOOLBELT_MIME=\"unknown\""
          + $" ($x.item.data.exe)")
      } else if $mime == "detect" {
        ($"DOT_TOOLBELT_EXTENSION=\"\""
          + $" DOT_TOOLBELT_MIME=\"detect\""
          + $" ($x.item.data.exe)")
      } else {
        let extension = $mime | mime extension
        ($"DOT_TOOLBELT_EXTENSION=\"($extension)\""
          + $" DOT_TOOLBELT_MIME=\"($mime)\""
          + $" ($x.item.data.exe)")
      }
    }
  | str join " | "

log "exec" $"command: ($command)"
log "exec" $"mimes: ($mimes | str join ' -> ')"

ui wait $"Running ($selected.data.display)..." (
  $actions
    | reduce
        --fold { || }
        {
          |it, acc| { ||
            let mime = $mimes | get $it.index
            return (with-env {
              DOT_TOOLBELT_MIME: $mime
              DOT_TOOLBELT_EXTENSION: (
                if $mime in [ "detect" "unknown" "none" ] {
                  ""
                } else {
                  $mime | mime extension
                }
              )
            } {
              let result = do $acc | ^$it.item.data.exe
              log "exec" $"command '($it.item.data.display)' done"
              return $result
            })
          }
        }
)
