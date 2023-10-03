import React, { useEffect, useState } from "react";
import { ethers } from "ethers";
import './Menu.css';

import DaiABI from '../web3/DaiABI.json';
import UsdtABI from '../web3/UsdtABI.json'

import Logo from '../assets/logo.png';
import Logo2 from '../assets/logo2.png';
import Logo3 from '../assets/logo3.png';
import Logo4 from '../assets/logo4.png';

const DAIAddress = "0x9D233A907E065855D2A9c7d4B552ea27fB2E5a36"
const USDTAddress = "0xe583769738b6dd4E7CAF8451050d1948BE717679"

export const Menu = ({ account, connected }) => {

  const[DAIContract, setDAIContract] = useState();
  const[USDTContract, setUSDTContract] = useState();

  const[balanceDAI, setBalanceDAI] = useState();
  const[balanceUSDT, setBalanceUSDT] = useState();

  const[insBalance, setInsBalance] = useState(false);

  useEffect(() => {
    handleBalance();
  })

  const handleBalance = async () => {
    const provider = new ethers.providers.Web3Provider(window.ethereum);
    const contractDAI = new ethers.Contract(
      DAIAddress,
      DaiABI,
      provider
    );

    const contractUSDT = new ethers.Contract(
      USDTAddress,
      UsdtABI,
      provider
    );

    console.log(account[0])
    
    let balanceDAI = await contractDAI.balanceOf(account[0]);
    
    let balanceUSDT = await contractUSDT.balanceOf(account[0])

    setBalanceDAI(Number(balanceDAI));
    setBalanceUSDT(Number(balanceUSDT));

    if(balanceDAI > 0){
      setInsBalance(true);
    }
    setInsBalance(false);
  }

  return (
    <div className="all">
      <div className="container">
        {
          connected ? (
            <div>
              <div className="title">Swap</div>
              <div className="put-1">
                <input type="number" className="in-1" placeholder="0.0"/>
                <div className="coin1"><div className="c1"><img src={Logo3} className="logos" />DAI</div></div>
              </div>
              <div className="balance">Balance {balanceDAI}</div>
              <div className="put-1">
                <input type="number" className="in-1" placeholder="0.0"/>
                <div className="coin1"><div className="c1"><img src={Logo4} className="logos" />USDT</div></div>
              </div>
              <div className="balance">Balance {balanceUSDT}</div>
              <div className="btncon">
                {
                  insBalance ? (
                    <button className="btnconfirm">Confirm</button>
                  ) : (
                    <button className="btnconfirm2">Insufficient amount</button>
                  )
                }
              </div>
            </div>
          ) : (
            <div className="inconnect">
              <img src={Logo2} className="logo-2" />
              <p className="pwallet">Please connect your wallet</p>
            </div>
          )
        }
      </div>
    </div>
  )
}