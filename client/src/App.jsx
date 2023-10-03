import { useState } from 'react'
import './App.css'
import { Header } from './components/Header';
import { Menu } from './components/Menu';


function App() {

  const[account, setAccount] = useState()
  const[connected, setConnected] = useState(false);

  return (
    <div className="App">
      <Header setAccount={setAccount} setConnected={setConnected} connected={connected} />
      <Menu account={account} connected={connected} />
    </div>
  )
}

export default App
