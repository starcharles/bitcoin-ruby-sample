require 'bitcoin'
require 'openassets'
require 'dotenv'
require "pry"

Dotenv.load

api = OpenAssets::Api.new({
    network:           'regtest',
    provider:         'bitcoind',
    cache:            'cache.db',
    dust_limit:              600,
    default_fees:          10000,
    min_confirmation:          1,
    max_confirmation:    9999999,
    rpc: {
      user:                ENV['RPC_USER'],
      password:            ENV['RPC_PASS'],
      schema:             'http',
      port:                 8332,
      host:          'localhost',
      timeout:                60,
      open_timeout:           60 }
  })

Bitcoin.network = :regtest

sender = 'mmEAxswu8V7LdUEvxy23Gv6iCZPxiAUB9i'
recipient = 'mp9SVNVpuiNau8p1t5oWZ3dzM6Ap5t7G64'

# アカウントにあるBTC
total_btc = 1*100_000_000
# 単位satoshiで送金額を設定
send_amount = 1*100_000_000
# 送金手数料
tx_fee = 0.001*100_000_000

priv_key = api.provider.dumpprivkey(sender)

# Keyオブジェクトに変換
key = Bitcoin::Key.from_base58(priv_key)

utxo_id = 'd99ccb61c982cfdd9d8d02c5b1b7940786140efe5cd15204b691bf1e6d3d2f91'

utxo_raw = api.provider.getrawtransaction(utxo_id)
tx = Bitcoin::Protocol::Tx.new(utxo_raw.htb)

tx_bldr = Bitcoin::Builder::TxBuilder.new

tx_bldr.input do |i|
  i.prev_out tx, 1
  i.signature_key key
end

tx_bldr.output do |o|
  o.value send_amount 
  o.script {|s| s.recipient recipient }
end

tx_bldr.output do |o|
  o.value total_btc - tx_fee 
  o.to sender
end

serialized_tx = tx_bldr.tx.to_payload.bth

result = api.provider.sendrawtransaction(serialized_tx)

puts result
