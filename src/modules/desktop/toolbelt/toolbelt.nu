let tools = r#'DOT_TOOLBELT_TOOLS'# | from json

def "mime base" []: string -> string {
  $in | split row ";" | first | str trim
}

def "processor display" []: record -> string {
  let display = $in.display
  let note = $in.note
  let output = $in.output?

  let note_part = if ($note | is-empty) {
    ""
  } else {
    $" ($note)"
  }

  let output_part = if ($output | is-empty) {
    ""
  } else {
    $" \(($output)\)"
  }

  ($display + ":" + $note_part + $output_part) | str trim
}

def "file mime" []: string -> string {
  file --mime-type -b $in | str trim
}

def "mime extension" []: string -> string {
  python3 -c (
    "import mimetypes"
    + $"\nprint\(mimetypes.guess_extension\('($in)'\) or ''\)"
    + "\n"
  ) | str trim
}

log "startup" (
  "loaded"
  + $" ($tools.sources | transpose | length) sources,"
  + $" ($tools.nodes | transpose | length) nodes,"
  + $" ($tools.sinks | transpose | length) sinks,"
  + $" ($tools.pipelines | transpose | length) pipelines"
)

let data_dir = (
  $env.XDG_RUNTIME_DIR?
    | default "/run"
    | path join "toolbelt"
)
mkdir $data_dir

let tmp_dir = $data_dir | path join tmp
rm -rf $tmp_dir
mkdir $tmp_dir
let tmp = $data_dir | path join (random uuid)

let data_file = $data_dir | path join "data"
let meta_file = $data_dir | path join "metadata.json"

let meta = if ($meta_file | path exists) {
  open $meta_file
} else {
  {
    created: null
    modified: null
    pipeline: []
    mime: null
    extension: null
  }
}

log "state" $"mime=($meta.mime | default "empty") pipeline=($meta.pipeline | str join ",")"

mut actions = []

let sources = ($tools.sources | transpose name data)
for source in $sources {
  $actions = (
    $actions
      | append {
          name: $source.name
          kind: "source"
          display: ($source.data | processor display)
          exe: $source.data.exe
          output: $source.data.output
        }
  )
}

log "actions" $"($sources | length) sources matched, ($actions | length) actions total"

if $meta.mime != null {
  let nodes = (
    $tools.nodes
      | transpose name data
      | where ($meta.mime | mime base) in ($it.data.inputs | each { mime base }) or $it.data.inputs == "any"
  )
  for node in $nodes {
    $actions = (
      $actions
        | append {
            name: $node.name,
            kind: "node",
            display: ($node.data | processor display)
            exe: $node.data.exe,
            output: $node.data.output,
          }
    )
  }

  log "actions" $"($nodes | length) nodes matched, ($actions | length) actions total"
}

if $meta.mime != null {
  let sinks = (
    $tools.sinks
      | transpose name data
      | where ($meta.mime | mime base) in ($it.data.inputs | each { mime base }) or $it.data.inputs == "any"
  )
  for sink in $sinks {
    $actions = ($actions | append {
      name: $sink.name
      kind: "sink"
      display: ($sink.data | processor display)
      exe: $sink.data.exe,
      output: null
    })
  }

  log "actions" $"($sinks | length) sinks matched, ($actions | length) actions total"
}

log "actions" $"($actions | length) actions total"

if ($actions | length) == 0 {
  "No actions available" | ui error
  exit 1
}

let choice = (
  $actions
    | get display
    | str join "\n"
    | ui menu
        $"Toolbelt content type: ($meta.mime | default "empty")"
        "Pick a toolbelt action..."
    | str trim
)

if $choice == null {
  "No actions selected" | ui error
  exit 1
}

let selected = $actions
  | where $it.display == $choice
  | first

log "choice" $"($selected.kind) ($selected.name)"

match $selected.kind {
  "source" => {
    log "exec" $"source ($selected.name) -> ($tmp)"
    with-env {
      DOT_TOOLBELT_EXTENSION: ""
      DOT_TOOLBELT_MIME: "none"
    } {
      $"($selected.exe) > ($tmp)"
        | ui wait $"Sourcing with ($selected.name)..."
        | common handle $"source ($selected.name)" --on-fail { rm -f $tmp }
    }

    mv -f $tmp $data_file
    let mime = if $selected.output == "detect" {
      $data_file | file mime
    } else {
      $selected.output
    }
    log "result" $"source ($selected.name) output mime=($mime)"
    {
      created: (date now | format date "%+")
      modified: null
      pipeline: [$selected.name]
      mime: $mime
      extension: ($mime | mime extension)
    } | to json | save -f $meta_file
  }
  "node" => {
    log "exec" $"node ($selected.name) mime=($meta.mime) -> ($tmp)"
    with-env {
      DOT_TOOLBELT_EXTENSION: $meta.extension
      DOT_TOOLBELT_MIME: $meta.mime
    } {
      $"($selected.exe) < ($data_file) > ($tmp)"
        | ui wait $"Processing with ($selected.name)..."
        | common handle $"node ($selected.name)" --on-fail { rm -f $tmp }
    }

    mv -f $tmp $data_file
    let mime = if $selected.output == "detect" {
      $data_file | file mime
    } else {
      $selected.output
    }
    log "result" $"node ($selected.name) output mime=($mime)"
    {
      created: $meta.created
      modified: (date now | format date "%+")
      pipeline: ($meta.pipeline ++ [ $selected.name ])
      mime: $mime
      extension: ($selected.output | mime extension)
    } | to json | save -f $meta_file
  }
  "sink" => {
    log "exec" $"sink ($selected.name) mime=($meta.mime)"
    with-env {
      DOT_TOOLBELT_EXTENSION: $meta.extension
      DOT_TOOLBELT_MIME: $meta.mime
    } {
      $"($selected.exe) < ($data_file)"
        | ui wait $"Sinking with ($selected.name)..."
        | common handle $"sink ($selected.name)"
    }

    rm -f $data_file $meta_file
  }
}
