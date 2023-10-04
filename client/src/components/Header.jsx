import React from "react";

import './Header.css';
import logo from '../assets/logo.png';

export const Header = ({ setAccount, setConnected, connected }) => {

  const connectAccount = async () =>{
    if(window.ethereum){
      const account = await window.ethereum.request({
        method: "eth_requestAccounts", 
      })
      setAccount(account)
      setConnected(true);
    }
  }

  return (
    <div>
      <header>
        <div>
          <h2>aeSwap</h2>
        </div>
        <nav className="options">
          <a href="">swap</a>
          <a href="">pool</a>
          <a href="">vote</a>
          <a href="">charts</a>
        </nav>
        <div className="econnect">
          <div className="eth"><img src={logo} className="logos" />Goerli</div>
          {
            connected ? (
              <label className="eth">Connected</label>
            ) : (
              <button className="wallet" onClick={connectAccount}> Connect</button>
            )
          }
        </div>
      </header>
    </div>
  )
}