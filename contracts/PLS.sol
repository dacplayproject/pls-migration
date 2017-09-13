pragma solidity ^0.4.11;

import "./MiniMeToken.sol";


contract PLS is MiniMeToken {

    function PLS(address _tokenFactory)
            MiniMeToken(
                _tokenFactory,
                0x0,                     // no parent token
                0,                       // no snapshot block number from parent
                "DACPLAY Token",         // Token name
                18,                      // Decimals
                "PLS",                   // Symbol
                true                     // Enable transfers
            ) {}
}
