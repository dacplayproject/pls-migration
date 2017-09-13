pragma solidity ^0.4.11;

import "./Owned.sol";
import "./MiniMeToken.sol";
import "./SafeMath.sol";
import "./ERC20Token.sol";

contract PLSController is Owned, TokenController {
    using SafeMath for uint256;

    uint256 constant public exchangeRate = 600;   // will be set before the token sale.
    uint256 constant public maxGasPrice = 50000000000;  // 50GWei

    MiniMeToken public  PLS;            // The ATT token itself

    address public plsController;

    uint256 public finalizedBlock;
    uint256 public finalizedTime;

    bool public paused;

    modifier initialized() {
        require(address(PLS) != 0x0);
        _;
    }

    modifier contributionOpen() {
        require(time() >= startTime &&
              time() <= endTime &&
              finalizedBlock == 0 &&
              address(PLS) != 0x0);
        _;
    }

    modifier notPaused() {
        require(!paused);
        _;
    }

    function PLSController() {
        paused = false;
    }


    /// @notice This method should be called by the owner before the contribution
    ///  period starts This initializes most of the parameters
    /// @param _pls Address of the PLS token contract
    /// @param _plsController Token controller for the PLS that will be transferred after
    ///  the contribution finalizes.
    function initialize(
        address _pls,
        address _plsController
    ) public onlyOwner {
      // Initialize only once
      require(address(PLS) == 0x0);

      PLS = MiniMeToken(_pls);
      require(PLS.totalSupply() == 0);
      require(PLS.controller() == address(this));
      require(PLS.decimals() == 18);  // Same amount of decimals as ETH

      require(_plsController != 0x0);
      plsController = _plsController;
  }

  /// @notice If anybody sends Ether directly to this contract, consider he is
  ///  getting PLSs.
  function () public payable notPaused {
      proxyPayment(msg.sender);
  }


  //////////
  // MiniMe Controller functions
  //////////

  /// @notice This method will generally be called by the PLS token contract to
  ///  acquire PLSs. Or directly from third parties that want to acquire PLSs in
  ///  behalf of a token holder.
  /// @param _th PLS holder where the PLSs will be minted.
  function proxyPayment(address _th) public payable notPaused initialized contributionOpen returns (bool) {
      require(_th != 0x0);

      return true;
  }

  function onTransfer(address, address, uint256) public returns (bool) {
      return false;
  }

  function onApprove(address, address, uint256) public returns (bool) {
      return false;
  }

  function migrateTokenUsingSig(bytes data) onlyOwner initialized notPaused contributionOpen {
      require(totalIssueTokenGenerated.add(_amount) <= maxIssueTokenLimit);

      assert(PLS.generateTokens(_th, _amount));


      ATT.generateTokens(0xb1, tokensToSecondRound)

      totalIssueTokenGenerated = totalIssueTokenGenerated.add(_amount);

      NewIssue(_th, _amount, data);
  }

  /// @notice This method will can be called by the owner before the contribution period
  ///  end or by anybody after the `endBlock`. This method finalizes the contribution period
  ///  by creating the remaining tokens and transferring the controller to the configured
  ///  controller.
  function finalize() public onlyOwner initialized {
      require(time() >= startTime);
      // require(msg.sender == owner || time() > endTime);
      require(finalizedBlock == 0);

      finalizedBlock = getBlockNumber();
      finalizedTime = now;

      ATT.changeController(attController);

      Finalized();
  }

  // NOTE on Percentage format
  // Right now, Solidity does not support decimal numbers. (This will change very soon)
  //  So in this contract we use a representation of a percentage that consist in
  //  expressing the percentage in "x per 10**18"
  // This format has a precision of 16 digits for a percent.
  // Examples:
  //  3%   =   3*(10**16)
  //  100% = 100*(10**16) = 10**18
  //
  // To get a percentage of a value we do it by first multiplying it by the percentage in  (x per 10^18)
  //  and then divide it by 10**18
  //
  //              Y * X(in x per 10**18)
  //  X% of Y = -------------------------
  //               100(in x per 10**18)
  //
  function percent(uint256 p) internal returns (uint256) {
      return p.mul(10**16);
  }
  
  /// @dev Internal function to determine if an address is a contract
  /// @param _addr The address being queried
  /// @return True if `_addr` is a contract
  function isContract(address _addr) constant internal returns (bool) {
      if (_addr == 0) return false;
      uint256 size;
      assembly {
          size := extcodesize(_addr)
      }
      return (size > 0);
  }

  function time() constant returns (uint) {
      return block.timestamp;
  }

  //////////
  // Constant functions
  //////////

  /// @return Total tokens issued in weis.
  function tokensIssued() public constant returns (uint256) {
      return ATT.totalSupply();
  }

  //////////
  // Testing specific methods
  //////////

  /// @notice This function is overridden by the test Mocks.
  function getBlockNumber() internal constant returns (uint256) {
      return block.number;
  }

  //////////
  // Safety Methods
  //////////

  /// @notice This method can be used by the controller to extract mistakenly
  ///  sent tokens to this contract.
  /// @param _token The address of the token contract that you want to recover
  ///  set to 0 in case you want to extract ether.
  function claimTokens(address _token) public onlyOwner {
      if (ATT.controller() == address(this)) {
          ATT.claimTokens(_token);
      }
      if (_token == 0x0) {
          owner.transfer(this.balance);
          return;
      }

      ERC20Token token = ERC20Token(_token);
      uint256 balance = token.balanceOf(this);
      token.transfer(owner, balance);
      ClaimedTokens(_token, owner, balance);
  }

  /// @notice Pauses the contribution if there is any issue
  function pauseContribution() onlyOwner {
      paused = true;
  }

  /// @notice Resumes the contribution
  function resumeContribution() onlyOwner {
      paused = false;
  }

  event ClaimedTokens(address indexed _token, address indexed _controller, uint256 _amount);
  event NewSale(address indexed _th, uint256 _amount, uint256 _tokens);
  event NewIssue(address indexed _th, uint256 _amount, bytes data);
  event Finalized();
}
