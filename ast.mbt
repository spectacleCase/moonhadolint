///|
pub(all) struct PairNode {
  key : String
  value : String
} derive(Eq, Debug)

///|
pub(all) struct FromNode {
  image : String
  tag : String?
  digest : Bool
  platform : String?
  as_name : String?
} derive(Eq, Debug)

///|
pub(all) struct CopyNode {
  from_stage : String?
  chown : String?
  sources : Array[String]
  dest : String
} derive(Eq, Debug)

///|
pub(all) struct RunNode {
  form : InstructionForm
  script : String
  argv : Array[String]
  has_pipe : Bool
  has_heredoc : Bool
} derive(Eq, Debug)

///|
pub(all) struct ExecNode {
  form : InstructionForm
  argv : Array[String]
  raw : String
} derive(Eq, Debug)

///|
pub(all) enum Node {
  From(FromNode)
  Run(RunNode)
  Copy(CopyNode)
  Add(CopyNode)
  Env(Array[PairNode])
  Arg(PairNode)
  Label(Array[PairNode])
  Expose(Array[String])
  Cmd(ExecNode)
  Entrypoint(ExecNode)
  Workdir(String)
  User(String)
  Other
} derive(Debug)

///|
fn pairs_of(arguments : String) -> Array[PairNode] {
  let result : Array[PairNode] = []
  for pair in env_pairs(arguments) {
    let (key, value) = pair
    result.push({ key, value })
  }
  result
}

///|
fn parse_copy_node(arguments : String, form : InstructionForm) -> CopyNode {
  let paths = if form is Json {
    parse_json_argv(arguments).unwrap_or([])
  } else {
    copy_paths(arguments)
  }
  let dest = if paths.length() > 0 { paths[paths.length() - 1] } else { "" }
  let sources : Array[String] = []
  let last = paths.length() - 1
  let mut i = 0
  while i < last {
    sources.push(paths[i])
    i += 1
  }
  {
    from_stage: flag_value(arguments, "from"),
    chown: flag_value(arguments, "chown"),
    sources,
    dest,
  }
}

///|
fn parse_exec_node(arguments : String, form : InstructionForm) -> ExecNode {
  let argv = if form is Json {
    parse_json_argv(arguments).unwrap_or([])
  } else {
    tokens(arguments)
  }
  { form, argv, raw: arguments }
}

///|
fn parse_from_node(arguments : String) -> Node {
  match parse_from_image(arguments) {
    None => Other
    Some(image) =>
      From({
        image: image.name,
        tag: image.tag,
        digest: image.digest,
        platform: flag_value(arguments, "platform"),
        as_name: parse_from_stage(arguments),
      })
  }
}

///|
fn parse_node(
  kind : InstructionKind,
  arguments : String,
  form : InstructionForm,
) -> Node {
  match kind {
    From => parse_from_node(arguments)
    Run => {
      let argv = if form is Json {
        parse_json_argv(arguments).unwrap_or([])
      } else {
        []
      }
      Run({
        form,
        script: arguments,
        argv,
        has_pipe: arguments.contains("|"),
        has_heredoc: arguments.contains("<<"),
      })
    }
    Copy => Copy(parse_copy_node(arguments, form))
    Add => Add(parse_copy_node(arguments, form))
    Env => Env(pairs_of(arguments))
    Arg => {
      let pairs = pairs_of(arguments)
      if pairs.length() > 0 {
        Arg(pairs[0])
      } else {
        Other
      }
    }
    Label => Label(pairs_of(arguments))
    Expose => Expose(tokens(arguments))
    Cmd => Cmd(parse_exec_node(arguments, form))
    Entrypoint => Entrypoint(parse_exec_node(arguments, form))
    Workdir => Workdir(first_arg(arguments))
    User => User(first_arg(arguments))
    _ => Other
  }
}
