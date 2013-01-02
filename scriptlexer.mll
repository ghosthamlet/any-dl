(*
  any-dl:
  -------
  Generic Media-Downloader for any kind of Online-Mediathek.

  Author / copyright: Oliver Bandel
  Copyleft:           GNU GENERAL PUBLIC LICENSE  v3 (or higher)
*)
{
  open Scriptparser
  let linenum = ref 1
  let stringbuf = Buffer.create 1000

  let keyword_table = Hashtbl.create 72
  let _ =
    List.iter (fun (kwd, tok) -> Hashtbl.add keyword_table kwd tok)
                [
                  ("parsername",  PARSERNAME  );
                  ("urlmatches",  URLMATCHES  );
                  ("start",       START  );
                  ("end",         END  );

                  ("showtype",      SHOWTYPE  );
                  ("match",        MATCH  );
                  ("show_match",   SHOW_MATCH  );
                  ("print",        PRINT  );
                  ("print_string", PRINT_STRING  );

                  ("linkextract",      LINKEXTRACT  );
                  ("linkextract_xml",  LINKEXTRACT_XML  );


                  ("get",            GET  );

                  ("sto",            STO  );
                  ("rcl",            RCL  );

                  ("rowselect",      ROWSELECT  );
                  ("select",         SELECT     );

                  ("colselect",      COLSELECT  );

                  ("dummy",  DUMMY  );
                ]


}
let alpha = ['a'-'z' 'A'-'Z']+
let alpha_ = ['a'-'z' 'A'-'Z' '_']+
let blanks = [' ' '\t' '\n' '\r']+
let digit  = [ '0' - '9' ]
let identifier = ['a'-'z' 'A'-'Z' ] (alpha_ | digit)*


rule read_command = parse
   | [ ' ' '\t' ]   { read_command lexbuf }
   | "\n"           { incr linenum; read_command lexbuf }
   | identifier as name { try Hashtbl.find keyword_table  name with Not_found -> IDENTIFIER (Lexing.lexeme lexbuf) }
   | digit+ as num  { INT_NUM (int_of_string num) }
   | '"'            { Buffer.clear stringbuf; read_string lexbuf }
   | ">>>"          { Buffer.clear stringbuf; read_specialstring lexbuf }
   | "_*_"          { Buffer.clear stringbuf; read_specialstring_2 lexbuf }
   | '.'            { DOT }

   | '>'            { GT }
   | '<'            { ST }
   | '='            { EQUALS }

   | ','            { COMMA }
   | ';'            { SEMI }
   | ':'            { COLON }
   | '('            { LPAREN }
   | ')'            { RPAREN }
   | digit+         { INT_NUM (int_of_string(Lexing.lexeme lexbuf)) }
   | '#'            { eat_up_line lexbuf }
   | _              { IDENTIFIER (Lexing.lexeme lexbuf) }
   | eof            { EOF }


and read_string = parse
   | [^ '"' '\n' '\\']+  { Buffer.add_string stringbuf (Lexing.lexeme lexbuf); read_string lexbuf }
   | '\n'           { incr linenum; Buffer.add_string stringbuf (Lexing.lexeme lexbuf); read_string lexbuf }
   | "\\n"          { Buffer.add_string stringbuf "\n"; read_string lexbuf }
   | "\\n"          { Buffer.add_string stringbuf "\n"; read_string lexbuf }
   | "\\("          { Buffer.add_string stringbuf "\\("; read_string lexbuf }
   | "\\)"          { Buffer.add_string stringbuf "\\)"; read_string lexbuf }
   | "\\."          { Buffer.add_string stringbuf "\\."; read_string lexbuf }
   | "\\\""         { Buffer.add_string stringbuf (Lexing.lexeme lexbuf); read_string lexbuf }
   | '"'            { STRING (Buffer.contents stringbuf) }
   | eof            { EOF }


and read_specialstring = parse
   | [^ '"' '\n' '<']+  { Buffer.add_string stringbuf (Lexing.lexeme lexbuf); read_specialstring lexbuf }
   | _              { Buffer.add_string stringbuf (Lexing.lexeme lexbuf); read_specialstring lexbuf }
   | "<<<"          { STRING (Buffer.contents stringbuf) }
   | eof            { EOF }


and read_specialstring_2 = parse
   | [^ '\n' '_' '*']+  { Buffer.add_string stringbuf (Lexing.lexeme lexbuf); read_specialstring_2 lexbuf }
   | _              { Buffer.add_string stringbuf (Lexing.lexeme lexbuf); read_specialstring_2 lexbuf }
   | "_*_"          { STRING (Buffer.contents stringbuf) }
   | eof            { EOF }





and eat_up_line = parse
   | [^ '\n']    { eat_up_line lexbuf }
   | _           { incr linenum; read_command lexbuf }



and read_int = parse
   | blanks    { read_int lexbuf }
   | digit+    { Some (int_of_string (Lexing.lexeme lexbuf)) }
   | eof       { raise End_of_file }
