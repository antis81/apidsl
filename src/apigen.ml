type outlang =
  | Api
  | Ast
  | C
  | Haskell of string

let parse_file file =
  let fh = open_in file in
  let lexbuf = Lexing.from_channel fh in
  lexbuf.Lexing.lex_curr_p <- Lexing.({
      lexbuf.lex_curr_p with
      pos_fname = file;
    });

  let api = ApiPasses.parse_lexbuf lexbuf in

  close_in fh;

  api


let dump_api pre api post =
  Option.may (Format.pp_print_string Format.str_formatter) pre;
  Format.fprintf Format.str_formatter "%a\n"
    ApiCodegen.Api.cg_decls api;
  Option.may (Format.fprintf Format.str_formatter "\n%s\n") post;

  Format.flush_str_formatter ()


let main input =
  let api = parse_file input in
  let ApiAst.Api (pre, ast, post) = api in
  function
  | C               -> print_string (ApiPasses.all pre ast post)
  | Haskell modname -> print_string (ApiPasses.haskell modname ast)
  | Ast             -> print_endline (ApiAst.show_api Format.pp_print_string api)
  | Api             -> print_endline (dump_api pre ast post)


let () =
  (*Printexc.record_backtrace true;*)
  match Sys.argv with
  | [|_                ; input|]
  | [|_; "-c"          ; input|] -> main input C
  | [|_; "-hs"; modname; input|] -> main input (Haskell modname)
  | [|_; "-ast"        ; input|] -> main input Ast
  | [|_; "-api"        ; input|] -> main input Api
  | _ -> print_endline "Usage: apigen <file>"
