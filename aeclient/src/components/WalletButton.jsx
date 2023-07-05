import React from 'react'
import { useState, useEffect } from 'react'

const WalletButton = ({ accounts, setAccounts}) => {


  const isConnected = Boolean(accounts)

  const connectAccount = async () => {
    if(window.ethereum){
      const account = await window.ethereum.request({
        method: "eth_requestAccounts",
      })
      setAccounts(account)
    }
  }

  return (
    <div>
      {isConnected ? (
        <button>{String(accounts).split('', 6)}...{String(accounts).substring(String(accounts).length - 4, String(accounts).length)}</button>
      ): (
        <button onClick={connectAccount}>connect</button>
      )}
    </div>
  )
}

export default WalletButton