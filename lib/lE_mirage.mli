(** High-level module for Let's encrypt *)

module Make
    (Time : Mirage_time.S)
    (Stack : Tcpip.Stack.V4V6)
    (Random : Mirage_random.S)
    (Mclock : Mirage_clock.MCLOCK)
    (Pclock : Mirage_clock.PCLOCK) : sig
  val get_certificates :
    yes_my_port_80_is_reachable_and_unused:Stack.t ->
    production:bool ->
    LE.configuration ->
    (Tls.Config.own_cert, [> `Msg of string ]) result Lwt.t
  (** [get_certificates ~yes_my_port_80_is_reachable_and_unused ~production cfg]
      tries to resolve the Let's encrypt challenge by initiating an HTTP server
      on port 80 and handling requests from it with [ocaml-letsencrypt].

      This resolution requires that your domain name (requested in the given
      [cfg.hostname]) redirects Let's encrypt to this HTTP server. You probably
      need to check your DNS configuration. *)

  module Paf : module type of Paf_mirage.Make (Stack.TCP)

  val with_lets_encrypt_certificates :
    ?port:int ->
    Stack.t ->
    production:bool ->
    LE.configuration ->
    (Paf.TLS.flow, Ipaddr.t * int) Alpn.server_handler ->
    (unit, [> `Msg of string ]) result Lwt.t
  (** [with_lets_encrypt_certificates ?port stackv4v6 ~production cfg handler]
      launches 2 servers: 1) An HTTP server which handles let's encrypt
      challenges and redirections 2) An ALPN server (HTTP/1.1 and H2) servers to
      the user's request handler

      Every 80 days, the fiber re-askes a new certificate from let's encrypt and
      re-update the ALPN server with this new certificate. The HTTP server does
      the redirection to the hostname defined into the given [cfg]. *)
end
