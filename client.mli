open Core

type version = int

val get_latest_version: unit -> version

val init: unit -> unit