pragma solidity ^0.4.0;
import "github.com/oraclize/ethereum-api/oraclizeAPI.sol";

contract PLSMigration is usingOraclize {

    event newVerify(string question);
    event newVerifyAnswer(string answer);

    function PLSMigration() {
        // OAR = OraclizeAddrResolverI(0x6f485C8BF6fc43eA212E93BBF8ce046C7f1cb475);
        OAR = OraclizeAddrResolverI(0xB7A07BcF2Ba2f2703b24C0691b5278999C59AC7e); // kovan
    }

    function __callback(bytes32 myid, string result) {
        if (msg.sender != oraclize_cbAddress()) throw;
        newVerifyAnswer(result);
    }

    function ask(string question) payable {
        oraclize_query("URL", question);
    }

}