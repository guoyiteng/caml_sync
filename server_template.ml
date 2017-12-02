open Opium.Std

type person = {
  name: string;
  age: int;
}

let json_of_person { name ; age } =
  let open Ezjsonm in
  dict [ "name", (string name)
       ; "age", (int age) ]

let print_param = post "/hello" begin fun req ->
    req |> App.json_of_body_exn |> Lwt.map (fun _json ->
        respond (`Json _json ))
  end

let print_person = get "/person/:name/:age" begin fun req ->
    let person = {
      name = param req "name";
      age = "age" |> param req |> int_of_string;
    } in
    `Json (person |> json_of_person) |> respond'
  end

let _ =
  App.empty
  |> print_param
  |> print_person
  |> App.run_command