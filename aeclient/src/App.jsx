import { Exchange, Loader, WalletButton } from './components';
import './App.css'
import { useState } from 'react';

function App() {
  
  const [accounts, setAccounts] = useState();
  const poolsLoading = false;

  return (
    <div id='total'>
      <div id='header'>
        <header>
          <WalletButton accounts={accounts} setAccounts={setAccounts}/>
        </header>
      </div>
      <div id='allcontent'>
        <h1 id='title'>aestheticswap</h1>
        <p id='pp'>exchange tokens in seconds</p>
        <div id='todocontent'>
          <div id='content'>
            <div>
              {accounts ? (
                poolsLoading ? (
                  <Loader />
                ) : <Exchange />
              ) : <Loader />}
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}

export default App
