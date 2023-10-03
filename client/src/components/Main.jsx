import React, { useEffect, useState, useRef } from 'react';
import './Main.css';
import { ethers } from "ethers";
import ChallengeABI from '../web3/ChallengeABI.json';
import DaiABI from '../web3/DaiABI.json';
import UsdtABI from '../web3/UsdtABI.json'
import { Admin } from './Admin';
// import * as dotenv from "dotenv";

// dotenv.config();

const ChallengeAddress = "0xe6dffcB72444ba28a50CDd99D8B6437246B1B047"
const DAIAddress = "0x9D233A907E065855D2A9c7d4B552ea27fB2E5a36"
const USDTAddress = "0xe583769738b6dd4E7CAF8451050d1948BE717679"

export const Main = () => {

  const[connected, setConnected] = useState(false);
  const[accounts, setAccounts] = useState([])

  const[contract, setContract] = useState()
  const[DAIContract, setDAIContract] = useState()
  const[USDTContract, setUSDTContract] = useState()

  const[balanceDAI, setBalanceDAI] = useState()
  const[balanceUSDT, setBalanceUSDT] = useState()

  const[value, setValue] = useState()

  const inputRef = useRef();

  useEffect(() => {
    handleStock();
  })

  const connectAccount = async () =>{
    if(window.ethereum){
      const account = await window.ethereum.request({
        method: "eth_requestAccounts", 
      })
      setAccounts(account);

      console.log('Address1: ' , accounts[0])

      setConnected(true);    
    }
  }

  const handleStock = async () =>{
    console.log('Address: ' , accounts[0])

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
    
    let balanceDAI = await contractDAI.balanceOf(accounts[0]);
    
    let balanceUSDT = await contractUSDT.balanceOf(accounts[0])

    setBalanceDAI(Number(balanceDAI));
    setBalanceUSDT(Number(balanceUSDT));
    
  }

  return (
    <div>
      <div className='connect-div'>
        {connected ? (
          <p className='p-connect'>Connected</p>
        ) : (
          <button className='connect' onClick={connectAccount}>Connect</button>
        )}
      </div>
      <div className='box-con'>
        <div className='box-div'>
          <main className='box'>
            <header className='header'>
            </header>
            <input type="number" className='input input-2a' value={value} />
            <p>{connected ? (
              <p>balance {balanceDAI}</p>
            ) : <p></p>}</p>
            <input type="number" className='input input-2b' value={value} />
            <p>{connected ? (
              <p>balance {balanceUSDT}</p>
            ) : <p></p>}</p>
            
          </main>
        </div>
        <div className='box-stock'>
          
        </div>
      </div>
    </div>
  )
}
