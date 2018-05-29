pragma solidity ^0.4.10;

// ONLY FOR TEST USE!
/**
 * Copyright (C) 2018  Ducatur, LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License").
 * You may not use this file except in compliance with the License.
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND (express or implied).
 */
 
contract SafeMath {

    function safeAdd(uint256 x, uint256 y) internal returns(uint256) {
      uint256 z = x + y;
      assert((z >= x) && (z >= y));
      return z;
    }

    function safeSubtract(uint256 x, uint256 y) internal returns(uint256) {
      assert(x >= y);
      uint256 z = x - y;
      return z;
    }

    function safeMult(uint256 x, uint256 y) internal returns(uint256) {
      uint256 z = x * y;
      assert((x == 0)||(z/x == y));
      return z;
    }

    function safeDiv(uint256 a, uint256 b) internal returns (uint256) {
      assert(b > 0);
      uint c = a / b;
      assert(a == b * c + a % b);
      return c;
    }

}

contract Token {
    uint256 public totalSupply;
    function balanceOf(address _owner) constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract StandardToken is Token {

    function transfer(address _to, uint256 _value) returns (bool success) {
      if (balances[msg.sender] >= _value && _value > 0) {
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
      } else {
        return false;
      }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
      if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
      } else {
        return false;
      }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}

contract DUC is SafeMath, StandardToken {

    string public constant name = "DUC test 001";
    string public constant symbol = "DUC";
    uint256 public constant decimals = 18;
    uint256 public constant tokenCreationCap =  7000000000*10**decimals;

    address public owner;
    address public oracle;

    modifier onlyOwner {
        if(owner!=msg.sender) revert();
        _;
    }

    modifier onlyOracle {
        if(oracle!=msg.sender) revert();
        _;
    }

    event create(address indexed _to, uint256 _value);
    event burnToken(address from, uint256 _value, int _network, bytes32 _adr);

    function DUC(address _owner, address _oracle) {
        oracle = _oracle;
        owner = _owner;

    }

    function burn_exchange(address _to, uint256 _value) external onlyOracle returns (bool success) {

        uint256 tokens = _value*10**decimals;
        uint256 checkedSupply = safeAdd(totalSupply, tokens);
        if (tokenCreationCap < checkedSupply) revert();

        balances[_to] += tokens;
        totalSupply = safeAdd(totalSupply, tokens);
        return true;

    }

    function () payable {
        createTokens();
    }

    function createTokens() internal {
        if (msg.value <= 0) revert();

        uint multiplier = 10 ** decimals;
        uint256 tokens = msg.value;

        uint256 checkedSupply = safeAdd(totalSupply, tokens);
        if (tokenCreationCap < checkedSupply) revert();

        balances[msg.sender] += tokens;
        totalSupply = safeAdd(totalSupply, tokens);
        owner.transfer(this.balance);
    }
    
    function changeOracle(address _oracle) external onlyOracle {
      oracle = _oracle;
    }
    
    function exchangeToken(uint256 _value, int _network, bytes32 _adr) {
        uint256 tokens = _value*10**decimals;
        if (balances[msg.sender] < tokens) revert();
        balances[msg.sender] -= tokens;
        totalSupply = safeSubtract(totalSupply, tokens);
        burnToken(msg.sender, _value, _network, _adr);
    }

}