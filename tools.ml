(*
  any-dl:
  -------
  Generic Media-Downloader for any kind of Online-Mediathek.

  Author / copyright: Oliver Bandel
  Copyleft:           GNU GENERAL PUBLIC LICENSE  v3 (or higher)
*)


exception Invalid_Index                 (* indexing a col/row that does not exist *)





(* CLI-VERBOSE-dependent print functions ! *)
(* --------------------------------------- *)
let verbose_fprintf ?(optflag=false) channel formatstr =
  let frmt = format_of_string formatstr in
  if Cli.opt.Cli.verbose || Cli.opt.Cli.very_verbose || optflag
  then Printf.fprintf channel frmt
  else Printf.ifprintf channel frmt

let very_verbose_fprintf ?(optflag=false) channel formatstr =
  let frmt = format_of_string formatstr in
  if Cli.opt.Cli.very_verbose || optflag
  then Printf.fprintf channel frmt
  else Printf.ifprintf channel frmt


let verbose_printf       ?(optflag=false) formatstr = verbose_fprintf      ~optflag:optflag stdout formatstr
let very_verbose_printf  ?(optflag=false) formatstr = very_verbose_fprintf ~optflag:optflag stdout formatstr


(* -v means: very_verbose is wanted output, not an error... why then stderr? -> unneeded?
let very_verbose_eprintf formatstr = very_verbose_fprintf stderr formatstr
*)

(* ------------------------------------------------ *)
(* ------------------------------------------------ *)
(* ------------------------------------------------ *)
let print_warning str = flush stdout; prerr_string "WARNING: "; prerr_endline str


(* ------------------------------------------------ *)
(* select those items from the row_items, which are *)
(* indexed by the values in the index_list          *)
(* ------------------------------------------------ *)
let item_selection row_items index_list =
  let res_len = List.length index_list in
  let res     = Array.make res_len row_items.(0) in
  let index_arr = Array.of_list index_list in

  for res_index = 0 to Array.length index_arr - 1
  do
    res.(res_index) <- row_items.(index_arr.(res_index))
  done;
  res


(* returns size of file in bytes *)
(* ----------------------------- *)
let filesize filename =
  let open Unix in
  let size = (stat filename).st_size in
  size


(* save string to file *)
(* ------------------- *)
let save_string_to_file str filename =
  let oc = open_out filename in
  output_string oc str;
  close_out oc



(* read file *)
(* --------- *)
let read_file  filename =
  let size = filesize filename in
  let ic = open_in filename in
  let contents = really_input_string ic size in
  contents




(* ------------------------------------------------------------------------ *)
(* Sortiere String-Liste mit Reihenfolge von a nach z; case insensitive *)
let sort stringlist = List.sort ( fun a b -> let al = String.lowercase a and bl = String.lowercase b
                                   in if al < bl then (-1) else if al = bl then 0 else 1)  stringlist
(* ------------------------------------------------------------------------ *)


(* =================================================== *)
(* from an array drop the element with the given index *)
(* =================================================== *)
let array_drop arr dropidx =
  let len = Array.length arr             in

  (* Argument checking *)
  (* ----------------- *)
  if dropidx < 0 || dropidx > len - 1 then raise Invalid_Index;


  let res = Array.make (len - 1) arr.(0) in

  let srcidx    = ref 0 in
  let targetidx = ref 0 in

  (* --------------------------------------------------------------------------------- *)
  (* copy any element from src to target, that has different index than the drop-index *)
  (* --------------------------------------------------------------------------------- *)
  while !srcidx < len
  do
    if !srcidx != dropidx
    then
      begin
        res.(!targetidx) <- arr.(!srcidx); (* copy data *)
        incr srcidx;
        incr targetidx
      end
    else
      begin
        incr srcidx;
      end
  done;
  res (* the resulting array *)



(* ======================================================== *)
(* converts a list of pairs into a list, by just prepending *)
(* the items of the pairs into the resullting list          *)
(* ======================================================== *)
let pairlist_to_list  inputlist =
  let rec aux res li = match li with
    | (k,v)::tl -> aux (v::k::res) tl
    | []        -> List.rev res
in
  aux [] inputlist



(* ================================================================ *)
(* exctract the charset-value from a string and select the matching *)
(* value for encoding                                               *)
(* ================================================================ *)
let select_decoding_scheme str =
  let scheme = (Pcre.extract ~pat:"charset=([^\"]+)" ~flags:[] str).(1) in
  match String.lowercase scheme with
    | "iso-88-59-1" -> `Enc_iso88591
    | "utf-8"       -> `Enc_utf8
    | _             -> `Enc_utf8



(* ======================================================== *)
(* Decode HTML-stuff (ampersand-foobar)                     *)
(* -------------------------------------------------------- *)
(* utf8 is hard encoded, as long as no encoding detection   *)
(* is implemented and in use.                               *)
(* ======================================================== *)
let html_decode ?(inenc=`Enc_utf8) str =
  try
    Netencoding.Html.decode ~in_enc:inenc ~out_enc:`Enc_utf8 () str
  with  Netconversion.Malformed_code -> str



(* ======================================= *)
let lines_of_string  str = Pcre.split ~pat:"\n" str

(* ======================================= *)
let match_pattern_on_string  pat str = Pcre.pmatch ~pat:pat str


(* ---------------------------------------------- *)
(* Adds items from input list in the order they   *)
(* are in the input list, but add each item only  *)
(* once.                                          *)
(* It's like sort -u without sorting, or like     *)
(* uniq, also working on items that are not       *)
(* neighbours in the input list.                  *)
(* ---------------------------------------------- *)
let add_item_once lst =
  let rec aux  sofar  old = match old with
    | hd::tl -> if List.mem hd sofar then aux sofar tl else aux (hd::sofar) tl
    | []     -> List.rev sofar
  in
    aux [] lst



(* ------------------------------------------------- *)
(* transpose an array-of-arrays                      *)
(* ------------------------------------------------- *)
(* lazy man's implementation via Csv's list-of-lists *)
(* ------------------------------------------------- *)
let transpose arrarr =
  let data = Csv.of_array arrarr in
  let tr = Csv.transpose data in
  Csv.to_array tr



(* -------------------------------------------------- *)
(* Paste a stringlist into a string.                  *)
(* The optional parameter sep is the separator, that  *)
(* is inserted between the strings of the stringlist. *)
(* -------------------------------------------------- *)
let paste ?(sep="\n") stringlist =
  let rec aux accum liste = match liste with
    | []     -> accum
    | hd::[] -> accum ^ sep ^ hd
    | hd::tl -> aux (accum ^ sep ^ hd) tl
  in
    if stringlist = []
    then ""
    else aux (List.hd stringlist) (List.tl stringlist)



(* -------------------------------------------------- *)
(* wrap a string in two strings, one on the left, and *)
(* one on the right side of a string.                 *)
(* This is done for each string of a list of string.  *)
(* -------------------------------------------------- *)
let wrap_string left right stringlist =
  List.map ( fun str -> left ^ str ^ right ) stringlist



module Array2 =
  struct
    include Array

    let filter filt arr = Array.of_list ( List.filter filt (Array.to_list arr ))

    let exists filt arr = List.exists filt (Array.to_list arr)


    let filter_row_by_colmatch colmatcher matr =
      filter ( fun arr -> exists colmatcher arr ) matr

  end



module Sleep =
  struct
    open Unix

    (* sleep a certain amount of time (in seconds as float *)
    (* --------------------------------------------------- *)
    let sleep_float  float_seconds =
      ignore( select [] [] [ stdin ] (abs_float float_seconds) )

    (* sleep ms milliseconds *)
    (* --------------------- *)
    let sleep_ms  ms =
      verbose_printf "sleep %d miliseconds\n" ms; (* devel-debug-info *)
      sleep_float (float_of_int ms /. 1000.0)

  end

