pragma solidity ^0.8.18;

import {IStarknetMessaging} from "./interfaces/IStarknetMessaging.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";

/**
 * @title MarquisMsgAdapter
 * @author Carlos Ramos
 * @dev this contract will interact with starknet core contract to send and consume messages to / from l2
 */

contract MarquisMsgAdapter is Initializable, OwnableUpgradeable {
    uint256 constant DEPOSIT_SELECTOR_L2 =
        0x002ec0df5118cf86d0032373d25506cff9e952ef881e2d6729f57356c766120e; // keccak256("l1_deposit_handler")
    IStarknetMessaging public starknetMessaging;
    address l2MsgAdapterAddr;

    function initialize(
        address _starknetMessagingAddr,
        address _l2MsgAdapterAddr
    ) external {
        starknetMessaging = IStarknetMessaging(_starknetMessagingAddr);
    }

    function sendManyValues(
        uint256 toAddress,
        uint256 selector,
        uint256[] calldata payload
    ) external payable returns (bytes32, uint256) {
        return
            starknetMessaging.sendMessageToL2{value: msg.value}(
                toAddress,
                selector,
                payload
            );
    }

    function deposit(
        uint256[] calldata payload // to parse into different values sent from l1
    ) external payable returns (bytes32, uint256) {
        return
            starknetMessaging.sendMessageToL2{value: msg.value}(
                uint256(uint160(l2MsgAdapterAddr)),
                DEPOSIT_SELECTOR_L2,
                payload
            );
    }
}
