#import "../lib/single_asset/fa2.mligo" "FA2"

type storage = FA2.storage

type extension = {
    admin : address;
    probationary_period : timestamp;
}

type extended_storage = extension storage

type parameter = 
    | Transfer of FA2.transfer
    | Balance_of of FA2.balance_of
    | Update_operators of FA2.update_operators

let is_operator (operators : FA2.Operators.t) (from_ : address) : bool =
  let sender_ = (Tezos.get_sender ()) in
  if (sender_ = from_) then true
  else
  let authorized = match Big_map.find_opt from_ operators with
     Some (a) -> a | None -> Set.empty
  in 
  if Set.mem sender_ authorized then 
    true
  else 
    false

let authorize_transfer (s : extended_storage) : unit =
    let sender_ = Tezos.get_sender() in
    if (Tezos.get_now() < s.extension.probationary_period) then
        if (sender_ = s.extension.admin) then
            ()
        else
            if (is_operator s.operators s.extension.admin) then
                ()
            else
                failwith "Transfer not authorized for users before Probationary Period"
    else
        ()


[@entry]
let transfer (p: FA2.transfer) (s: extended_storage) : operation list * extended_storage =
  let _ = authorize_transfer s in
  FA2.transfer p s

[@entry]
let balance_of (p: FA2.balance_of) (s: extended_storage) : operation list * extended_storage =
  FA2.balance_of p s

[@entry]
let update_operators (p: FA2.update_operators) (s: extended_storage) : operation list * extended_storage =
  FA2.update_ops p s

let get_balance (s : extended_storage) (owner : address) (_token_id : nat) : nat =
    FA2.Ledger.get_for_user s.ledger owner

[@view] let get_balance (p: address) (s: extended_storage) : nat =
    get_balance s p 0n
